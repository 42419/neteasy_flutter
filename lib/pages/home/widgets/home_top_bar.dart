import 'package:material_ui/material_ui.dart';

import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';

/// 首页顶部栏：左侧菜单、中间 6 个二级 tab、右侧搜索。
/// 目前只有选中态，切 tab 还没有内容。
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.tabBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, size: 24),
            color: AppTheme.textPrimary,
            tooltip: '菜单',
          ),
          Expanded(
            child: SizedBox.expand(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < AppConstants.homeTabs.length; i++)
                    Expanded(
                      child: _TabItem(
                        label: AppConstants.homeTabs[i],
                        selected: i == AppConstants.homeDefaultTab,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 24),
            color: AppTheme.textPrimary,
            tooltip: '搜索',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? AppTheme.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
