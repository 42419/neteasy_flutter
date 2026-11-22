import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 默认推荐 / 风格推荐 的胶囊切换：整条 200×32，选中半区是滑块。
///
/// 「风格推荐」还没做，点了不切——官方这里切的是另一套列表，
/// 数据和样式都没对齐之前不动，避免点出一个空页。
class DailySegment extends StatelessWidget {
  const DailySegment({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    return Container(
      width: 200,
      height: 32,
      decoration: BoxDecoration(
        color: daily.segmentTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: daily.segmentThumb,
              borderRadius: BorderRadius.circular(16),
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
            width: 100,
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
