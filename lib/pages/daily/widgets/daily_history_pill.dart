import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';

/// 历史日推：半透明白胶囊 + VIP 徽章。
///
/// 历史日推要会员才能翻，所以徽章直接挂在文字后面；点了目前只留空回调。
class DailyHistoryPill extends StatelessWidget {
  const DailyHistoryPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: daily.historyTrack,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('历史日推', style: TextStyle(fontSize: 12, color: colors.onMedia)),
            const SizedBox(width: 5),
            SvgPicture.asset(AppConstants.vipBadge, height: 12),
          ],
        ),
      ),
    );
  }
}
