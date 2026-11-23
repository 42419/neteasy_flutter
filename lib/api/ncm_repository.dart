import '../utils/result.dart';
import '../viewmodels/home_block.dart';
import '../viewmodels/home_entry.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';
import '../viewmodels/song_url.dart';
import '../viewmodels/user_profile.dart';
import 'api_client.dart';
import 'ncm_mapper.dart';

/// 网易云数据仓库：只调用后端已实现的路由，返回 `Result`，不抛裸异常。
///
/// 后端没有的接口不在这里做假实现，占位由页面层处理。
class NcmRepository {
  const NcmRepository(this._api);

  final ApiClient _api;

  /// 带时间戳绕过后端的 GET 缓存（二维码状态这类接口必须实时）
  String get _stamp => DateTime.now().millisecondsSinceEpoch.toString();

  // ---------- 首页 ----------

  /// 首页顶部入口卡（`/homepage/dragon/ball`）。
  ///
  /// 需要登录态，游客返回空数组；调用方拿到空列表就用内置配置兜底。
  Future<Result<List<HomeEntry>>> homeEntries() async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/homepage/dragon/ball',
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toHomeEntries(value)),
      Err(:final AppError error) => Err<List<HomeEntry>>(error),
    };
  }

  /// 首页区块（`/homepage/block/page`）：官方首页的推荐歌单、曲风、新歌新碟等
  /// 都在这个响应里按顺序返回，是首页主体的数据源。
  ///
  /// 后端对读接口缓存 2 分钟，[refresh] 为 true 时额外带时间戳绕过缓存。
  Future<Result<List<HomeBlock>>> homeBlocks({bool refresh = false}) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/homepage/block/page',
      <String, String>{
        'refresh': refresh ? 'true' : 'false',
        if (refresh) 'timestamp': _stamp,
      },
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toHomeBlocks(value)),
      Err(:final AppError error) => Err<List<HomeBlock>>(error),
    };
  }

  /// 用户的歌单（`/user/playlist`）：自建 + 收藏，第一个通常是「我喜欢的音乐」。
  Future<Result<List<Playlist>>> userPlaylists(
    int uid, {
    int limit = 30,
  }) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/user/playlist',
      <String, String>{'uid': '$uid', 'limit': '$limit'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(
        mapList<Playlist>(value['playlist'], toPlaylist),
      ),
      Err(:final AppError error) => Err<List<Playlist>>(error),
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

  /// 每日推荐歌曲（`/recommend/songs`，需要登录）。
  ///
  /// [refresh] 对应页面上的「换一批」。**刷新靠 `afresh=true`，不是时间戳**：
  /// 每日推荐一天一批，光带 `timestamp` 只能绕过后端 2 分钟缓存，
  /// 上游照旧返回同一批，看起来就像按钮没反应。
  Future<Result<List<Song>>> dailySongs({bool refresh = false}) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/recommend/songs',
      refresh ? <String, String>{'afresh': 'true', 'timestamp': _stamp} : null,
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
  ///
  /// 只用来判断「有没有登录」。**不要拿它的 uid 查用户数据**：登录后这里返回的
  /// 仍是设备游客 id，用它请求 `/user/detail/new` 会 404。真实 uid 走 [accountProfile]。
  Future<Result<UserProfile?>> loginProfile() async {
    final Result<Map<String, dynamic>> result = await _api.get('/login/status');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toLoginProfile(value)),
      Err(:final AppError error) => Err<UserProfile?>(error),
    };
  }

  /// 当前登录账号（`/user/account`）；游客返回 `Ok(null)`。
  ///
  /// 这里的 `account.id` 是真实 uid，用户详情、歌单列表都要用它。
  Future<Result<UserProfile?>> accountProfile() async {
    final Result<Map<String, dynamic>> result = await _api.get('/user/account');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toAccountProfile(value)),
      Err(:final AppError error) => Err<UserProfile?>(error),
    };
  }

  // ---------- 我的 ----------

  /// 用户详情（`/user/detail/new`）：昵称、头像、签名、关注数、等级、听歌数。
  ///
  /// 和 `/login/status` 的区别：那个只回答「当前是谁」，这里带上「我的」页要展示的统计。
  Future<Result<UserProfile>> userDetailNew(int uid) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/user/detail/new',
      <String, String>{'uid': '$uid'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => switch (toUserDetail(
        value,
        fallbackUid: uid,
      )) {
        final UserProfile profile => Ok(profile),
        null => const Err<UserProfile>(AppError('用户信息为空')),
      },
      Err(:final AppError error) => Err<UserProfile>(error),
    };
  }

  /// 会员等级与 SVIP 状态（`/vip/info/v2`）
  Future<Result<({int level, bool svipActive})>> vipStatus() async {
    final Result<Map<String, dynamic>> result = await _api.get('/vip/info/v2');
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toVipStatus(value)),
      Err(:final AppError error) => Err<({int level, bool svipActive})>(error),
    };
  }

  /// 能佩戴的徽章数（`/user/medal`）
  ///
  /// 必须带 uid：不传时上游按「当前会话」查，拿到的是 499 用户信息获取失败。
  Future<Result<int>> badgeCount(int uid) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/user/medal',
      <String, String>{'uid': '$uid'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toBadgeCount(value)),
      Err(:final AppError error) => Err<int>(error),
    };
  }

  /// 累计听歌小时数（`/listen/data/total`，接口给秒）
  Future<Result<int>> listenHours() async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/listen/data/total',
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toListenHours(value)),
      Err(:final AppError error) => Err<int>(error),
    };
  }

  /// 创建 / 收藏的歌单数（`/user/subcount`）
  Future<Result<({int created, int collected})>> subcount() async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/user/subcount',
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toSubcount(value)),
      Err(:final AppError error) => Err<({int created, int collected})>(error),
    };
  }

  /// 最近一周播放最多的一首（`/user/record?type=1`）。
  ///
  /// `type=1` 才是最近一周（weekData），`type=0` 是全部时间；「听歌排行」封面用前者。
  Future<Result<Song?>> weeklyTopSong(int uid) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/user/record',
      <String, String>{'uid': '$uid', 'type': '1'},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => Ok(toWeeklyTopSong(value)),
      Err(:final AppError error) => Err<Song?>(error),
    };
  }

  // ---------- 播放 ----------

  /// 播放地址（`/song/url/v1`）。
  ///
  /// 地址有时效，播放前现取，不要缓存。没有地址（无版权、下架、VIP 且不能试听）
  /// 返回 Err。[level] 是期望音质，服务端按账号权限降档：
  /// standard / higher / exhigh（极高，320k）/ lossless …
  Future<Result<SongUrl>> songUrl(int id, {String level = 'exhigh'}) async {
    final Result<Map<String, dynamic>> result = await _api.get(
      '/song/url/v1',
      <String, String>{'id': '$id', 'level': level},
    );
    return switch (result) {
      Ok(:final Map<String, dynamic> value) => switch (toSongUrl(value)) {
        final SongUrl url => Ok(url),
        null => const Err<SongUrl>(AppError('暂时无法播放')),
      },
      Err(:final AppError error) => Err<SongUrl>(error),
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
