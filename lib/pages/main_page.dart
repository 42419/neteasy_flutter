import 'package:material_ui/material_ui.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'home/home_view.dart';
import 'profile/profile_view.dart';

/// 主页面壳：底部三个图标 tab + 内容区。
///
/// 官方导航栏只有图标、没有文字标签，选中态深色、未选中灰色。
/// 用 IndexedStack 让 tab 切换不重建页面，数据与滚动位置都保留。
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    // 背景交给主题（浅 #F4F7FA / 深 #151515），别再写死浅色
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeView(),
          _PlaceholderPage(label: '关注'),
          ProfileView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(colors),
    );
  }

  Widget _buildBottomNav(AppColors colors) {
    return Container(
      color: colors.card,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppTheme.bottomNavHeight,
          child: Row(
            children: <Widget>[
              _buildNavItem(
                index: 0,
                asset: AppConstants.tabIconHome,
                label: AppConstants.bottomTabLabels[0],
                colors: colors,
              ),
              _buildNavItem(
                index: 1,
                asset: AppConstants.tabIconFollow,
                label: AppConstants.bottomTabLabels[1],
                colors: colors,
              ),
              _buildNavItem(
                index: 2,
                asset: AppConstants.tabIconMine,
                label: AppConstants.bottomTabLabels[2],
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 图标是「黑色 + alpha」的透明位图，
  /// 用 srcIn 直接染色，选中/未选中只改 color。
  Widget _buildNavItem({
    required int index,
    required String asset,
    required String label,
    required AppColors colors,
  }) {
    final bool selected = _index == index;
    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => setState(() => _index = index),
          child: Center(
            child: Image.asset(
              asset,
              width: 24,
              height: 24,
              color: selected ? colors.textPrimary : colors.textTertiary,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// 还没做的 tab 占位。按 yunfei 的约定：缺内容先用居中文字顶住。
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SafeArea(
      child: Center(
        child: Text('$label 页待实现', style: AppTheme.caption(colors)),
      ),
    );
  }
}
