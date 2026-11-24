import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 默认推荐 / 风格推荐 的胶囊切换。
///
/// 几何按真机量（406dp 宽截图 1px=1dp）：整条 200×38、圆角 19；
/// 滑块**不是撑满**的，四面各留 3dp，所以是 194 里的半区 97×32、圆角 16。
/// 底色是压在渐变上的一层薄黑（约 14%），不是白色——白色会让整条比头部亮，
/// 官方看着是比周围略暗一档；滑块本身是 78% 白。
///
/// 「风格推荐」还没做，点了不切——官方这里切的是另一套列表，
/// 数据和样式都没对齐之前不动，避免点出一个空页。
class DailySegment extends StatelessWidget {
  const DailySegment({super.key});

  /// 整条尺寸
  static const double width = 200;
  static const double height = 38;

  /// 滑块离整条边缘的留白（四面相同）
  static const double _inset = 3;

  /// 半区宽度 =（整条 - 左右留白）/ 2
  static const double _halfWidth = (width - _inset * 2) / 2;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: daily.segmentTrack,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: _halfWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: daily.segmentThumb,
              borderRadius: BorderRadius.circular((height - _inset * 2) / 2),
            ),
            child: Text(
              '默认推荐',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: daily.segmentSelectedText,
              ),
            ),
          ),
          SizedBox(
            width: _halfWidth,
            child: Center(
              child: Text(
                '风格推荐',
                style: TextStyle(fontSize: 15, color: colors.onMedia),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
