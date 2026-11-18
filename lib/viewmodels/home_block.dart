/// 首页区块。
///
/// 服务端（`/homepage/block/page`）按官方首页顺序返回 `blocks[]`，
/// 前端按 [blockCode] 决定用哪种样式渲染，未识别的走通用样式。
class HomeBlock {
  const HomeBlock({
    required this.blockCode,
    required this.showType,
    required this.title,
    required this.subtitle,
    required this.creatives,
  });

  final String blockCode;
  final String showType;

  /// `uiElement.mainTitle.title`，游客态常为空
  final String title;

  /// `uiElement.subTitle.title`，「推荐歌单」「新歌新碟」其实在这里
  final String subtitle;

  final List<HomeCreative> creatives;

  /// 区块头文字：主标题优先，没有就用副标题
  String get displayTitle => title.isNotEmpty ? title : subtitle;

  bool get hasHeader => displayTitle.isNotEmpty;
}

/// 区块里的一个卡片。
class HomeCreative {
  const HomeCreative({
    required this.creativeType,
    required this.action,
    required this.imageUrl,
    required this.labelTexts,
    required this.resources,
  });

  /// `list` / `SONG_LIST_HOMEPAGE` / `NEW_SONG_HOMEPAGE` …
  final String creativeType;

  /// 跳转协议，如 `orpheus://playlist/<id>`
  final String action;

  final String imageUrl;
  final List<String> labelTexts;
  final List<HomeResource> resources;

  /// 卡片主资源（歌单卡只有 1 个，歌曲卡有 3 个）
  HomeResource? get primary => resources.isEmpty ? null : resources.first;

  /// 曲风/新歌那种「一张卡里三首歌」，要按行铺开
  bool get isMultiSong =>
      resources.length > 1 || creativeType == 'SONG_LIST_HOMEPAGE';
}

/// 卡片里的资源：歌单、歌曲、专辑等。
class HomeResource {
  const HomeResource({
    required this.resourceType,
    required this.resourceId,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.labelTexts,
  });

  /// `list` / `song` / `album` …
  final String resourceType;
  final String resourceId;

  /// 歌单名或歌名
  final String name;

  /// `uiElement.mainTitle.title`
  final String title;

  /// `uiElement.subTitle.title`，歌曲里是歌手
  final String subtitle;

  final String imageUrl;
  final List<String> labelTexts;

  bool get isSong => resourceType == 'song';

  String get displayName => name.isNotEmpty ? name : title;
}
