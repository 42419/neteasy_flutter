import 'package:material_ui/material_ui.dart';

/// 应用主题与设计令牌。
///
/// 数值来自真机截图采样（1220×2712 @3x，即 406×904 dp），不是 Material 默认值——
/// 目标是复刻网易云，所以这里不套 M3 的圆角/排版刻度。
class AppTheme {
  AppTheme._();

  // ---------- 颜色 ----------

  /// 页面背景（截图整图众数，占比 47.2%）
  static const Color background = Color(0xFFF4F7FA);

  /// 深色模式的页面背景。
  ///
  /// 原生启动屏的 `splash_background`（values-night）必须与它一致，
  /// 否则冷启动会看到「黑 → 灰」一跳。
  static const Color backgroundDark = Color(0xFF121212);

  /// 网易云品牌红：tab 选中、红心、强调
  static const Color brand = Color(0xFFEC4141);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF878787);
  static const Color textTertiary = Color(0xFFA4A6A7);

  static const Color cardSurface = Color(0xFFFFFFFF);

  /// 图片未加载完的底色
  static const Color placeholder = Color(0xFFE6E9EE);

  /// 细描边：按钮边框、分割线
  static const Color divider = Color(0xFFE3E5E8);

  /// 分类/标签 chip：官方是透明底 + 细描边（截图采样 #B6C3DD / #5975B2）
  static const Color chipBorder = Color(0xFFB6C3DD);
  static const Color chipText = Color(0xFF5975B2);

  /// 播客标签的浅蓝填充底色（无描边）
  static const Color chipFill = Color(0xFFE5EAF2);

  /// 列表条目的灰色简介行
  static const Color textDescription = Color(0xFF6B6C7A);

  /// 行尾的实心播放三角
  static const Color iconPlay = Color(0xFF4A4A55);

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
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    height: 1.3,
    color: textPrimary,
  );

  /// 卡片标题（歌单名），最多两行
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: textPrimary,
  );

  /// 辅助信息：副标题、播放量、占位提示
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: textSecondary,
  );

  // ---------- ThemeData ----------

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: brightness,
      ),
      // 之前深色也返回浅色背景：只有 ColorScheme 变了，页面底色还是 #F4F7FA
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? backgroundDark
          : background,
    );
  }
}
