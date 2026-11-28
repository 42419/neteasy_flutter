import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 「我的关注」那一行：左边标题，右边三个筛选项。
///
/// 三个项之间有一条 1dp 的竖线；选中项加粗、用正文色，其余是次要色。
class FollowTabs extends StatelessWidget {
  const FollowTabs({super.key, required this.selected, required this.onSelect});

  /// 0 全部 / 1 音乐人 / 2 朋友
  final int selected;

  final ValueChanged<int> onSelect;

  static const List<String> labels = <String>['全部', '音乐人', '朋友'];

  static const double height = 46;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Row(
          children: <Widget>[
            Text(
              '我的关注',
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            for (int i = 0; i < labels.length; i++) ...<Widget>[
              if (i > 0)
                Container(
                  width: 0.5,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: colors.divider,
                ),
              GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      // 选中用 w500：比正文粗一点就够，w600 在 13sp 下发闷
                      fontWeight: i == selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: i == selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
