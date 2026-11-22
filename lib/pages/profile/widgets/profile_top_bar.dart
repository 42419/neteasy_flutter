import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/user_profile.dart';

/// 「我的」页顶部工具栏：菜单 / 添加状态（或小头像 + 昵称）/ 新建 / 搜索 / 更多。
///
/// 中间那段必须落在屏幕正中。用 Expanded 居中会被左右按钮的宽度差带偏
/// （左边 1 个、右边 3 个），所以整条用 Stack，三段各自对齐。
///
/// [collapsed] 为 true 时（头像区已经滚上去）中间换成小头像 + 昵称。
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key, required this.user, required this.collapsed});

  final UserProfile user;

  /// 头像区已滚出视口：中间换成小头像 + 昵称
  final bool collapsed;

  /// 工具栏高度（不含状态栏）
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(width: 4),
                IconButton(
                  // 侧栏还没做，先只占位
                  onPressed: () {},
                  icon: const Icon(Icons.menu_rounded, size: 25),
                  color: colors.textPrimary,
                  tooltip: '菜单',
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: collapsed
                  ? Row(
                      key: const ValueKey<String>('collapsed'),
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ClipOval(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: user.avatarUrl.isEmpty
                                ? ColoredBox(color: colors.placeholder)
                                : CoverImage(
                                    url: user.avatarUrl,
                                    logicalWidth: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  : TextButton(
                      key: const ValueKey<String>('expanded'),
                      onPressed: () {},
                      child: Text(
                        '+ 添加状态',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 26),
                  color: colors.textPrimary,
                  tooltip: '新建',
                ),
                IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: '搜索',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, size: 24),
                  color: colors.textPrimary,
                  tooltip: '更多',
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
