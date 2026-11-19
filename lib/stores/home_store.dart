import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/home_block.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';

/// 首页状态。
///
/// 主体是服务端按官方顺序返回的 `blocks`，页面按 blockCode 决定样式；
/// 排行榜和「我的歌单」是独立接口，和区块并行加载。
class HomeStore extends ChangeNotifier {
  HomeStore(this._repo, {this.uidProvider, this.nicknameProvider});

  final NcmRepository _repo;

  /// 当前登录用户 id 的来源；返回 null 表示未登录
  final int? Function()? uidProvider;

  /// 当前登录用户昵称的来源
  final String? Function()? nicknameProvider;

  /// 首次加载才显示整页转圈；之后的刷新保留旧内容，别把列表和滚动位置换掉
  bool _loading = true;
  String? _error;
  List<HomeBlock> _blocks = const <HomeBlock>[];
  List<Rank> _ranks = const <Rank>[];
  List<Playlist> _myPlaylists = const <Playlist>[];
  int? _uid;
  String _nickname = '';
  bool _disposed = false;

  /// 并发的 load 只认最后一次：登录态恢复和登录回调可能先后各触发一次
  int _generation = 0;

  bool get loading => _loading;

  /// 只有「没有任何内容可显示」时才有值
  String? get error => _error;
  List<HomeBlock> get blocks => _blocks;
  List<Rank> get ranks => _ranks;
  List<Playlist> get myPlaylists => _myPlaylists;
  int? get uid => _uid;
  String get nickname => _nickname;
  bool get loggedIn => _uid != null;

  /// 首页排行榜展示的卡片数
  static const int homeRankCount = 6;

  /// 拉首页所需数据。下拉刷新、首次进入、登录状态变化都走这里。
  Future<void> load() async {
    final int generation = ++_generation;
    final bool hasContent = _blocks.isNotEmpty || _ranks.isNotEmpty;
    if (!hasContent) {
      _loading = true;
      _error = null;
      _safeNotify();
    }

    final int? uid = uidProvider?.call();
    final String nickname = nicknameProvider?.call() ?? '';

    // 三个请求并行发出，再依次取结果
    final Future<Result<List<HomeBlock>>> blocksFuture = _repo.homeBlocks(
      refresh: true,
    );
    final Future<List<Rank>> ranksFuture = _loadRanks();
    // 未登录不请求需要登录的接口，省一次必然失败的往返
    final Future<Result<List<Playlist>>> mineFuture = uid == null
        ? Future<Result<List<Playlist>>>.value(
            const Ok<List<Playlist>>(<Playlist>[]),
          )
        : _repo.userPlaylists(uid);

    final Result<List<HomeBlock>> blocks = await blocksFuture;
    final List<Rank> ranks = await ranksFuture;
    final Result<List<Playlist>> mine = await mineFuture;
    if (generation != _generation) {
      return;
    }

    _uid = uid;
    _nickname = nickname;
    if (blocks is Ok<List<HomeBlock>>) {
      _blocks = blocks.value;
    }
    // 榜单和歌单失败时保留旧数据，不用空列表覆盖
    if (ranks.isNotEmpty) {
      _ranks = ranks;
    }
    if (mine is Ok<List<Playlist>>) {
      _myPlaylists = mine.value;
    }

    final bool hasAny = _blocks.isNotEmpty || _ranks.isNotEmpty;
    _error = (!hasAny && blocks is Err<List<HomeBlock>>)
        ? blocks.error.message
        : null;
    _loading = false;
    _safeNotify();
  }

  /// 榜单：官方榜（新歌/热歌/原创/飙升）排前，其后按播放量补到 6 个；
  /// 每个榜再补前 3 首歌名给卡片下方用。
  Future<List<Rank>> _loadRanks() async {
    final Result<List<Rank>> ranks = await _repo.toplists(limit: 20);
    if (ranks is! Ok<List<Rank>>) {
      return const <Rank>[];
    }
    final List<Rank> sorted = List<Rank>.of(ranks.value)
      ..sort((Rank a, Rank b) {
        final int byType = a.homeWeight.compareTo(b.homeWeight);
        return byType != 0 ? byType : b.playCount.compareTo(a.playCount);
      });
    final List<Rank> top = sorted.take(homeRankCount).toList();

    await Future.wait(
      top.map((Rank rank) async {
        final Result<List<String>> names = await _repo.toplistTrackNames(
          rank.id,
        );
        if (names is Ok<List<String>>) {
          rank.tracks = names.value;
        }
      }),
    );
    return top;
  }

  /// 异步返回后 store 可能已随页面销毁，别再调 notifyListeners
  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
