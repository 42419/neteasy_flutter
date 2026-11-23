import 'package:material_ui/material_ui.dart';

import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';

/// 播放全部 / 换一批 / 多选。
///
/// 这一行压在暖橙渐变的下缘，所以「播放全部」用主文字色（深色下是白），
/// 「换一批」的描边和文字跟着渐变走浅深两套。
class DailyActionBar extends StatelessWidget {
  const DailyActionBar({
    super.key,
    required this.refreshing,
    required this.onPlayAll,
    required this.onRefresh,
  });

  /// 「换一批」进行中：按钮里换成转圈，且不可再点
  final bool refreshing;

  /// 列表还没有内容时传 null：骨架期间「播放全部」不该能点
  final VoidCallback? onPlayAll;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 8, 12, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPlayAll,
              child: Row(
                children: <Widget>[
                  const _BrandPlayButton(),
                  const SizedBox(width: 10),
                  Text(
                    '播放全部',
                    style: TextStyle(fontSize: 17, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: refreshing ? null : onRefresh,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: daily.actionBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: refreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Text(
                        '换一批',
                        style: TextStyle(fontSize: 12, color: daily.actionText),
                      ),
              ),
            ),
            const SizedBox(width: 5),
            // 多选还没实现，先只放图标占位
            Image.asset(
              AppConstants.multiselectIcon,
              width: 25,
              height: 25,
              color: colors.iconPlay,
              colorBlendMode: BlendMode.srcIn,
            ),
          ],
        ),
      ),
    );
  }
}

/// 实心红圆 + 白色三角
class _BrandPlayButton extends StatelessWidget {
  const _BrandPlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppTheme.brand,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: 18,
        color: AppTheme.colorsOf(context).onMedia,
      ),
    );
  }
}
