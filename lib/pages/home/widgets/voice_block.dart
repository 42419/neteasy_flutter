import 'package:material_ui/material_ui.dart';

import '../../../components/cover_thumb.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/home_block.dart';
import 'section_parts.dart';

/// 播客节目行：所属播客 / 节目标题 / 标签 + 简介。
///
/// 标题可能占 1 行也可能占 2 行，简介的行数跟着变——用 TextPainter 量一次，
/// 保证「两行标题 + 一行简介」不会把这一行撑破。
class VoiceTile extends StatelessWidget {
  const VoiceTile({super.key, required this.voice});

  final HomeResource voice;

  /// 播客节目行高：官方约 92dp（封面 80），这里放 100 容下极端情况
  static const double rowHeight = 100;

  static TextStyle _titleStyle(AppColors colors) => TextStyle(
    fontSize: 16,
    height: 1.15,
    fontWeight: FontWeight.w500,
    color: colors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final String label = voice.labelTexts.isEmpty ? '' : voice.labelTexts.first;
    final String title = voice.displayName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CoverThumb(url: voice.imageUrl, size: 80, radius: 6),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // 量一次标题实际占几行，剩下的高度留给简介
              final TextPainter titlePainter = TextPainter(
                text: TextSpan(text: title, style: _titleStyle(colors)),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 2,
              );
              titlePainter.layout(maxWidth: constraints.maxWidth);
              final int titleLineCount = titlePainter
                  .computeLineMetrics()
                  .length;
              titlePainter.dispose();

              final int descMaxLines = titleLineCount >= 2 ? 1 : 2;

              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    voice.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                    ).copyWith(color: colors.textDescription),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(colors),
                  ),
                  if (label.isNotEmpty || voice.desc.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    // 标签与简介是同一条会换行的文字流，用 WidgetSpan 才能让第二行回到左边
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          if (label.isNotEmpty)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: TagChip(label, filled: true),
                              ),
                            ),
                          TextSpan(
                            text: voice.desc,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: colors.textDescription,
                            ),
                          ),
                        ],
                      ),
                      maxLines: descMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 80,
          child: Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 26,
              color: colors.iconPlay,
            ),
          ),
        ),
      ],
    );
  }
}

/// 有声书行：标题（两行）/ 灰色简介 / 分类标签 + 播放量，右侧评分。
///
/// 评分在官方用的是自有字体，这里只用字号/字重/颜色近似。
class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book});

  final HomeBook book;

  /// 有声书行高：官方实测 90dp，封面 64×80
  static const double rowHeight = 92;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // 有声书封面是竖版 64×80
        CoverThumb(
          url: book.coverUrl,
          size: 64,
          width: 64,
          height: 80,
          radius: 6,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (book.desc.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  book.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: colors.textDescription,
                  ),
                ),
              ],
              if (book.category.isNotEmpty ||
                  book.playCount.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    if (book.category.isNotEmpty) ...<Widget>[
                      TagChip(book.category),
                      const SizedBox(width: 8),
                    ],
                    if (book.playCount.isNotEmpty) ...<Widget>[
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 15,
                        color: colors.textTertiary,
                      ),
                      Text(
                        book.playCount,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (book.score.isNotEmpty)
          // 与封面（64×80）垂直居中，和官方一致
          SizedBox(
            height: 80,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                book.score,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: colors.textDescription,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 播客节目区：把 creatives 里的 resources 拍平成行
class VoiceBlock extends StatelessWidget {
  const VoiceBlock({super.key, required this.block});

  final HomeBlock block;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = block.creatives
        .expand((HomeCreative c) => c.resources)
        .map((HomeResource r) => VoiceTile(voice: r))
        .toList();
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return RowPages(tiles: tiles, rowHeight: VoiceTile.rowHeight);
  }
}

/// 有声书区：数据在 `dslData` 里，mapper 已拍平到 `block.books`
class BookBlock extends StatelessWidget {
  const BookBlock({super.key, required this.block});

  final HomeBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.books.isEmpty) {
      return const SizedBox.shrink();
    }
    return RowPages(
      tiles: block.books.map((HomeBook b) => BookTile(book: b)).toList(),
      rowHeight: BookTile.rowHeight,
    );
  }
}
