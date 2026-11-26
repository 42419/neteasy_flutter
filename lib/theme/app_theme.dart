import 'package:material_ui/material_ui.dart';

/// 语义色。浅色 / 深色两套，页面统一从这里取，不要直接写死颜色。
///
/// 深色：背景 `#151515`、卡片 `#1D1D20`，文字按 100 / 60 / 40% 白分层，描边 10% 白。
///
/// 命名口径：
/// - `textXxx` 管文字，`divider` 管描边，`placeholder` 管图没到时的底色
/// - `onMedia` 系列是**压在封面/渐变卡上的前景色**，不随深浅色变（底色本来就是图或渐变色）
/// - `xxxScrim` 是压暗/提亮的半透明层，值写死在这里，页面不要再自己 `withValues`
@immutable
class AppColors {
  const AppColors({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDescription,
    required this.divider,
    required this.placeholder,
    required this.chipBorder,
    required this.chipText,
    required this.chipFill,
    required this.iconPlay,
    required this.progressTrack,
    required this.scrim,
    required this.onMedia,
    required this.onMediaSecondary,
    required this.mediaScrim,
    required this.countBadgeScrim,
    required this.strongScrim,
    required this.skeletonShine,
    required this.floatingShadow,
  });

  /// 页面背景
  final Color background;

  /// 卡片 / 底部栏 / 迷你播放器的底色
  final Color card;

  /// 主文字：标题、歌名
  final Color textPrimary;

  /// 次要文字：副标题、播放量
  final Color textSecondary;

  /// 更弱的提示文字
  final Color textTertiary;

  /// 列表条目的灰色简介行
  final Color textDescription;

  /// 细描边：按钮边框、分割线
  final Color divider;

  /// 图片未加载完的底色
  final Color placeholder;

  /// 分类/标签 chip 的描边与文字
  final Color chipBorder;
  final Color chipText;

  /// 播客标签的浅蓝填充底色（无描边）
  final Color chipFill;

  /// 行尾的实心播放三角
  final Color iconPlay;

  /// 进度环的底槽（迷你播放器的播放键外圈）
  final Color progressTrack;

  /// 底部渐隐遮罩的实色端（迷你播放器下方铺到屏幕底边的那块）
  final Color scrim;

  /// 压在封面/渐变卡上的主文字与图标：纯白
  final Color onMedia;

  /// 媒体卡上的次要文字：75% 白（入口卡副标题、日期后的月份）
  final Color onMediaSecondary;

  /// 媒体卡底部压暗层：黑 45%，保证白字可读
  final Color mediaScrim;

  /// 播放量角标的底：黑 25%
  final Color countBadgeScrim;

  /// 强压暗层：黑 55%（二维码过期遮罩）
  final Color strongScrim;

  /// 骨架屏扫光的高光条：白 45%
  final Color skeletonShine;

  /// 浮起元素的投影（迷你播放器胶囊）。深色下投影只会糊成一团，压得很淡
  final Color floatingShadow;

  /// 浅色：真机截图采样值
  static const AppColors light = AppColors(
    background: Color(0xFFF4F7FA),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF878787),
    textTertiary: Color(0xFFA4A6A7),
    textDescription: Color(0xFF6B6C7A),
    divider: Color(0xFFE3E5E8),
    placeholder: Color(0xFFE6E9EE),
    chipBorder: Color(0xFFB6C3DD),
    chipText: Color(0xFF5975B2),
    chipFill: Color(0xFFE5EAF2),
    iconPlay: Color(0xFF4A4A55),
    progressTrack: Color(0xFFC4C4C9),
    scrim: Color(0xFFF4F7FA),
    onMedia: Color(0xFFFFFFFF),
    onMediaSecondary: Color(0xBFFFFFFF),
    mediaScrim: Color(0x73000000),
    countBadgeScrim: Color(0x40000000),
    strongScrim: Color(0x8C000000),
    skeletonShine: Color(0x73FFFFFF),
    floatingShadow: Color(0x0F000000),
  );

  /// 深色：官方深色资源里背景 #151515、卡片 #1D1D20，
  /// 主文字纯白，次要 60% 白（#99FFFFFF 叠在 #151515 上约等于 #A1A1A1），
  /// 描边 10% 白（#1AFFFFFF 约等于 #2C2C2C）
  static const AppColors dark = AppColors(
    background: Color(0xFF151515),
    card: Color(0xFF1D1D20),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1A1),
    textTertiary: Color(0xFF6E6E6E),
    textDescription: Color(0xFF8C8C8C),
    divider: Color(0xFF2C2C2C),
    placeholder: Color(0xFF262629),
    chipBorder: Color(0xFF3A4356),
    chipText: Color(0xFF8FA3C8),
    chipFill: Color(0xFF232833),
    iconPlay: Color(0xFFC4C4C8),
    progressTrack: Color(0xFF606062),
    scrim: Color(0xFF0D0D12),
    onMedia: Color(0xFFFFFFFF),
    onMediaSecondary: Color(0xBFFFFFFF),
    mediaScrim: Color(0x73000000),
    countBadgeScrim: Color(0x40000000),
    strongScrim: Color(0x8C000000),
    skeletonShine: Color(0x73FFFFFF),
    floatingShadow: Color(0x47000000),
  );
}

