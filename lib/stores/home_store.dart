import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/home_snapshot_store.dart';
import '../utils/result.dart';
import '../viewmodels/home_block.dart';
import '../viewmodels/home_entry.dart';
import '../viewmodels/home_snapshot.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';

/// 首页状态。
///
/// 主体是服务端按官方顺序返回的 `blocks`，页面按 blockCode 决定样式；
/// 排行榜和「我的歌单」是独立接口，和区块并行加载。
class HomeStore extends ChangeNotifier {
  HomeStore(
    this._repo, {
    this.uidProvider,
    this.nicknameProvider,
    this._snapshotStore,
    this._loggedInProvider,
  });

  final NcmRepository _repo;

  /// 上次成功加载的快照；null 表示不落盘（测试里就是这么用的）
  final HomeSnapshotStore? _snapshotStore;

  /// 当前是否已登录。cookie 在建 ApiClient 时就能读到，早于 [restoreCached]
  final bool Function()? _loggedInProvider;

  /// 当前登录用户 id 的来源；返回 null 表示未登录
  final int? Function()? uidProvider;

  /// 当前登录用户昵称的来源
  final String? Function()? nicknameProvider;

  /// 首次加载才显示整页转圈；之后的刷新保留旧内容，别把列表和滚动位置换掉
  bool _loading = true;
  String? _error;
  List<HomeBlock> _blocks = const <HomeBlock>[];
  List<HomeEntry> _entries = const <HomeEntry>[];
  List<Rank> _ranks = const <Rank>[];
  List<Playlist> _myPlaylists = const <Playlist>[];
  int? _uid;
  String _nickname = '';

  /// 每日推荐第一首的封面，用作首张入口卡的底图
  String _dailyCover = '';
  bool _disposed = false;

  /// 并发的 load 只认最后一次：登录态恢复和登录回调可能先后各触发一次
  int _generation = 0;

  bool get loading => _loading;

  /// 只有「没有任何内容可显示」时才有值
  String? get error => _error;
  List<HomeBlock> get blocks => _blocks;

  /// 顶部入口卡：登录态才有数据，空表示用页面内置的默认配置
  List<HomeEntry> get entries => _entries;
  List<Rank> get ranks => _ranks;
  List<Playlist> get myPlaylists => _myPlaylists;
  int? get uid => _uid;
  String get nickname => _nickname;

  /// 每日推荐第一首的封面；空表示未登录或还没取到
  String get dailyCover => _dailyCover;
  bool get loggedIn => _uid != null;

  /// 首页排行榜展示的卡片数
  static const int homeRankCount = 6;

  /// 用启动时读到的快照铺首屏：同步、不等 IO，首帧就有内容。
  ///
  /// 启动时调用一次。之后的 [load] 会静默刷新并原地替换，因为此时已经有内容，
  /// `loading` 不会再被置回 true，页面也就不会退回骨架屏。
  void hydrate(HomeSnapshot? snapshot) {
    if (snapshot == null || snapshot.isEmpty) {
      return;
    }
    _blocks = snapshot.blocks;
    _ranks = snapshot.ranks;
    // 登录态才有数据的那几块（入口卡、我的歌单、每日推荐封面）只在身份一致时复用，
    // 否则会把上一个账号的内容铺给游客
    final bool loggedIn = _loggedInProvider?.call() ?? false;
    if (loggedIn == snapshot.loggedIn) {
      _entries = snapshot.entries;
      _myPlaylists = snapshot.myPlaylists;
      _dailyCover = snapshot.dailyCover;
      _nickname = snapshot.nickname;
      _uid = snapshot.uid;
    }
    _loading = false;
    _safeNotify();
  }

  /// 把这次成功的结果落盘，下次冷启动直接铺。失败不影响当前会话。
  void _persist() {
    final HomeSnapshotStore? store = _snapshotStore;
    if (store == null || _blocks.isEmpty) {
      return;
    }
    unawaited(
      store.save(
        HomeSnapshot(
          loggedIn: _uid != null,
          uid: _uid,
          nickname: _nickname,
          dailyCover: _dailyCover,
          entries: _entries,
          blocks: _blocks,
          ranks: _ranks,
          myPlaylists: _myPlaylists,
          savedAt: DateTime.now(),
        ),
      ),
    );
  }

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
    final Future<Result<List<HomeEntry>>> entriesFuture = _repo.homeEntries();
    final Future<List<Rank>> ranksFuture = _loadRanks();
    // 未登录不请求需要登录的接口，省一次必然失败的往返
    final Future<Result<List<Playlist>>> mineFuture = uid == null
        ? Future<Result<List<Playlist>>>.value(
            const Ok<List<Playlist>>(<Playlist>[]),
          )
        : _repo.userPlaylists(uid);
    // 首张入口卡（每日推荐）的背景就是今天第一首推荐的专辑封面
    final Future<Result<List<Song>>> dailyFuture = uid == null
        ? Future<Result<List<Song>>>.value(const Ok<List<Song>>(<Song>[]))
        : _repo.dailySongs();

    final Result<List<HomeBlock>> blocks = await blocksFuture;
    final Result<List<HomeEntry>> entries = await entriesFuture;
    final List<Rank> ranks = await ranksFuture;
    final Result<List<Playlist>> mine = await mineFuture;
    final Result<List<Song>> daily = await dailyFuture;
    if (generation != _generation) {
      return;
    }

    _uid = uid;
    _nickname = nickname;
    if (uid == null) {
      // 登出后这些「登录态才有」的数据必须清掉：入口卡和每日推荐接口对游客返回空，
      // 下面的「空返回不覆盖」会让上一个账号的内容一直留着，还会被写进快照
      _entries = const <HomeEntry>[];
      _myPlaylists = const <Playlist>[];
      _dailyCover = '';
    }
    if (blocks is Ok<List<HomeBlock>>) {
      _blocks = blocks.value;
    }
    // 入口卡只有登录态才下发，空返回不覆盖已有数据
    if (entries is Ok<List<HomeEntry>> && entries.value.isNotEmpty) {
      _entries = entries.value;
    }
    // 榜单和歌单失败时保留旧数据，不用空列表覆盖
    if (ranks.isNotEmpty) {
      _ranks = ranks;
    }
    if (mine is Ok<List<Playlist>>) {
      _myPlaylists = mine.value;
    }
    if (daily is Ok<List<Song>> && daily.value.isNotEmpty) {
      _dailyCover = daily.value.first.coverUrl;
    }

    final bool hasAny = _blocks.isNotEmpty || _ranks.isNotEmpty;
    _error = (!hasAny && blocks is Err<List<HomeBlock>>)
        ? blocks.error.message
        : null;
    // 只有区块这次真的取到了才落盘，避免网络抖动时把旧快照反复写一遍
    if (blocks is Ok<List<HomeBlock>>) {
      _persist();
    }
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
