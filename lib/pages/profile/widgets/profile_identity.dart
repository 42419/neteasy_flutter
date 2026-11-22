import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/profile_summary.dart';
import '../../../viewmodels/user_profile.dart';

/// 头像、昵称、会员徽章、性别与徽章数、四项统计。
///
/// 整块压在模糊背景上，所以文字统一用 `textPrimary`（深色下是白），
/// 只有 SVIP 昵称例外——金色在深浅色下都成立。
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.user, required this.data});

  final UserProfile user;
  final ProfileSummary data;

  /// 头像直径（截图量出来 73dp）
  static const double avatarSize = 73;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final ProfileColors profileColors = AppTheme.profileOf(context);
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        _buildAvatar(colors, profileColors),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  // SVIP 昵称是金色，普通用户和 VIP 都是主文字色
                  color: data.svipActive
                      ? profileColors.svipName
                      : colors.textPrimary,
                ),
              ),
            ),
            if (data.vipLabel.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              _VipLevelBadge(data: data),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (user.gender != 0)
              SvgPicture.asset(
                user.isFemale
                    ? 'assets/icons/profile/gender_female.svg'
                    : 'assets/icons/profile/gender_male.svg',
                width: 11,
                height: 11,
                colorFilter: ColorFilter.mode(
                  user.isFemale
                      ? profileColors.genderFemale
                      : profileColors.genderMale,
                  BlendMode.srcIn,
                ),
              ),
            if (user.gender != 0 && data.badgeCount != null)
              Text(' · ', style: AppTheme.caption(colors)),
            // 徽章数拿不到就整段不画，不显示「0枚徽章」
            if (data.badgeCount != null) ...<Widget>[
              Icon(
                Icons.workspace_premium_outlined,
                size: 14,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text('${data.badgeCount}枚徽章', style: AppTheme.caption(colors)),
            ],
          ],
        ),
        const SizedBox(height: 18),
        _StatsRow(user: user, data: data),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvatar(AppColors colors, ProfileColors profileColors) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: profileColors.avatarRing, width: 2),
        boxShadow: <BoxShadow>[
          // 官方头像外面有一圈很淡的白光，别调太亮，否则糊成一坨
          BoxShadow(
            color: profileColors.avatarGlow,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: user.avatarUrl.isEmpty
            ? ColoredBox(
                color: colors.placeholder,
                child: Icon(Icons.person, color: colors.textTertiary),
              )
            : CoverImage(url: user.avatarUrl, logicalWidth: avatarSize),
      ),
    );
  }
}

/// 昵称旁的会员徽章：直接用整套等级图标（52×16，按高度 16 显示）
class _VipLevelBadge extends StatelessWidget {
  const _VipLevelBadge({required this.data});

  final ProfileSummary data;

  @override
  Widget build(BuildContext context) {
    final String kind = data.svipActive ? 'svip' : 'vip';
    // 图标只做到 7 级，更高的等级先按 7 显示
    final int level = data.vipLevel.clamp(1, 7);
    return SvgPicture.asset(
      'assets/icons/vip/level/$kind$level.svg',
      height: 16,
    );
  }
}

/// 关注 / 粉丝 / 等级 / 听歌小时数
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.data});

  final UserProfile user;
  final ProfileSummary data;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);

    Widget item(String value, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
            ),
          ),
          if (label.isNotEmpty) ...<Widget>[
            const SizedBox(width: 3),
            Text(label, style: AppTheme.caption(colors)),
          ],
        ],
      );
    }

    // 等级缺失（0）和听歌时长未知（null）的项直接不画，别摆出 Lv.0 / 0 小时
    final List<Widget> items = <Widget>[
      item('${user.follows}', '关注'),
      item('${user.followeds}', '粉丝'),
      if (user.level > 0) item('Lv.${user.level}', ''),
      if (data.listenHours != null) item('${data.listenHours}', '小时'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 18),
          items[i],
        ],
      ],
    );
  }
}
