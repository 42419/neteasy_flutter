import 'package:material_ui/material_ui.dart';

/// 语义色。浅色 / 深色两套，页面统一从这里取，不要直接写死颜色。
///
/// 深色：背景 `#151515`、卡片 `#1D1D20`，文字按 100 / 60 / 40% 白分层，描边 10% 白。
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

  /// 当前主题的语义色。页面在 build 里取一次，往下传
  static AppColors colorsOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  // ---------- 间距 ----------

  /// 区块之间的竖向间距
  static const double gap = 16;

  /// 页面左右边距（与官方 16dp 对齐）
  static const double pagePadding = 16;

  // ---------- 圆角 ----------

  /// 封面/大卡
  static const double radiusCard = 8;

  /// 播放量角标等小标签
  static const double radiusChip = 4;

  // ---------- 尺寸 ----------

  /// 顶部 tab 栏（不含状态栏）
  static const double tabBarHeight = 48;

  /// 底部导航
  static const double bottomNavHeight = 56;

  /// 悬浮迷你播放器
  static const double miniPlayerHeight = 56;

  // ---------- 文字 ----------

  /// 板块标题：「推荐歌单」「排行榜」
  static TextStyle sectionTitle(AppColors colors) =>
      TextStyle(fontSize: 17, height: 1.3, color: colors.textPrimary);

  /// 卡片标题（歌单名），最多两行
  static TextStyle cardTitle(AppColors colors) =>
      TextStyle(fontSize: 14, height: 1.35, color: colors.textPrimary);

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
