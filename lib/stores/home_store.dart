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

    final Result<List<Rank>> ranks = await _repo.toplists();
    _ranks = ranks is Ok<List<Rank>> ? ranks.value : const <Rank>[];

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
