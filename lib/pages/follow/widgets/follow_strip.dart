import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/feed_event.dart';

/// 「关注」页顶部的头像条：好友/歌手 + 全部好友。
///
/// 尺寸取真机截图：圆 52、每格 71（圆心间隔 213px ÷ 3）、左边距 16。
/// 人数超过屏幕就横向滚动，官方也是这么处理的。
///
/// 官方首位还有「乐迷团」入口，团徽是图片资源、代号未定，暂不渲染，
/// 拿到图标后在这里补一格即可。
class FollowStrip extends StatelessWidget {
  const FollowStrip({
    super.key,
    required this.contacts,
    this.onContact,
    this.onAllFriends,
  });

  /// 已经筛过的候选（好友 + 关注的歌手）
  final List<FollowContact> contacts;

  final ValueChanged<FollowContact>? onContact;
  final VoidCallback? onAllFriends;

  /// 圆 52 + 间距 10 + 文字 15 + 上下留白
  static const double height = 96;

  /// 一格的宽度：比圆宽，左右各留出一点间隙
  static const double _slotWidth = 71;

  /// 圆直径
  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        children: <Widget>[
          for (final FollowContact contact in contacts)
            _StripSlot(
              label: contact.user.displayName,
              onTap: () => onContact?.call(contact),
              child: _Avatar(url: contact.user.avatarUrl, size: _avatarSize),
            ),
          _StripSlot(
            label: '全部好友',
            onTap: onAllFriends,
            child: const _AllFriendsAvatar(),
          ),
        ],
      ),
    );
  }
}

class _StripSlot extends StatelessWidget {
  const _StripSlot({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      width: FollowStrip._slotWidth,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            child,
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 圆形头像：图没到、地址为空时露出主题占位色
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? ColoredBox(color: colors.placeholder)
            : CoverImage(url: url, logicalWidth: size),
      ),
    );
  }
}

/// 「全部好友」：白底 + 细描边 + 三个点。
///
/// 三个点直接复用列表行尾的 `more.png`（竖排 ⋮）旋转 90° 得到，
/// 不另画一套圆点。
class _AllFriendsAvatar extends StatelessWidget {
  const _AllFriendsAvatar();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Container(
      width: FollowStrip._avatarSize,
      height: FollowStrip._avatarSize,
      decoration: BoxDecoration(
        color: colors.card,
        shape: BoxShape.circle,
        border: Border.all(color: colors.divider),
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 1,
        child: Image.asset(
          AppConstants.moreIcon,
          width: 18,
          height: 18,
          color: colors.textTertiary,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
  }
}
