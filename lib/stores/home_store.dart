import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';

/// 首页状态。
///
/// 页面只读这里的数据，不自己发请求；登录态是附加信息，失败不影响首页主体。
class HomeStore extends ChangeNotifier {
  HomeStore(this._repo);

  final NcmRepository _repo;

  bool _loading = true;
  String? _error;
  List<Playlist> _recommended = const <Playlist>[];
  List<Rank> _ranks = const <Rank>[];
  List<Song> _daily = const <Song>[];
  int? _uid;
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;
  List<Playlist> get recommended => _recommended;
  List<Rank> get ranks => _ranks;
  List<Song> get daily => _daily;
  int? get uid => _uid;
  bool get loggedIn => _uid != null;

  /// 拉首页所需的全部数据。下拉刷新与首次进入共用。
  Future<void> load() async {
    _loading = true;
    _error = null;
    _safeNotify();

    final Result<List<Playlist>> playlists = await _repo.recommendPlaylists();
    if (playlists is Err<List<Playlist>>) {
      _error = playlists.error.message;
      _loading = false;
      _safeNotify();
      return;
    }
    _recommended = (playlists as Ok<List<Playlist>>).value;

    final Result<List<Rank>> ranks = await _repo.toplists();
    _ranks = ranks is Ok<List<Rank>> ? ranks.value : const <Rank>[];

    // 登录态失败不当成首页失败：游客也能看推荐歌单和排行榜
    final Result<int?> uid = await _repo.currentUid();
    _uid = uid is Ok<int?> ? uid.value : null;
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
