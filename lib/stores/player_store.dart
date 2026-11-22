import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../player/netease_audio_handler.dart';
import '../viewmodels/song.dart';

/// 播放状态：界面层只和它打交道，不直接碰音频服务。
///
/// 真正在后台跑的是 [NeteaseAudioHandler]（通知栏、锁屏也控制它），
/// 这里把它的流收成界面要的几个字段。只有界面关心的字段变了才通知，
/// 缓冲进度这类高频更新不会引起整页重建。
class PlayerStore extends ChangeNotifier {
  PlayerStore(this._handler) {
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _handler.mediaItem.listen((MediaItem? item) {
        _current = item;
        notifyListeners();
      }),
      _handler.playbackState.listen(_onPlaybackState),
    ]);
  }

  final NeteaseAudioHandler _handler;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  MediaItem? _current;
  bool _playing = false;
  AudioProcessingState _processing = AudioProcessingState.idle;

  /// 当前这首（含放到一半被暂停的）；还没放过任何歌时为 null
  MediaItem? get current => _current;

  bool get hasMedia => _current != null;

  /// 用户视角的「在播放」：正在取地址 / 缓冲时也算，界面显示暂停键
  bool get playing => _playing;

  /// 正在取地址或缓冲，界面用转圈代替播放键
  bool get loading =>
      _processing == AudioProcessingState.loading ||
      _processing == AudioProcessingState.buffering;

  /// 当前歌曲 id，列表据此高亮正在播放的那一行
  int? get currentSongId => int.tryParse(_current?.id ?? '');

  /// 播放进度，只给进度环这类局部组件用，别拿它 watch 整页
  Stream<Duration> get position => AudioService.position;

  /// 要提示用户的话（无法播放、只能试听）
  Stream<String> get messages => _handler.messages;

  void _onPlaybackState(PlaybackState state) {
    final bool changed =
        state.playing != _playing || state.processingState != _processing;
    _playing = state.playing;
    _processing = state.processingState;
    if (changed) {
      notifyListeners();
    }
  }

  /// 把 [songs] 作为播放队列，从 [index] 开始放。
  Future<void> playQueue(List<Song> songs, {int index = 0}) async {
    if (songs.isEmpty) {
      return;
    }
    await _handler.playQueue(songs.map(_toMediaItem).toList(), index);
  }

  Future<void> toggle() => _playing ? _handler.pause() : _handler.play();

  Future<void> next() => _handler.skipToNext();

  Future<void> previous() => _handler.skipToPrevious();

  Future<void> seek(Duration position) => _handler.seek(position);

  MediaItem _toMediaItem(Song song) {
    return MediaItem(
      id: '${song.id}',
      title: song.name,
      artist: song.artist,
      album: song.albumName,
      duration: song.durationMs > 0
          ? Duration(milliseconds: song.durationMs)
          : null,
      artUri: _artUri(song.coverUrl),
    );
  }

  /// 通知栏、锁屏封面：https + CDN 300px 缩略图（原图动辄几百 KB）
  Uri? _artUri(String raw) {
    final String url = raw.trim();
    if (url.isEmpty) {
      return null;
    }
    final String secure = url.startsWith('http://')
        ? 'https://${url.substring(7)}'
        : url;
    return Uri.tryParse(
      secure.contains('?') ? secure : '$secure?param=300y300',
    );
  }

  @override
  void dispose() {
    for (final StreamSubscription<Object?> sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}
