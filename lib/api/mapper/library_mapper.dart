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
  return Playlist(
    id: id,
    name: name,
    coverUrl:
        (json['picUrl'] as String?) ?? (json['coverImgUrl'] as String?) ?? '',
    playCount: asInt(json['playCount']),
    trackCount: asInt(json['trackCount']),
    copywriter: json['copywriter'] as String?,
    specialType: asInt(json['specialType']),
  );
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
  );
}

/// 登录态响应 → 用户资料；未登录返回 null。
///
/// 结构是 `{ data: { code, account, profile } }`——外层没有 code，**code 在 data 里**，
/// 且 `account` 只有 id，昵称头像在 `profile`。
UserProfile? toLoginProfile(Map<dynamic, dynamic> json) {
  final Object? data = json['data'];
  if (data is! Map) {
    return null;
  }
  if (asInt(data['code']) != 200) {
    return null;
  }
  final Object? account = data['account'];
  final int uid = account is Map ? asInt(account['id']) : 0;
  if (uid == 0) {
    return null;
  }
  final Object? profile = data['profile'] ?? account;
  return UserProfile(
    uid: uid,
    nickname: profile is Map ? (profile['nickname'] as String?) ?? '' : '',
    avatarUrl: profile is Map ? (profile['avatarUrl'] as String?) ?? '' : '',
    vipType: profile is Map ? asInt(profile['vipType']) : 0,
  );
}
