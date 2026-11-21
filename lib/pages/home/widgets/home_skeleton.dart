import 'package:material_ui/material_ui.dart';

import '../../../components/pull_to_refresh.dart';
import '../../../theme/app_theme.dart';

/// 首页骨架屏：还没有任何快照可铺时的首屏占位。
///
/// 几何全部照真实区块取值——入口卡行 200、歌单 / 榜单行 200、歌曲行 58×3、
/// 区块头内边距 20 / 10——数据到达后高度不变，页面不会跳。
///
/// 动效只用一个 controller 驱动每个区块一层 `ShaderMask`：
/// 十几个独立动画在中低端机上会掉帧，而这里只有一束光在扫。
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key, required this.onRefresh});

  /// 加载态也允许下拉刷新
  final Future<void> Function() onRefresh;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 系统开了「减少动态效果」就退化成静态灰块
    final bool animate =
        !(MediaQuery.maybeReduceMotionOf(context) ?? false) &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool animate = _controller.isAnimating;
    return PullToRefresh(
      onRefresh: widget.onRefresh,
      builder: (BuildContext context, double extraTop) => CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(child: SizedBox(height: extraTop)),
          SliverToBoxAdapter(
            child: _Section(
              animation: animate ? _controller : null,
              // 入口卡行没有区块标题，直接顶在顶部栏下面
              showHeader: false,
              child: const _CardRow(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          SliverToBoxAdapter(
            child: _Section(
              animation: animate ? _controller : null,
              child: const _CardRow(),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              animation: animate ? _controller : null,
              child: _RowBlock(height: _SongRow.rowHeight * 3),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              animation: animate ? _controller : null,
              child: _RowBlock(height: _SongRow.rowHeight * 3),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              animation: animate ? _controller : null,
              child: const _CardRow(showRank: true),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一个区块 = 标题骨 + 内容骨，整体罩一层扫光
class _Section extends StatelessWidget {
  const _Section({
    required this.animation,
    required this.child,
    this.showHeader = true,
  });

  final Animation<double>? animation;
  final Widget child;

  /// 入口卡行没有标题，画了反而多出一块
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _Shimmer(
        animation: animation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showHeader)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  20,
                  AppTheme.pagePadding,
                  10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Bone(width: 88, height: 22),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// 扫光：一束半透明白光从左侧扫到右侧，盖在骨架的实色块上
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.animation, required this.child});

  final Animation<double>? animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = this.animation;
    if (animation == null) {
      return child;
    }
    return AnimatedBuilder(
      animation: animation,
      // child 不参与重建，每帧只重算 shader
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.8 + 3.4 * t, 0),
              end: Alignment(-0.8 + 3.4 * t, 0),
              colors: <Color>[
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const <double>[0, 0.5, 1],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// 封面卡行：入口卡、推荐歌单、我的歌单、排行榜共用
class _CardRow extends StatelessWidget {
  const _CardRow({this.showRank = false});

  /// 排行榜卡是整块渐变卡，没有封面下方的两行字
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        itemCount: 3,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _CardBone(showRank: showRank),
          );
        },
      ),
    );
  }
}

class _CardBone extends StatelessWidget {
  const _CardBone({required this.showRank});

  final bool showRank;

  @override
  Widget build(BuildContext context) {
    if (showRank) {
      return const _Bone(width: 150, height: 200, radius: AppTheme.radiusCard);
    }
    return const SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Bone(width: 150, height: 150, radius: AppTheme.radiusCard),
          SizedBox(height: 10),
          _Bone(width: 150, height: 14),
          SizedBox(height: 6),
          _Bone(width: 96, height: 14),
        ],
      ),
    );
  }
}

/// 三行一条的歌曲区块（曲风推荐、新歌新碟）
class _RowBlock extends StatelessWidget {
  const _RowBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _SongRow(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 单条歌曲骨：48 封面 + 两行字
class _SongRow extends StatelessWidget {
  const _SongRow();

  static const double rowHeight = 58;

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Bone(width: 48, height: 48, radius: 6),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Bone(width: 180, height: 14),
            SizedBox(height: 6),
            _Bone(width: 110, height: 11),
          ],
        ),
      ],
    );
  }
}

/// 骨架基础块：实色圆角，扫光只改它的亮度
class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, this.radius = 4});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.placeholder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
