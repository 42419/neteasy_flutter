import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 三个标签：音乐 / 播客 / 笔记。
///
/// 吸顶后用**整块底色**盖住下面的列表，所以这里必须是不透明背景，
/// 不能只放文字——否则列表会从字缝里透上来。
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  /// 0 音乐 / 1 播客 / 2 笔记
  final int selected;

  final ValueChanged<int> onSelect;

  /// 吸顶高度与 [ProfilePinnedHeader.height] 保持一致
  static const double height = 52;

  static const List<String> labels = <String>['音乐', '播客', '笔记'];

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: colors.background,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          color: i == selected
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 35,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: i == selected
                              ? colors.textPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 固定高度的吸顶 header：滚过去之后一直贴在上面的工具栏下面。
///
/// 只有「我的」页这一处用，所以没放进 components；真出现第二个页面再挪。
class ProfilePinnedHeader extends SliverPersistentHeaderDelegate {
  ProfilePinnedHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant ProfilePinnedHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
