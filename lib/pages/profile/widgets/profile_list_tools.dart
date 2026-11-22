import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../../../viewmodels/profile_summary.dart';

/// 「近期  创建²  收藏²」+ 右侧排序按钮。
///
/// 只有选中的那个用主文字色，其余压成次要色；点一下切换下面的列表。
/// 计数为 0 时不画上标——官方对空歌单也是不标。
class ProfileListTools extends StatelessWidget {
  const ProfileListTools({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelect,
  });

  final ProfileSummary data;

  /// 0 近期 / 1 创建 / 2 收藏
  final int selected;

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        18,
        AppTheme.pagePadding,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              'assets/icons/profile/recent_tab.svg',
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                colors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 2),
          _ListTab(
            label: '近期',
            count: 0,
            selected: selected == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(width: 22),
          _ListTab(
            label: '创建',
            count: data.createdPlaylists,
            selected: selected == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 22),
          _ListTab(
            label: '收藏',
            count: data.collectedPlaylists,
            selected: selected == 2,
            onTap: () => onSelect(2),
          ),
          const Spacer(),
          Icon(Icons.tune_rounded, size: 18, color: colors.textSecondary),
        ],
      ),
    );
  }
}

/// 一个可点的小标签：名字 + 右上角计数（上标感靠 9sp 小字 + 顶部对齐）
///
/// [count] 为 null 表示这项统计没取到，只画名字。
class _ListTab extends StatelessWidget {
  const _ListTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final int? total = count;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 1.2,
              color: selected ? colors.textPrimary : colors.textSecondary,
            ),
          ),
          if (total != null && total > 0)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.2,
                  color: colors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