/// 每日推荐页的暖橙体系。
///
/// 这一页整片压在渐变上：白字、半透明白胶囊、深棕选中态都是它独有的，
/// 塞进 [AppColors] 会让别的页面多出用不到的字段，所以单独成类。
@immutable
class DailyColors {
  const DailyColors({
    required this.pageBackground,
    required this.headerGradient,
    required this.headerGradientStops,
    required this.segmentTrack,
    required this.segmentThumb,
    required this.segmentSelectedText,
    required this.historyTrack,
    required this.actionBorder,
    required this.actionText,
    required this.reasonChipColor,
    required this.reasonChipBackground,
    required this.dateSuffix,
    required this.fortuneText,
  });

  /// 这一页的底色。官方每日推荐是纯白（浅色），和首页的 `#F4F7FA` 不一样：
  /// 渐变最后一段要落到它上面才不会有硬边，播放栏底下也靠它盖住橙色。
  final Color pageBackground;

  /// 顶部渐变，从上到下 6 段；最后一段必须等于页面背景，否则会切出一条边
  final List<Color> headerGradient;

  /// 渐变的落点。暖色区延长到「播放全部」那一行，渐变才不会在按钮上方断掉
  final List<double> headerGradientStops;

  /// 顶栏胶囊底（默认推荐 / 风格推荐）：压在渐变上的一层薄黑，
  /// 比头部略暗一档（真机量得约 14% 黑），不是白色
  final Color segmentTrack;

  /// 选中半区的滑块：78% 白，透出一点底色，不是纯白
  final Color segmentThumb;

  /// 选中半区的文字（深棕，压在浅色滑块上）
  final Color segmentSelectedText;

  /// 历史日推胶囊的底：和分段控件一样是压在渐变上的一层薄黑（真机约 8%），
  /// 比头部暗一点点；写成白色会让它比周围亮，一眼就不对
  final Color historyTrack;

  /// 「换一批」的描边
  final Color actionBorder;

  /// 「换一批」的文字
  final Color actionText;

  /// 推荐语标签的字色（比品牌红更偏玫）
  final Color reasonChipColor;

  /// 推荐语标签的底（浅色粉底；深色用暗红，粉底在黑夜模式里太刺眼）
  final Color reasonChipBackground;

  /// 日期后面的「/月份」：80% 白
  final Color dateSuffix;

  /// 「查看今日运势」与它的箭头：92% 白
  final Color fortuneText;

  static const DailyColors light = DailyColors(
    pageBackground: Color(0xFFFFFFFF),
    headerGradient: <Color>[
      Color(0xFFFFB687),
      Color(0xFFFFAB84),
      Color(0xFFFDAB8E),
      Color(0xFFF6C2AF),
      Color(0xFFF9EAE5),
      Color(0xFFFFFFFF),
    ],
    headerGradientStops: <double>[0, 0.40, 0.65, 0.80, 0.92, 1],
    segmentTrack: Color(0x24000000),
    segmentThumb: Color(0xC7FFFFFF),
    segmentSelectedText: Color(0xFF3D2A22),
    historyTrack: Color(0x14000000),
    actionBorder: Color(0x24333333),
    actionText: Color(0xFF333333),
    reasonChipColor: Color(0xFFFF3A3A),
    reasonChipBackground: Color(0xFFFFE9E9),
    dateSuffix: Color(0xCCFFFFFF),
    fortuneText: Color(0xEBFFFFFF),
  );

