import '../../viewmodels/playlist.dart';
import '../../viewmodels/rank.dart';
import '../../viewmodels/song.dart';
import '../../viewmodels/user_profile.dart';
import 'json_utils.dart';

/// 歌单、榜单、歌曲、登录用户这几个基础模型的映射。
///
/// 都是先校验关键字段（id / 名称），缺了直接返回 null 让上层过滤，
/// 不返回半个对象。

Playlist? toPlaylist(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }
  final Map<dynamic, dynamic>? creator = asMap(json['creator']);
  return Playlist(
    id: id,
    name: name,
    coverUrl:
        (json['picUrl'] as String?) ?? (json['coverImgUrl'] as String?) ?? '',
    playCount: asInt(json['playCount']),
    trackCount: asInt(json['trackCount']),
    cloudTrackCount: asInt(json['cloudTrackCount']),
    copywriter: json['copywriter'] as String?,
    specialType: asInt(json['specialType']),
    creatorName: (creator?['nickname'] as String?) ?? '',
    creatorId: asInt(creator?['userId']),
    creatorAvatarUrl: (creator?['avatarUrl'] as String?) ?? '',
    subscribed: json['subscribed'] == true,
    updateTime: asInt(json['updateTime']),
    sharedUserIds: _sharedUserIds(json['sharedUsers']),
  );
}

/// `sharedUsers[].userId`。
///
/// 列表接口（`/user/playlist`）只给 uid、不给头像，而且**把自己也列在里面**。
/// 所以这里只负责把 uid 捞出来，「谁是对方」由 `ProfileStore` 按当前登录 uid 判断。
List<int> _sharedUserIds(Object? raw) {
  if (raw is! List) {
    return const <int>[];
  }
  return raw
      .whereType<Map>()
      .map((Map item) => asInt(item['userId']))
      .where((int id) => id > 0)
      .toList(growable: false);
}

Rank? toRank(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }
  return Rank(
    id: id,
    name: name,
    coverUrl: (json['coverImgUrl'] as String?) ?? '',
    playCount: asInt(json['playCount']),
    updateFrequency: (json['updateFrequency'] as String?) ?? '',
    toplistType: (json['ToplistType'] as String?) ?? '',
  );
}

Song? toSong(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }

  // 专辑封面：`al.picUrl` / 平铺 `picUrl`
  String cover = '';
  String albumName = '';
  final Object? album = json['al'] ?? json['album'];
  if (album is Map) {
    cover = (album['picUrl'] as String?) ?? '';
    albumName = (album['name'] as String?) ?? '';
  }
  if (cover.isEmpty) {
    cover = (json['picUrl'] as String?) ?? '';
  }

  // 歌手：`ar[]` / `artists[]` / 平铺字符串
  String artist = '';
  final Object? artists = json['ar'] ?? json['artists'];
  if (artists is List) {
    artist = artists
        .whereType<Map>()
        .map((Map item) => (item['name'] as String?) ?? '')
        .where((String part) => part.isNotEmpty)
        .join('/');
  } else if (artists is String) {
    artist = artists;
  }

  return Song(
    id: id,
    name: name,
    artist: artist,
    coverUrl: cover,
    albumName: albumName,
    durationMs: asInt(json['dt'] ?? json['duration']),
    // 每日推荐的单曲上直接带推荐语，注意空串要当成没有
    reason: firstText(<Object?>[json['reason'], json['recommendReason']]),
    // fee 可能平铺，也可能在 privilege 里
    isVip:
        asInt(json['fee']) == 1 || asInt(asMap(json['privilege'])?['fee']) == 1,
    // MV 字段在不同接口里叫 mv / mvid，0 或缺失都表示没有
    mvId: asInt(json['mv'] ?? json['mvid']),
  );
}

/// `/user/account` → 当前登录账号；游客返回 null。
///
/// 和 `/login/status` 的区别：这里的 `account.id` 是**真实 uid**（登录后
/// `/login/status` 那个还是设备游客 id，用它查用户详情会 404），
/// 且 `anonimousUser` 直接标明是不是游客身份。
UserProfile? toAccountProfile(Map<dynamic, dynamic> json) {
  final Map<dynamic, dynamic>? account = asMap(json['account']);
  if (account == null || account['anonimousUser'] == true) {
    return null;
  }
  final int uid = asInt(account['id']);
  if (uid == 0) {
    return null;
  }
  final Map<dynamic, dynamic>? profile = asMap(json['profile']);
  return UserProfile(
    uid: uid,
    nickname: (profile?['nickname'] as String?) ?? '',
    avatarUrl: (profile?['avatarUrl'] as String?) ?? '',
    backgroundUrl: (profile?['backgroundUrl'] as String?) ?? '',
    vipType: asInt(profile?['vipType'] ?? account['vipType']),
    gender: asInt(profile?['gender']),
    signature: (profile?['signature'] as String?) ?? '',
  );
}
