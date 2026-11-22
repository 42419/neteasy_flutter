import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_thumb.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/playlist.dart';

/// 歌单行：48 封面 + 名称 + 副标题；「我喜欢的音乐」右侧带「心动模式」。
///
/// 其余歌单右侧是 ⋮。点整行还没接歌单详情页，先只有视觉。
class ProfilePlaylistRow extends StatelessWidget {
  const ProfilePlaylistRow({
    super.key,
    required this.playlist,
    required this.onHeartMode,
  });

  final Playlist playlist;

  /// 「心动模式」胶囊的回调（该功能未实现，页面只弹提示）
  final VoidCallback onHeartMode;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: AppTheme.listRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Row(
            children: <Widget>[
              CoverThumb(url: playlist.coverUrl, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      playlist.isLikedMusic ? '我喜欢的音乐' : playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.listTitle(colors),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      playlist.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.listSubtitle(colors),
                    ),
                  ],
                ),
              ),
              if (playlist.isLikedMusic) ...<Widget>[
                const SizedBox(width: 8),
                _HeartModePill(onTap: onHeartMode),
              ] else
                Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 白底胶囊：心形图标 + 「心动模式」
class _HeartModePill extends StatelessWidget {
  const _HeartModePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/profile/heart_mode.svg',
              width: 13,
              height: 13,
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '心动模式',
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
