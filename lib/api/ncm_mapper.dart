import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';

/// 网易云原始 JSON → viewmodels。
///
/// 所有容错都收敛在这里：字段缺失返回 null 让上层过滤，不在页面里做 `as` 强转。
/// 字段口径对齐 Kotlin 版 `data/model/Models.kt` 的 parseBanners / parsePersonalized / parseToplist。
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
    updateFrequency: (json['updateFrequency'] as String?) ?? '',
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
  );
}

/// 把列表字段映射成模型列表，丢弃解析失败的条目。
List<T> mapList<T>(Object? raw, T? Function(Map<dynamic, dynamic>) parse) {
  if (raw is! List) {
    return const <Never>[];
  }
  return raw
      .whereType<Map<dynamic, dynamic>>()
      .map(parse)
      .whereType<T>()
      .toList(growable: false);
}

/// JSON 里的数字可能是 int / double / 字符串，统一取 int。
int asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
