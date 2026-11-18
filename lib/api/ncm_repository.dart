import '../utils/result.dart';
import '../viewmodels/home_block.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';
import '../viewmodels/user_profile.dart';
import 'api_client.dart';
import 'ncm_mapper.dart';

/// 网易云数据仓库：只调用后端已实现的路由，返回 `Result`，不抛裸异常。
///
/// 后端目前只实现了 24 个接口，首页若干模块没有数据源，对应占位由页面层处理，
/// 这里不提供假实现。
class NcmRepository {
  const NcmRepository(this._api);

  final ApiClient _api;

  /// 带时间戳绕过后端的 GET 缓存（二维码状态这类接口必须实时）
  String get _stamp => DateTime.now().millisecondsSinceEpoch.toString();

  // ---------- 首页 ----------

  /// 首页区块（`/homepage/block/page`）：官方首页的推荐歌单、曲风、新歌新碟等
  /// 都在这个响应里按顺序返回，是首页主体的数据源。
  Future<Result<List<HomeBlock>>> homeBlocks({bool refresh = false}) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/homepage/block/page',
      <String, String>{'refresh': refresh ? 'true' : 'false'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toHomeBlocks(value)),
      Err(:final AppError error) => Err<List<HomeBlock>>(error),
    };
  }

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

  /// 榜单前 N 首歌名（`/playlist/track/all`）：`/toplist` 的 `tracks` 是空的，
  /// 首页榜单卡下方的三首歌名只能单独取。只带 limit 时响应约 7KB，比详情接口轻得多。
  Future<Result<List<String>>> toplistTrackNames(
    int id, {
    int limit = 3,
  }) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/playlist/track/all',
      <String, String>{'id': '$id', 'limit': '$limit'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        toTrackNames(value, limit: limit),
      ),
      Err(:final AppError error) => Err<List<String>>(error),
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

  // ---------- 登录 ----------

  /// 二维码 unikey（`/login/qr/key`）
  Future<Result<String>> qrKey() async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/login/qr/key',
      <String, String>{'timestamp': _stamp},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(_readNested(value, 'unikey')),
      Err(:final AppError error) => Err<String>(error),
    };
  }

  /// 二维码图片：后端返回 `data:image/png;base64,...` 的 data url（`/login/qr/create`）
  Future<Result<String>> qrImage(String key) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/login/qr/create',
      <String, String>{'key': key, 'qrimg': 'true', 'timestamp': _stamp},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(_readNested(value, 'qrimg')),
      Err(:final AppError error) => Err<String>(error),
    };
  }

  /// 轮询扫码状态（`/login/qr/check`），返回 801/800/802/803
  Future<Result<int>> qrCheck(String key) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/login/qr/check',
      <String, String>{'key': key, 'timestamp': _stamp},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(asInt(value['code'])),
      Err(:final AppError error) => Err<int>(error),
    };
  }

  /// 当前登录用户（`/login/status`）；未登录返回 `Ok(null)`。
  Future<Result<UserProfile?>> loginProfile() async {
    final Result<Map<String, dynamic>> result = await _api.get('/login/status');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toLoginProfile(value)),
      Err(:final AppError error) => Err<UserProfile?>(error),
    };
  }

  /// 取 `data.<field>`，缺失时返回空串
  String _readNested(Map<String, dynamic> json, String field) {
    final Object? data = json['data'];
    if (data is Map) {
      final Object? value = data[field];
      if (value is String) {
        return value;
      }
    }
    return '';
  }
}
