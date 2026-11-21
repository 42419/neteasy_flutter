import 'package:material_ui/material_ui.dart';

/// VIP 小徽章：白底 + 浅红描边 + 红字。
///
/// 官方每日推荐、歌单行、搜索结果里都是这个样式，别再手写一遍。
/// 尺寸取自真机截图：高 12dp 时整枚 17.7×12，左边框到文字 2.6dp，
/// 文字大写高度 6.7dp（约 9sp）。
///
/// 需要横条状的「VIP / SVIP」大徽章（我的页那种）继续用
/// `AppConstants.vipBadge` 的 SVG，两者不是同一个东西。
class VipBadge extends StatelessWidget {
  const VipBadge({
    super.key,
    this.label = 'VIP',
    this.height = 12,
    this.color = const Color(0xFFFF4B4B),
  });

  final String label;

  /// 徽章高度。字号、内边距、圆角都按它等比算，改一个地方就够
  final double height;

  /// 文字与描边的主色；描边取它的 33% 透明度
  final Color color;

  /// 列表行里的标准高度
  static const double rowHeight = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: 0.33),
          width: height * 0.058,
        ),
        borderRadius: BorderRadius.circular(height * 0.25),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: height * 0.75,
          height: 1,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}
