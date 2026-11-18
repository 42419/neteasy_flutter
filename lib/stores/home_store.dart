import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/home_block.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';

/// 首页状态。
///
/// 主体是服务端按官方顺序返回的 `blocks`，页面按 blockCode 决定样式；
/// 排行榜和每日推荐是独立接口，单独加载。
class HomeStore extends ChangeNotifier {
  HomeStore(this._repo, {this.uidProvider});

  final NcmRepository _repo;

  /// 当前登录用户 id 的来源；返回 null 表示未登录
  final int? Function()? uidProvider;

  bool _loading = true;
  String? _error;
  List<HomeBlock> _blocks = const <HomeBlock>[];
  List<Rank> _ranks = const <Rank>[];
  List<Song> _daily = const <Song>[];
  int? _uid;
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;
  List<HomeBlock> get blocks => _blocks;
  List<Rank> get ranks => _ranks;
  List<Song> get daily => _daily;
  int? get uid => _uid;
  bool get loggedIn => _uid != null;

  /// 首页排行榜展示的卡片数
  static const int homeRankCount = 6;

  /// 拉首页所需数据。下拉刷新、首次进入、登录状态变化都走这里。
  Future<void> load() async {
    _loading = true;
    _error = null;
    _safeNotify();

    final Result<List<HomeBlock>> blocks = await _repo.homeBlocks();
    if (blocks is Err<List<HomeBlock>>) {
      _error = blocks.error.message;
      _loading = false;
      _safeNotify();
      return;
    }
    _blocks = (blocks as Ok<List<HomeBlock>>).value;

    _ranks = await _loadRanks();

    // 未登录就不请求需要登录的接口，省一次必然失败的往返
    _uid = uidProvider?.call();
    if (_uid != null) {
      final Result<List<Song>> daily = await _repo.dailySongs();
      _daily = daily is Ok<List<Song>> ? daily.value : const <Song>[];
    } else {
      _daily = const <Song>[];
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
