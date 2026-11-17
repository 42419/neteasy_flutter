import '../data/api_client.dart';
import '../models/home_models.dart';

/// 首页数据源。只调用后端已实现的接口（neteasy-backend v0.2.0 的 24 个路由）。
///
/// 网易云首页还有「近期云村热播 / 艺人定制 / 雷达歌单 / 热门播客 / SVIP 有声书」等模块，
/// 后端没有对应路由，先不做——不要用假数据填。
class HomeRepository {
  const HomeRepository(this._api);

  final ApiClient _api;

  /// 推荐歌单（`/personalized`）
  Future<List<Playlist>> recommendPlaylists({int limit = 6}) async {
    final json = await _api.get('/personalized', {'limit': '$limit'});
    return _mapList(json['result'], Playlist.tryParse);
  }

  /// 排行榜（`/toplist`）
  Future<List<Rank>> toplists() async {
    final json = await _api.get('/toplist');
    // 该接口的列表字段在不同版本里叫 list / data，都试一下
    return _mapList(json['list'] ?? json['data'], Rank.tryParse);
  }

  /// 每日推荐歌曲（`/recommend/songs`，需要登录）
  Future<List<Song>> dailySongs() async {
    final json = await _api.get('/recommend/songs');
    final data = json['data'];
    if (data is Map) {
      return _mapList(
        data['dailySongs'] ?? data['recommendReasons'],
        Song.tryParse,
      );
    }
    return _mapList(json['songs'], Song.tryParse);
  }

  /// 当前用户的歌单（`/user/playlist`，需要登录）
  Future<List<Playlist>> userPlaylists(int uid) async {
    final json = await _api.get('/user/playlist', {
      'uid': '$uid',
      'limit': '1000',
    });
    return _mapList(json['playlist'], Playlist.tryParse);
  }

  /// 是否已登录（`/login/status`）
  Future<int?> currentUid() async {
    final json = await _api.get('/login/status');
    final account = json['account'];
    if (account is Map) {
      final id = account['id'];
      if (id is int) return id;
    }
    return null;
  }

  List<T> _mapList<T>(Object? raw, T? Function(Map<dynamic, dynamic>) parse) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(parse)
        .whereType<T>()
        .toList(growable: false);
  }
}
