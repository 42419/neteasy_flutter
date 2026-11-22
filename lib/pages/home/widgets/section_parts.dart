import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 区块标题。箭头只在这个区块有「更多」入口时才画。
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.showMore = false});

  final String title;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
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
              style: AppTheme.sectionTitle(colors),
            ),
          ),
          if (showMore)
            Icon(
              Icons.chevron_right_rounded,
              size: 25,
              color: colors.textPrimary,
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
    final AppColors colors = AppTheme.colorsOf(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: filled ? 4 : 2, vertical: 1),
      decoration: BoxDecoration(
        color: filled ? colors.chipFill : null,
        border: filled
            ? null
            : Border.all(color: colors.chipBorder, width: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, height: 1.2, color: colors.chipText),
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

/// 把一串条目按每 3 条一页横向铺开（歌曲、播客节目、有声书），**整页整页地翻**：
/// 手指松开后总是吸附到某一页的左边，和官方一样是 PageView 的手感，
/// 不是随手滑到哪停在哪。
///
/// 几何实测：页宽 = 屏幕宽 − 32，页内左 16 / 右 8，页与页之间**不留间隙**。
/// 这样下一页的封面只在屏幕右缘露出约 16dp，三组宽度完全一致。
///
/// 实现：`PageView` + `viewportFraction`（页宽 / 屏宽）+ `padEnds: false`
/// （第一页贴左边，不居中）。最后一页吸附到左边后，右边会留出一截空白，
/// 这是 `viewportFraction < 1` 的固有表现。
class RowPages extends StatefulWidget {
  const RowPages({super.key, required this.tiles, required this.rowHeight});

  final List<Widget> tiles;
  final double rowHeight;

  @override
  State<RowPages> createState() => _RowPagesState();
}

class _RowPagesState extends State<RowPages> {
  PageController? _controller;
  double _fraction = 0;

  /// `viewportFraction` 是 `PageController` 的构造参数，建好就改不了。
  /// 宽度变了（折叠屏展开、分屏）要换一个新的，并保留当前页。
  ///
  /// 旧的不能立刻 dispose：此刻旧的 PageView 还挂在它上面，等这一帧
  /// 换完控制器再释放，否则它卸载时会碰到已释放的控制器。
  PageController _controllerFor(double fraction) {
    final PageController? current = _controller;
    if (current != null && (fraction - _fraction).abs() < 0.001) {
      return current;
    }
    int page = 0;
    if (current != null) {
      if (current.hasClients) {
        page = (current.page ?? 0).round();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    _fraction = fraction;
    return _controller = PageController(
      viewportFraction: fraction,
      initialPage: page,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Widget>> pages = <List<Widget>>[];
    for (int i = 0; i < widget.tiles.length; i += 3) {
      pages.add(
        widget.tiles.sublist(
          i,
          i + 3 > widget.tiles.length ? widget.tiles.length : i + 3,
        ),
      );
    }
    return SizedBox(
      height: widget.rowHeight * 3,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final PageController controller = _controllerFor(
            (width - AppTheme.pagePadding * 2) / width,
          );
          return PageView.builder(
            controller: controller,
            padEnds: false,
            itemCount: pages.length,
            itemBuilder: (BuildContext context, int index) => Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.pagePadding,
                right: 8,
              ),
              child: Column(
                children: <Widget>[
                  for (final Widget tile in pages[index])
                    SizedBox(height: widget.rowHeight, child: tile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
