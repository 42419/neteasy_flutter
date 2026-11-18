import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'home/home_view.dart';

/// 主页面壳：底部三个 tab + 内容区。
///
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeView(),
          _PlaceholderPage(label: '云村'),
          _PlaceholderPage(label: '我的'),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: AppTheme.cardSurface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppTheme.bottomNavHeight,
          child: Row(
            children: <Widget>[
              _buildNavItem(
                index: 0,
                icon: Icons.music_note_outlined,
                selectedIcon: Icons.music_note,
                label: '发现',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum,
                label: '云村',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool selected = _index == index;
    final Color color = selected ? AppTheme.textPrimary : AppTheme.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(selected ? selectedIcon : icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
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
    return SafeArea(
      child: Center(child: Text('$label 页待实现', style: AppTheme.caption)),
    );
  }
}
