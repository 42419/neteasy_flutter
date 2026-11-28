import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';

/// 「关注」页顶栏：菜单 / 标题 / 搜索 / 红色加号。
///
/// 中间标题必须落在屏幕正中。左边 1 个按钮、右边 2 个（加号比图标宽），
/// 用 Expanded 居中会被带偏，所以整条用 Stack，三段各自对齐。
class FollowTopBar extends StatelessWidget {
  const FollowTopBar({super.key, this.onMenu, this.onSearch, this.onCompose});

  /// 工具栏高度（不含状态栏），与「我的」页顶栏一致
  static const double height = 56;

  final VoidCallback? onMenu;
  final VoidCallback? onSearch;

  /// 红色加号：发布动态
  final VoidCallback? onCompose;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                // 侧栏还没做，和首页 / 我的页一样先只占位
                onPressed: onMenu ?? () {},
                icon: const Icon(Icons.menu, size: 24),
                color: colors.textPrimary,
                tooltip: '菜单',
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              '关注',
              style: TextStyle(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: onSearch ?? () {},
                  icon: SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: '搜索',
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ComposeButton(onTap: onCompose),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 红底白加号。官方是 32dp 的实心圆，比图标按钮更靠右、更醒目
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '发布动态',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppTheme.brand,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            AppConstants.feedPlusIcon,
            width: 18,
            height: 18,
          ),
        ),
      ),
    );
  }
}
