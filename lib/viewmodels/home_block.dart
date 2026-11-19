/// 首页区块。
///
/// 服务端（`/homepage/block/page`）按官方首页顺序返回 `blocks[]`，
/// 页面按 [blockCode] 选择渲染方式；不认识的区块直接不渲染。
class HomeBlock {
  const HomeBlock({
    required this.blockCode,
    required this.showType,
    required this.title,
    required this.subtitle,
    required this.hasMore,
    required this.creatives,
    this.books = const <HomeBook>[],
  });

  // ---------- 已适配的 blockCode ----------

  /// 推荐歌单
  static const String playlistRcmd = 'HOMEPAGE_BLOCK_PLAYLIST_RCMD';

  /// 曲风推荐：一卡三首歌
  static const String styleRcmd = 'HOMEPAGE_BLOCK_STYLE_RCMD';

  /// 雷达歌单
  static const String mgcPlaylist = 'HOMEPAGE_BLOCK_MGC_PLAYLIST';

  /// 新歌新碟
  static const String newAlbumNewSong = 'HOMEPAGE_BLOCK_NEW_ALBUM_NEW_SONG';

  /// 专属场景歌单
  static const String officialPlaylist = 'HOMEPAGE_BLOCK_OFFICIAL_PLAYLIST';

  /// 视频合辑
  static const String videoPlaylist = 'HOMEPAGE_BLOCK_VIDEO_PLAYLIST';

  /// 热门播客（封面卡）
  static const String voicelistRcmd = 'HOMEPAGE_VOICELIST_RCMD';

  /// 每天听点儿好音乐（播客节目，一个 creative 里带多条）
  static const String musicPodcastRcmd = 'HOMEPAGE_MUSIC_PODCAST_RCMD_BLOCK';

  /// SVIP 专享有声书：数据在 `dslData`，不在 `creatives`
  static const String voicebookRcmd = 'HOMEPAGE_VOICEBOOK_RCMD';

  final String blockCode;
  final String showType;

  /// `uiElement.mainTitle.title`，常为空
  final String title;

  /// `uiElement.subTitle.title`，「推荐歌单」「新歌新碟」其实在这里
  final String subtitle;

  /// 区块头是否带「更多」跳转（`button.action` 是 `orpheus://`），
  /// 决定标题后面画不画箭头。「播放全部」之类的按钮不算。
  final bool hasMore;

  final List<HomeCreative> creatives;

  /// 有声书区块的条目（来自 `dslData`）
  final List<HomeBook> books;

  /// 区块头文字：主标题优先，没有就用副标题
  String get displayTitle => title.isNotEmpty ? title : subtitle;

  bool get hasHeader => displayTitle.isNotEmpty;

  /// 没有任何可渲染内容
  bool get isEmpty => creatives.isEmpty && books.isEmpty;
}

/// 区块里的一个卡片。
class HomeCreative {
  const HomeCreative({
    required this.creativeType,
    required this.action,
    required this.title,
    required this.imageUrl,
    required this.labelTexts,
    required this.resources,
  });

  /// `list` / `SONG_LIST_HOMEPAGE` / `NEW_SONG_HOMEPAGE` / `voiceList` …
  final String creativeType;

  /// 跳转协议，如 `orpheus://playlist/<id>`
  final String action;

  /// creative 自己的标题（`uiElement.mainTitle.title`）。
  /// 热门播客的 `resources` 是空的，名字只在这里；「新歌」卡的小标题也在这里。
  final String title;

  final String imageUrl;
  final List<String> labelTexts;
  final List<HomeResource> resources;

  /// 卡片主资源（歌单卡只有 1 个，歌曲卡有 3 个）
  HomeResource? get primary => resources.isEmpty ? null : resources.first;
}

/// 卡片里的资源：歌单、歌曲、播客节目等。
class HomeResource {
  const HomeResource({
    required this.resourceType,
    required this.resourceId,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.labelTexts,
    this.artists = const <String>[],
    this.isVip = false,
    this.playCount = 0,
  });

  /// `list` / `song` / `voice` …
  final String resourceType;
  final String resourceId;

  /// 歌单名或歌名
  final String name;

  /// `uiElement.mainTitle.title`
  final String title;

  /// `uiElement.subTitle.title`。
  /// 歌曲里这是「超51%人收藏」「十万红心」这类**标签**，不是歌手（歌手见 [artists]）；
  /// 播客节目里是节目所属播客名。
  final String subtitle;

  final String imageUrl;
  final List<String> labelTexts;

  /// 歌手，来自 `resourceExtInfo.artists`
  final List<String> artists;

  /// 需要 VIP（`songPrivilege.fee == 1`）
  final bool isVip;

  /// 歌单播放量，来自 `resourceExtInfo.playCount`
  final int playCount;

  bool get isSong => resourceType == 'song';

  String get displayName => name.isNotEmpty ? name : title;

  String get artistLine => artists.join('/');
}

/// 有声书条目（`HOMEPAGE_VOICEBOOK_RCMD` 的 `dslData`）。
///
/// 一个条目在官方界面占三行：标题 / 灰色简介 [desc] / 分类标签 + 播放量，右侧评分。
class HomeBook {
  const HomeBook({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.category,
    required this.desc,
    required this.playCount,
    required this.score,
  });

  final String id;
  final String title;
  final String coverUrl;

  /// 分类，如「学习教育」
  final String category;

  /// 简介，如「让孩子足不出户领略中国壮美山河」；接口字段是 `desc`，一般都有
  final String desc;

  /// 已经格式化好的播放量，如「49.2万」
  final String playCount;

  /// 评分，如「9.2」；部分条目没有评分，是空串
  final String score;
}
