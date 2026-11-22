import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../viewmodels/home_block.dart';
import 'section_parts.dart';

/// 封面卡：歌单、播客这种「一张图 + 标题」的方块。
/// 左上播放量、右下播放键都按需显示。
class CoverCard extends StatelessWidget {
  const CoverCard({
    super.key,
    required this.image,
    required this.name,
    this.playCount = 0,
    this.showPlay = true,
  });

  final String image;
  final String name;
  final int playCount;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CoverImage(url: image, logicalWidth: 150),
                  ),
                  if (playCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.countBadgeScrim,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusChip,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.headphones,
                              size: 12,
                              color: colors.onMedia,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatCount(playCount),
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: colors.onMedia,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showPlay)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 30,
                        color: colors.onMedia,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle(colors),
            ),
          ),
        ],
      ),
    );
  }
}

/// 歌单横滑一排：推荐歌单、雷达歌单、专属场景歌单、热门播客都用它
class PlaylistRow extends StatelessWidget {
  const PlaylistRow({
    super.key,
    required this.block,
    this.showCount = true,
    this.showPlay = true,
  });

  final HomeBlock block;
  final bool showCount;
  final bool showPlay;

  @override
  Widget build(BuildContext context) {
    return HorizontalList(
      height: 200,
      itemCount: block.creatives.length,
      itemBuilder: (BuildContext context, int index) {
        final HomeCreative creative = block.creatives[index];
        final HomeResource? res = creative.primary;
        final String image = res != null && res.imageUrl.isNotEmpty
            ? res.imageUrl
            : creative.imageUrl;
        // 热门播客的 resources 是空的，名字只在 creative 上
        final String resName = res?.displayName ?? '';
        return CoverCard(
          image: image,
          name: resName.isNotEmpty ? resName : creative.title,
          playCount: showCount ? (res?.playCount ?? 0) : 0,
          showPlay: showPlay,
        );
      },
    );
  }
}
