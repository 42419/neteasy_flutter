/// 首页用到的数据模型。
///
/// 字段名对齐 Rust 后端（neteasy-backend v0.2.0）返回的网易云原始 JSON，
/// 解析口径参考 Kotlin 版 `data/model/Models.kt` 的 parsePersonalized / parseToplist。
library;

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.playCount = 0,
    this.trackCount = 0,
    this.copywriter,
  });

  final int id;
  final String name;
  final String coverUrl;
  final int playCount;
  final int trackCount;
  final String? copywriter;

  static Playlist? tryParse(Map<dynamic, dynamic> json) {
    final id = _asInt(json['id']);
    final name = (json['name'] as String?) ?? '';
    if (id == 0 || name.isEmpty) return null;
    return Playlist(
      id: id,
      name: name,
      coverUrl:
          (json['picUrl'] as String?) ?? (json['coverImgUrl'] as String?) ?? '',
      playCount: _asInt(json['playCount']),
      trackCount: _asInt(json['trackCount']),
      copywriter: json['copywriter'] as String?,
    );
  }
}

class Rank {
  const Rank({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.updateFrequency = '',
  });

  final int id;
  final String name;
  final String coverUrl;
  final String updateFrequency;

  static Rank? tryParse(Map<dynamic, dynamic> json) {
    final id = _asInt(json['id']);
    final name = (json['name'] as String?) ?? '';
    if (id == 0 || name.isEmpty) return null;
    return Rank(
      id: id,
      name: name,
      coverUrl: (json['coverImgUrl'] as String?) ?? '',
      updateFrequency: (json['updateFrequency'] as String?) ?? '',
    );
  }
}

class Song {
  const Song({
    required this.id,
    required this.name,
    required this.artist,
    this.coverUrl = '',
    this.albumName = '',
    this.durationMs = 0,
  });

  final int id;
  final String name;
  final String artist;
  final String coverUrl;
  final String albumName;
  final int durationMs;

  /// 网易云的 song JSON 有两种形态：搜索结果顶层同层字段；详情/歌单里套在 `al`/`ar` 下
  static Song? tryParse(Map<dynamic, dynamic> json) {
    final id = _asInt(json['id']);
    final name = (json['name'] as String?) ?? '';
    if (id == 0 || name.isEmpty) return null;

    final album = json['al'] ?? json['album'];
    final artists = json['ar'] ?? json['artists'];

    var cover = '';
    var albumName = '';
    if (album is Map) {
      cover = (album['picUrl'] as String?) ?? '';
      albumName = (album['name'] as String?) ?? '';
    }
    if (cover.isEmpty) cover = (json['picUrl'] as String?) ?? '';

    var artist = '';
    if (artists is List && artists.isNotEmpty) {
      artist = artists
          .whereType<Map>()
          .map((a) => (a['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .join('/');
    }
    if (artist.isEmpty) {
      final ar = json['artists'];
      if (ar is String) artist = ar;
    }

    return Song(
      id: id,
      name: name,
      artist: artist,
      coverUrl: cover,
      albumName: albumName,
      durationMs: _asInt(json['dt'] ?? json['duration']),
    );
  }
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
