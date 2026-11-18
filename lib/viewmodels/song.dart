/// 歌曲。
///
/// 网易云的歌曲 JSON 有两种形态：搜索/详情把专辑放在 `al`、歌手放在 `ar`，
/// 另一些接口直接平铺 `picUrl`/`artists`，取值时都兜住。
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

  /// 列表里副标题：歌手 · 专辑，空的部分自动省略。
  String get subtitle {
    if (artist.isEmpty) {
      return albumName;
    }
    if (albumName.isEmpty) {
      return artist;
    }
    return '$artist · $albumName';
  }
}
