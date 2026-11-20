import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 区块标题。箭头只在这个区块有「更多」入口时才画。
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.showMore = false});

  final String title;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        10,
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sectionTitle,
            ),
          ),
          if (showMore)
            const Icon(
              Icons.chevron_right_rounded,
              size: 25,
              color: AppTheme.textPrimary,
            ),
        ],
      ),
    );
  }
}

/// 分类/标签小标签。
///
/// 官方两套：有声书分类是透明底 + 蓝灰细描边，播客标签是浅蓝填充（#E5EAF2）。
/// 文字都取 #5975B2。
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: filled ? 4 : 2, vertical: 1),
      decoration: BoxDecoration(
        color: filled ? AppTheme.chipFill : null,
        border: filled
            ? null
            : Border.all(color: AppTheme.chipBorder, width: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          height: 1.2,
          color: AppTheme.chipText,
        ),
      ),
    );
  }
}

/// 横向滑动的一排，统一间距与边距
class HorizontalList extends StatelessWidget {
  const HorizontalList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        itemCount: itemCount,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 10),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// 把一串条目按每 3 条一页横向铺开（歌曲、播客节目、有声书）。
///
/// 几何照官方实测：页宽 = 屏幕宽 − 32，页内左 16 / 右 8，页与页之间**不留间隙**。
/// 这样下一页的封面只在屏幕右缘露出约 16dp，三组宽度完全一致。
class RowPages extends StatelessWidget {
  const RowPages({super.key, required this.tiles, required this.rowHeight});

  final List<Widget> tiles;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final List<List<Widget>> pages = <List<Widget>>[];
    for (int i = 0; i < tiles.length; i += 3) {
      pages.add(tiles.sublist(i, i + 3 > tiles.length ? tiles.length : i + 3));
    }
    final double pageWidth =
        MediaQuery.sizeOf(context).width - AppTheme.pagePadding * 2;
    return SizedBox(
      height: rowHeight * 3,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: pages.length,
        itemBuilder: (BuildContext context, int index) => SizedBox(
          width: pageWidth,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.pagePadding,
              right: 8,
            ),
            child: Column(
              children: <Widget>[
                for (final Widget tile in pages[index])
                  SizedBox(height: rowHeight, child: tile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