  static const DailyColors dark = DailyColors(
    pageBackground: Color(0xFF151515),
    headerGradient: <Color>[
      Color(0xFFF0A176),
      Color(0xFFD9825B),
      Color(0xFF8A5647),
      Color(0xFF4A3230),
      Color(0xFF221A18),
      Color(0xFF151515),
    ],
    headerGradientStops: <double>[0, 0.40, 0.65, 0.80, 0.92, 1],
    segmentTrack: Color(0x24000000),
    segmentThumb: Color(0xCCE8DDD6),
    segmentSelectedText: Color(0xFF3D2A22),
    historyTrack: Color(0x14FFFFFF),
    actionBorder: Color(0x47FFFFFF),
    actionText: Color(0xE6FFFFFF),
    reasonChipColor: Color(0xFFFF3A3A),
    reasonChipBackground: Color(0xFF3A2222),
    dateSuffix: Color(0xCCFFFFFF),
    fortuneText: Color(0xEBFFFFFF),
  );
}

/// 「我的」页的专属颜色。
///
/// 官方这一页的头部**不随主题变**：头像放大模糊后压一层黑色遮罩，上面的字、图标、
/// 快捷入口一律是白的，深浅色下长得一样。所以这里的「头部前景色」是固定的白，
/// 不是 `AppColors.textPrimary`——后者在浅色下是黑的，压在深色头部上会看不见。
@immutable
class ProfileColors {
  const ProfileColors({
    required this.svipName,
    required this.genderMale,
    required this.genderFemale,
    required this.onHeader,
    required this.onHeaderSecondary,
    required this.onHeaderMuted,
    required this.quickChip,
    required this.quickChipContent,
    required this.avatarRing,
    required this.avatarGlow,
    required this.headerFallback,
    required this.blurScrimTop,
    required this.blurScrimBottom,
  });

  /// SVIP 昵称的金色（普通用户和 VIP 用 [onHeader]）
  final Color svipName;

  /// 性别图标
  final Color genderMale;
  final Color genderFemale;

  /// 头部上的前景色：数字、昵称、顶栏图标用 100% 白；
  /// 统计标签、徽章数用 80%；「+ 添加状态」这类弱提示用 62%（截图取色折算）
  final Color onHeader;
  final Color onHeaderSecondary;
  final Color onHeaderMuted;

  /// 快捷入口的底：9% 白，浮在深色头部上（截图量得 #74645c → #80746c）
  final Color quickChip;

  /// 快捷入口里的图标和字，92% 白
  final Color quickChipContent;

  /// 头像描边与外圈淡光
  final Color avatarRing;
  final Color avatarGlow;

  /// 没有头像时头部的底色：取官方这张头像模糊后的平均色，保证白字有对比度
  final Color headerFallback;

  /// 头部黑色遮罩的两端：上半段保持 [blurScrimTop]，往下渐隐到 [blurScrimBottom]。
  /// 官方实测上端约 25% 黑、下端为 0；下端留一点点（6%），
  /// 免得浅色头像模糊出来的底太亮、白字糊掉。深色下页面底更黑，遮罩加重到 32% / 12%。
  final Color blurScrimTop;
  final Color blurScrimBottom;

  static const ProfileColors light = ProfileColors(
    svipName: Color(0xFFFEE7B9),
    genderMale: Color(0xFF5AA8FF),
    genderFemale: Color(0xFFFF6B9A),
    onHeader: Color(0xFFFFFFFF),
    onHeaderSecondary: Color(0xCCFFFFFF),
    onHeaderMuted: Color(0x9EFFFFFF),
    quickChip: Color(0x17FFFFFF),
    quickChipContent: Color(0xEBFFFFFF),
    avatarRing: Color(0xFFFFFFFF),
    avatarGlow: Color(0x24FFFFFF),
    headerFallback: Color(0xFF7B6B65),
    blurScrimTop: Color(0x40000000),
    blurScrimBottom: Color(0x0F000000),
  );

  /// 深色下页面底是黑的，头部遮罩略重一点，和下面的面板拉开层次
  static const ProfileColors dark = ProfileColors(
    svipName: Color(0xFFFEE7B9),
    genderMale: Color(0xFF5AA8FF),
    genderFemale: Color(0xFFFF6B9A),
    onHeader: Color(0xFFFFFFFF),
    onHeaderSecondary: Color(0xCCFFFFFF),
    onHeaderMuted: Color(0x9EFFFFFF),
    quickChip: Color(0x17FFFFFF),
    quickChipContent: Color(0xEBFFFFFF),
    avatarRing: Color(0xFFFFFFFF),
    avatarGlow: Color(0x24FFFFFF),
    headerFallback: Color(0xFF5A4F4B),
    blurScrimTop: Color(0x52000000),
    blurScrimBottom: Color(0x1F000000),
  );
}

/// 应用主题与设计令牌。
///
/// 尺寸类数值来自真机截图采样（1220×2712 @3x，即 406×904 dp），不是 Material 默认值——
/// 目标是复刻网易云，所以这里不套 M3 的圆角/排版刻度。
class AppTheme {
  AppTheme._();

