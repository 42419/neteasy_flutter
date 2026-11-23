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
/// 为什么不直接用 `PageView`：`viewportFraction < 1` 时 PageView 的滚动范围
/// 只到「最后一页贴住屏幕右缘」，最后一页没法像前面的页一样吸附到左边，
/// 只能被推到右边，还会在左边露出上一页的播放键——官方的最后一页是和其他页
/// 一模一样地贴左、右边留空。所以这里用 `ListView`（定宽条目 + 右侧补一段）
/// 加自己的吸附物理效果，把最后一页的位置也算进去。
class RowPages extends StatefulWidget {
  const RowPages({super.key, required this.tiles, required this.rowHeight});

  final List<Widget> tiles;
  final double rowHeight;

  @override
  State<RowPages> createState() => _RowPagesState();
}

class _RowPagesState extends State<RowPages> {
  final ScrollController _controller = ScrollController();

  /// 当前一页的宽度。物理效果在滚动位置建好时就定下来了，之后宽度变化它自己
  /// 看不到，所以让它每次吸附时回来读这里的最新值。
  double _pageExtent = 0;

  late final _PageSnapPhysics _physics = _PageSnapPhysics(
    pageExtent: () => _pageExtent,
  );

  /// 记下新页宽；宽度变了（折叠屏展开、分屏）就在这一帧布局完后，
  /// 把滚动偏移换算到新宽度，让它仍停在原来那一页。
  void _syncPageExtent(double next) {
    final double previous = _pageExtent;
    _pageExtent = next;
    if (previous <= 0 ||
        (previous - next).abs() < 0.5 ||
        !_controller.hasClients) {
      return;
    }
    final double page = (_controller.offset / previous).roundToDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final ScrollPosition position = _controller.position;
      _controller.jumpTo(
        (page * next).clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
          final double pageWidth = width - AppTheme.pagePadding * 2;
          _syncPageExtent(pageWidth);
          return ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: _physics,
            itemExtent: pageWidth,
            // 右边补「屏宽 − 页宽」：滚动范围刚好到「最后一页贴住屏幕左边」，
            // 最后一页就能和前面的页一样吸附到左边，右边留空
            padding: EdgeInsets.only(right: width - pageWidth),
            itemCount: pages.length,
            itemBuilder: (BuildContext context, int index) => Padding(
              // 右边距归零：官方行内容一直排到页宽边缘，右侧播放三角的墨迹
              // 右缘离页边约 4.5dp。留 8dp 会整体左移，三角看起来偏内
              padding: const EdgeInsets.only(left: AppTheme.pagePadding),
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

/// 按**固定页宽**整页吸附的滚动物理效果。
///
/// 逻辑照搬 Flutter 的 `PageScrollPhysics`（拖过半页或甩一下就翻页，否则回弹），
/// 区别只在页宽：`PageScrollPhysics` 用视口宽度当页宽，这里用 [pageExtent]
/// 给的页宽，因为我们的一页比屏幕窄 32dp。
class _PageSnapPhysics extends ScrollPhysics {
  const _PageSnapPhysics({required this.pageExtent, super.parent});

  /// 当前页宽。用函数而不是数值：物理效果实例会被滚动位置长期持有，
  /// 宽度变了得能读到最新的。
  final double Function() pageExtent;

  @override
  _PageSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _PageSnapPhysics(
      pageExtent: pageExtent,
      parent: buildParent(ancestor),
    );
  }

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
    double extent,
  ) {
    double page = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final double extent = pageExtent();
    // 越界且没在往回走：交给父类的回弹；页宽还没量出来也走父类
    if (extent <= 0 ||
        (velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _targetPixels(position, tolerance, velocity, extent);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
