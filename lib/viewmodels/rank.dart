/// 排行榜条目（首页「排行榜」横滑卡片）。
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

  /// 更新频率，如「每周更新」，官方卡片下方就显示这个。
  final String updateFrequency;

  /// 「新歌榜」拆成「新歌」+「榜」两行，官方卡片是竖排的。
  String get head => name.length > 2 ? name.substring(0, 2) : name;

  String get tail => name.length > 2 ? name.substring(2) : '';
}
