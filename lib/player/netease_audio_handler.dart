import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/result.dart';
import '../viewmodels/song_url.dart';
import 'play_order.dart';

/// 按歌曲 id 取播放地址（由仓库提供，见 `NcmRepository.songUrl`）。
typedef SongUrlResolver = Future<Result<SongUrl>> Function(int songId);

/// 后台音频服务：通知栏、锁屏、耳机按键都走它。
///
/// 和普通「歌单播放器」的区别：网易云的播放地址会过期，所以队列里只放
/// 歌曲信息（[MediaItem]），**切到哪首才去取哪首的地址**，不把一串地址
/// 一次性塞给播放器。因此这里自己管队列下标，不用 just_audio 的播放列表。
class NeteaseAudioHandler extends BaseAudioHandler with SeekHandler {
  NeteaseAudioHandler() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  /// 取播放地址的函数，仓库建好之后由外面注入
  SongUrlResolver? urlResolver;

  final StreamController<String> _messages =
      StreamController<String>.broadcast();

  /// 要告诉用户的话（无法播放、只能试听），界面层弹提示
  Stream<String> get messages => _messages.stream;

  /// 当前在队列里的位置，-1 表示还没开始放
  int _index = -1;

  /// 每次切歌 +1。取地址、加载都是异步的，回来时发现 token 变了
  /// 就说明用户已经切走了，结果直接丢掉，别把旧歌放出来。
  int _loadToken = 0;

  /// 正在取地址 / 加载：对外报告 loading，别露出播放器内部的 idle
  bool _resolving = false;

  /// 连续放不了的歌数；连着 3 首都失败就停下，不要一直往后翻
  int _failures = 0;

  RepeatKind _repeat = RepeatKind.all;
  bool _shuffle = false;

  void _init() {
    _player.playbackEventStream.listen(
      _broadcast,
      onError: (Object error, StackTrace stackTrace) {
        // 播放中途出错（连接断了、地址失效）：当作这首放不了
        debugPrint('播放器错误: $error');
        final int token = _loadToken;
        final MediaItem? item = mediaItem.value;
        if (item != null) {
          unawaited(_onUnplayable(token, item, null));
        }
      },
    );
    _player.processingStateStream.listen((ProcessingState state) {
      if (state == ProcessingState.completed) {
        unawaited(_onCompleted());
      }
    });
  }

  // ---------- 对外入口 ----------

  /// 换一个播放队列，从 [index] 开始放。
  Future<void> playQueue(List<MediaItem> items, int index) async {
    if (items.isEmpty) {
      return;
    }
    queue.add(items);
    final int start = index < 0
        ? 0
        : (index >= items.length ? items.length - 1 : index);
    await _playAt(start);
  }

  @override
  Future<void> play() async {
    if (_resolving) {
      return;
    }
    // idle：被停掉过（出错、通知栏划掉），重新从当前这首加载
    if (_player.processingState == ProcessingState.idle) {
      if (_index >= 0) {
        await _playAt(_index);
      }
      return;
    }
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    if (_resolving) {
      // 还在取地址就暂停：取消这次加载，之后再点播放会重新来
      _loadToken++;
      _resolving = false;
      await _player.stop();
      _broadcast(_player.playbackEvent);
      return;
    }
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final int? next = nextIndex(
      current: _index,
      length: queue.value.length,
      repeat: _repeat,
      shuffle: _shuffle,
      manual: true,
    );
    if (next != null) {
      await _playAt(next);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // 放了一会儿再点「上一首」，行为和主流播放器一样：先回到这首的开头
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    await _playAt(previousIndex(current: _index, length: queue.value.length));
  }

  @override
  Future<void> skipToQueueItem(int index) => _playAt(index);

  @override
  Future<void> stop() async {
    _loadToken++;
    _resolving = false;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeat = switch (repeatMode) {
      AudioServiceRepeatMode.none => RepeatKind.none,
      AudioServiceRepeatMode.one => RepeatKind.one,
      AudioServiceRepeatMode.all => RepeatKind.all,
      AudioServiceRepeatMode.group => RepeatKind.all,
    };
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffle = shuffleMode == AudioServiceShuffleMode.all;
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  // ---------- 内部：切歌 ----------

  Future<void> _playAt(int index) async {
    final List<MediaItem> items = queue.value;
    if (index < 0 || index >= items.length) {
      return;
    }
    final int token = ++_loadToken;
    _index = index;
    final MediaItem item = items[index];
    mediaItem.add(item);
    _resolving = true;
    _broadcast(_player.playbackEvent);

    try {
      await _player.stop();
    } on Object catch (error) {
      debugPrint('停止上一首失败: $error');
    }
    if (token != _loadToken) {
      return;
    }

    final int? songId = int.tryParse(item.id);
    final SongUrlResolver? resolver = urlResolver;
    if (songId == null || resolver == null) {
      await _onUnplayable(token, item, null);
      return;
    }
    final Result<SongUrl> result = await resolver(songId);
    if (token != _loadToken) {
      return;
    }
    if (result is! Ok<SongUrl>) {
      await _onUnplayable(
        token,
        item,
        result is Err<SongUrl> ? result.error.message : null,
      );
      return;
    }

    final SongUrl playable = result.value;
    try {
      await _player.setUrl(playable.url);
      if (token != _loadToken) {
        return;
      }
      _resolving = false;
      _failures = 0;
      if (playable.isTrial) {
        _messages.add('《${item.title}》只能试听片段');
      }
      _broadcast(_player.playbackEvent);
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // 加载被下一次 setUrl 打断，说明用户已经切歌了，不是错误
      return;
    } on Object catch (error) {
      debugPrint('加载失败: $error');
      await _onUnplayable(token, item, null);
    }
  }

  /// 这首放不了：提示一下，自动跳到下一首；连着失败太多次就停下。
  Future<void> _onUnplayable(int token, MediaItem item, String? reason) async {
    if (token != _loadToken) {
      return;
    }
    _resolving = false;
    _failures++;
    _messages.add('《${item.title}》${reason ?? '暂时无法播放'}');

    final int? next = nextIndex(
      current: _index,
      length: queue.value.length,
      repeat: _repeat,
      shuffle: _shuffle,
      manual: true,
    );
    final bool canSkip =
        _failures < 3 && queue.value.length > 1 && next != null;
    if (!canSkip) {
      _failures = 0;
      await _player.stop();
      _broadcast(_player.playbackEvent);
      return;
    }
    // 稍等一下再跳，免得提示一闪而过；期间用户自己切了歌就算了
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (token == _loadToken) {
      await _playAt(next);
    }
  }

  Future<void> _onCompleted() async {
    final int? next = nextIndex(
      current: _index,
      length: queue.value.length,
      repeat: _repeat,
      shuffle: _shuffle,
      manual: false,
    );
    if (next == null) {
      // 队尾且不循环：停在开头
      await _player.pause();
      await _player.seek(Duration.zero);
    } else if (next == _index) {
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } else {
      await _playAt(next);
    }
  }

  // ---------- 内部：把播放器状态同步给系统 ----------

  void _broadcast(PlaybackEvent event) {
    final bool playing = _resolving ? true : _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const <MediaAction>{MediaAction.seek},
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState: _resolving
            ? AudioProcessingState.loading
            : const <ProcessingState, AudioProcessingState>{
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _index >= 0 ? _index : null,
      ),
    );
  }
}
