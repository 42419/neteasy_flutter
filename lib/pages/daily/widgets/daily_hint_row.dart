import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 「根据你的音乐口味生成，每日 6:00 更新」提示行。
class DailyHintRow extends StatelessWidget {
  const DailyHintRow({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 8, 12, 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            '根据你的音乐口味生成，每日6:00更新',
            style: AppTheme.caption(colors).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
