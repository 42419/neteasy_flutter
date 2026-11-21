import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/home_block.dart';
import 'cover_image.dart';
import 'section_parts.dart';

/// 歌曲行：官方「近期云村热播」样式。
/// 封面 48 / 歌名一行 / 标签 + 歌手 / 右侧实心播放三角。
/// 标签（`subtitle`）是「超51%人收藏」这类文案，歌手要读 `artists`。
class SongTile extends StatelessWidget {
  const SongTile({super.key, required this.song});

  final HomeResource song;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 48,
            height: 48,
            child: CoverImage(url: song.imageUrl, logicalWidth: 48),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      song.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (song.isVip) ...<Widget>[
                    const SizedBox(width: 4),
                    SvgPicture.asset(AppConstants.vipBadge, height: 12),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: <Widget>[
                  if (song.subtitle.isNotEmpty) ...<Widget>[
                    Flexible(child: TagChip(song.subtitle)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      song.artistLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(colors),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.play_arrow_rounded, size: 26, color: colors.iconPlay),
      ],
    );
  }
}

/// 一卡三首的歌曲区：曲风推荐、新歌新碟。
/// 每张卡原本的 3 首歌拆成 3 行，3 行一页横向翻。
class SongBlock extends StatelessWidget {
  const SongBlock({super.key, required this.block});

  final HomeBlock block;

  /// 歌曲行高：官方「近期云村热播」实测 58dp
  static const double rowHeight = 58;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[
      for (final HomeCreative creative in block.creatives)
        for (final HomeResource song in creative.resources.take(3))
          SongTile(song: song),
    ];
    // 区块里一首歌都没有时不占空白
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return RowPages(tiles: tiles, rowHeight: rowHeight);
  }
}
