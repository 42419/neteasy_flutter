/// 排行榜条目（首页「排行榜」横滑卡片）。
///
/// 官方卡片是：榜名居中大字、左上角播放量、右下角播放键，卡片下方接 3 首歌名。
/// 那 3 首歌名要单独调 `/playlist/track/all` 才有——`/toplist` 里的 `tracks` 是空的。
class Rank {
  Rank({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.playCount = 0,
    this.updateFrequency = '',
    this.toplistType = '',
  });

  final int id;
  final String name;
  final String coverUrl;

  /// 榜单总播放量，卡片左上角显示
  final int playCount;

  /// 更新频率，如「每周更新」
  final String updateFrequency;

  /// 官方榜标记：N 新歌 / H 热歌 / O 原创 / S 飙升；普通曲风榜为空
  final String toplistType;

  /// 卡片下方展示的前 3 首歌名，由 HomeStore 补；空表示还没取到
  List<String> tracks = const <String>[];

  /// 歌名用顿号连成一段，官方就是这种排法
  String get trackLine => tracks.join('、');

  /// 首页排序权重：官方榜排在前面，顺序对齐官方（新歌 / 热歌 / 原创 / 飙升）
  int get homeWeight => switch (toplistType) {
    'N' => 0,
    'H' => 1,
    'O' => 2,
    'S' => 3,
    _ => 9,
  };
}
