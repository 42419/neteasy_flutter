import '../../viewmodels/user_profile.dart';
import 'json_utils.dart';

/// `/user/detail/new` → 用户资料（含关注数、等级、听歌数）。
///
/// 统计字段散在顶层和 `profile` 里：`level` / `listenSongs` /
/// `peopleCanSeeMyPlayRecord` 在顶层，关注数在 `profile`。两边都兜一下，
/// 上游换位置也不会整块丢失。
UserProfile? toUserDetail(Map<dynamic, dynamic> json, {int fallbackUid = 0}) {
  final Map<dynamic, dynamic>? profile = asMap(json['profile']);
  final int uid =
      asInt(profile?['userId'] ?? profile?['id'] ?? json['userId']) != 0
      ? asInt(profile?['userId'] ?? profile?['id'] ?? json['userId'])
      : fallbackUid;
  if (uid == 0) {
    return null;
  }
  final String nickname = (profile?['nickname'] as String?) ?? '';
  return UserProfile(
    uid: uid,
    nickname: nickname,
    avatarUrl:
        (profile?['avatarUrl'] as String?) ??
        (profile?['avatarImgUrl'] as String?) ??
        '',
    vipType: asInt(profile?['vipType']),
    gender: asInt(profile?['gender']),
    signature: (profile?['signature'] as String?) ?? '',
    follows: asInt(profile?['follows']),
    followeds: asInt(profile?['followeds']),
    level: asInt(json['level'] ?? profile?['level']),
    listenSongs: asInt(json['listenSongs'] ?? profile?['listenSongs']),
    // 字段缺失时按「公开」处理：拿不到就别挂锁，免得误导
    recordPrivate: json['peopleCanSeeMyPlayRecord'] == false,
  );
}

/// `/vip/info/v2` → (等级, SVIP 是否在有效期内)。
///
/// 等级取 `data.redVipLevel`（1–10，对应「壹」到「拾」）；
/// SVIP 的判断看 `data.redplus.expireTime` 是否大于 `data.now`。
({int level, bool svipActive}) toVipStatus(Map<dynamic, dynamic> json) {
  final Map<dynamic, dynamic>? data = asMap(json['data']);
  if (data == null) {
    return (level: 0, svipActive: false);
  }
  final int level = asInt(data['redVipLevel']);
  final int now = asInt(data['now']);
  final Map<dynamic, dynamic>? redplus = asMap(data['redplus']);
  final int expire = asInt(redplus?['expireTime']);
  return (level: level, svipActive: expire > 0 && expire > now);
}

/// `/user/medal` → 能佩戴的徽章数。
///
/// 不能用 `data.medalNum`：它包含两枚不能佩戴的会员徽章，页面上的数字
/// 是 `obtainMedals` 里 `canWear == true` 的个数。
int toBadgeCount(Map<dynamic, dynamic> json) {
  final Map<dynamic, dynamic>? data = asMap(json['data']);
  final Object? medals = data?['obtainMedals'];
  if (medals is! List) {
    return 0;
  }
  return medals
      .whereType<Map>()
      .where((Map item) => item['canWear'] == true)
      .length;
}

/// `/listen/data/total` → 累计听歌小时数。
///
/// 接口给的是秒，页面按小时向下取整。
int toListenHours(Map<dynamic, dynamic> json) {
  final Map<dynamic, dynamic>? data = asMap(json['data']);
  final int seconds = asInt(data?['totalDuration']);
  return seconds <= 0 ? 0 : seconds ~/ 3600;
}

/// `/user/subcount` → (创建数, 收藏数)。
({int created, int collected}) toSubcount(Map<dynamic, dynamic> json) {
  return (
    created: asInt(json['createdPlaylistCount']),
    collected: asInt(json['subPlaylistCount']),
  );
}
