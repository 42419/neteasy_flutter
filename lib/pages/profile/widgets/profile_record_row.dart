import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/profile_summary.dart';
import '../../../viewmodels/user_profile.dart';

/// 「听歌排行」入口：周榜第一的封面 + 柱状图标志 + 标题 + 累计听歌数，右侧「置顶」。
///
/// 封面是最近一周播放最多那首歌的封面；没有就用主页背景图，再没有用头像。
/// 锁挂在「累计听歌 N 首」前面，不在标题旁。
class ProfileRecordRow extends StatelessWidget {
  const ProfileRecordRow({super.key, required this.user, required this.data});

  final UserProfile user;
  final ProfileSummary data;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);

    String cover = data.topSongCover;
    if (cover.isEmpty) {
      cover = user.backgroundUrl.isNotEmpty
          ? user.backgroundUrl
          : user.avatarUrl;
    }

    return SizedBox(
      height: AppTheme.listRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusThumb),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (cover.isNotEmpty)
                    CoverImage(url: cover, logicalWidth: 48),
                  // 柱状图标志压在封面正中间
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/profile/rank.svg',
                      width: 19,
                      height: 19,
                      colorFilter: ColorFilter.mode(
                        colors.onMedia,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('听歌排行', style: AppTheme.listTitle(colors)),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      if (user.recordPrivate) ...<Widget>[
                        SvgPicture.asset(
                          'assets/icons/profile/lock.svg',
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(
                            colors.textTertiary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '累计听歌${user.listenSongs}首',
                        style: AppTheme.listSubtitle(colors),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/icons/profile/pin.svg',
                  width: 13,
                  height: 13,
                  colorFilter: ColorFilter.mode(
                    colors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 3),
                Text('置顶', style: AppTheme.caption(colors)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
