import 'package:material_ui/material_ui.dart';

/// 从网易云 App 截图采样得到的设计 token（1220×2712 @3x，即 406×904 dp）。
///
/// 采样方法：`PIL` 统计整图众数颜色 / 逐行扫描文字带，见 `refs/screenshots/`。
class Tokens {
  const Tokens._();

  /// 页面背景（全图占比 47.2%）
  static const Color background = Color(0xFFF4F7FA);

  /// 网易云品牌红（tab 选中、红心、强调）
  static const Color brand = Color(0xFFEC4141);

  /// 主文字 / 次文字 / 三级文字
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF878787);
  static const Color textTertiary = Color(0xFFA4A6A7);

  /// 卡片与区块
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0x14000000);

  /// 圆角：卡片 8dp，小标签 4dp，胶囊 999
  static const double radiusCard = 8;
  static const double radiusChip = 4;

  /// 页面左右边距（与截图 16dp 对齐）
  static const double gutter = 16;

  /// 板块之间的竖向间距
  static const double sectionGap = 24;

  /// 顶部 tab 栏高度（不含状态栏）
  static const double tabBarHeight = 48;

  /// 悬浮迷你播放器高度（距底导航 8dp）
  static const double miniPlayerHeight = 56;

  /// 底部导航高度
  static const double bottomNavHeight = 56;

  /// 标题：板块标题 17sp 半粗；卡片标题 12sp；辅助 11sp
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: textSecondary,
  );
}