  /// 网易云品牌红：tab 选中、红心、强调。深浅色共用
  static const Color brand = Color(0xFFEC4141);

  /// 行内 VIP 标签的红：比品牌红更偏玫，官方「每日推荐」「歌单行」用的都是它
  static const Color vipTag = Color(0xFFFF4B4B);

  /// 透明。给 `SystemUiOverlayStyle`、渐变端点这类 const 场景用：
  /// 页面里不许写 `Colors.transparent` / `Color(0x…)`，统一从这里取。
  static const Color transparent = Color(0x00000000);

  /// 当前主题的语义色。页面在 build 里取一次，往下传
  static AppColors colorsOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  /// 每日推荐页的暖橙体系
  static DailyColors dailyOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? DailyColors.dark
      : DailyColors.light;

  /// 「我的」页的专属色
  static ProfileColors profileOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ProfileColors.dark
      : ProfileColors.light;

  /// 首页 6 张入口卡的渐变（每日推荐 / 榜单推荐 / 心动模式 / 雷达歌单 / 漫游 / 相似歌曲）。
  ///
  /// 登录后官方只下发运营图，图没加载出来时要靠同色系渐变兜底，露白底很扎眼；
  /// 游客态直接就是这套渐变。
  static const List<List<Color>> entryGradients = <List<Color>>[
    <Color>[Color(0xFF4A4A52), Color(0xFF23232A)],
    <Color>[Color(0xFFFF6B6B), Color(0xFFD63B3B)],
    <Color>[Color(0xFF3E5AA8), Color(0xFF23335F)],
    <Color>[Color(0xFF2E1559), Color(0xFF050C20)],
    <Color>[Color(0xFF91A83E), Color(0xFF5F5523)],
    <Color>[Color(0xFF3EA888), Color(0xFF235F31)],
  ];

  /// 排行榜卡的渐变，按顺序循环：官方是绿 / 橙 / 蓝 / 紫几套
  static const List<List<Color>> rankGradients = <List<Color>>[
    <Color>[Color(0xFF7BD3A8), Color(0xFF3BAF7A)],
    <Color>[Color(0xFFFFC46B), Color(0xFFF08C2E)],
    <Color>[Color(0xFF9EC5FF), Color(0xFF5B8DEF)],
    <Color>[Color(0xFFD3A8FF), Color(0xFF9A5BEF)],
  ];

  // ---------- 间距 ----------

  /// 区块之间的竖向间距（设计规范值，具体区块另有自己的内边距）
  static const double gap = 16;

  /// 页面左右边距（与官方 16dp 对齐）
  static const double pagePadding = 16;

  // ---------- 圆角 ----------

  /// 封面/大卡
  static const double radiusCard = 8;

  /// 播放量角标等小标签
  static const double radiusChip = 4;

  /// 列表行里的小封面（歌单行、歌曲行、播客行都是这个）
  static const double radiusThumb = 4;

  // ---------- 尺寸 ----------

  /// 顶部 tab 栏（不含状态栏）
  static const double tabBarHeight = 48;

  /// 底部导航
  static const double bottomNavHeight = 56;

  /// 列表行高：歌单行、听歌排行、新建歌单都是 68
  static const double listRowHeight = 68;

  // 迷你播放器的胶囊高度不在这里定义：它和唱片直径、圆角半径是同一个数，
  // 改一处就得改三处，所以只认 `MiniPlayerBar.height`。

  // ---------- 文字 ----------

  /// 板块标题：「推荐歌单」「排行榜」
  static TextStyle sectionTitle(AppColors colors) =>
      TextStyle(fontSize: 17, height: 1.3, color: colors.textPrimary);

  /// 卡片标题（歌单名），最多两行
  static TextStyle cardTitle(AppColors colors) =>
      TextStyle(fontSize: 14, height: 1.35, color: colors.textPrimary);

  /// 列表行标题：歌单名、听歌排行、新建歌单
  static TextStyle listTitle(AppColors colors) =>
      TextStyle(fontSize: 15, height: 1.3, color: colors.textPrimary);

  /// 列表行副标题：歌单「歌单 · N首 · 创建者」、导入外部歌单的说明
  static TextStyle listSubtitle(AppColors colors) =>
      TextStyle(fontSize: 12, height: 1.3, color: colors.textSecondary);

  /// 辅助信息：副标题、播放量、占位提示
  static TextStyle caption(AppColors colors) =>
      TextStyle(fontSize: 11, height: 1.3, color: colors.textSecondary);

  // ---------- ThemeData ----------

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final AppColors colors = brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.background,
    );
  }
}
