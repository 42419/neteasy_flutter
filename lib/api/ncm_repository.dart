import '../utils/result.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';
import 'api_client.dart';
import 'ncm_mapper.dart';

/// 网易云数据仓库：只调用后端已实现的路由，返回 `Result`，不抛裸异常。
///
/// 后端（neteasy-backend v0.2.0）目前只实现了 24 个接口，首页若干模块没有数据源，
/// 对应的占位由页面层处理，这里不提供假实现。
class NcmRepository {
  const NcmRepository(this._api);

  final ApiClient _api;

  /// 推荐歌单（`/personalized`）
  Future<Result<List<Playlist>>> recommendPlaylists({int limit = 6}) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/personalized',
      <String, String>{'limit': '$limit'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        mapList<Playlist>(value['result'], toPlaylist),
      ),
      Err(:final AppError error) => Err<List<Playlist>>(error),
    };
  }

  /// 排行榜（`/toplist`）。字段在不同版本里叫 `list` 或 `data`，都试一下。
  Future<Result<List<Rank>>> toplists({int limit = 10}) async {
    final Result<Map<String, dynamic>> result = await _api.get('/toplist');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        mapList<Rank>(
          value['list'] ?? value['data'],
          toRank,
        ).take(limit).toList(growable: false),
      ),
      Err(:final AppError error) => Err<List<Rank>>(error),
    };
  }

  /// 每日推荐歌曲（`/recommend/songs`，需要登录）
  Future<Result<List<Song>>> dailySongs() async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/recommend/songs',
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        mapList<Song>(
          value['data'] is Map
              ? (value['data'] as Map)['dailySongs']
              : value['songs'],
          toSong,
        ),
      ),
      Err(:final AppError error) => Err<List<Song>>(error),
    };
  }

  /// 当前登录用户 id（`/login/status`）；未登录返回 `Ok(null)`。
  Future<Result<int?>> currentUid() async {
    final Result<Map<String, dynamic>> result = await _api.get('/login/status');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        value['account'] is Map ? asInt((value['account'] as Map)['id']) : null,
      ),
      Err(:final AppError error) => Err<int?>(error),
    };
  }
}
