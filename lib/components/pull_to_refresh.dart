import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// 网易云式的下拉刷新。
///
/// 和 Material 的 `RefreshIndicator` 不一样：内容是跟着手指一块往下走的，
/// 拉出来的空档里放启动页那个音符描边动画——只不过启动页是自动播，
/// 这里是「跟手」播，描边的生长进度直接由下拉距离决定，松手才自己续上。
///
/// 用法：`builder` 拿到 [extraTop]，把它垫在第一个 sliver 顶上。
/// 刷新悬停期间靠这段空白把内容撑在拉下来的位置，指示器才有地方待着；
/// 否则松手后回弹会把内容收回去，指示器就压在头像上了。
///
/// 外层的滚动视图要用 [BouncingScrollPhysics]：只有允许越界，`pixels`
/// 才会变成负数，才量得到下拉距离，内容也才会真的跟着走。
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.builder,
    this.threshold = 90,
  });

  /// 松手后要等的事；它返回的 Future 一完成就收起来
  final Future<void> Function() onRefresh;

  /// [extraTop] 是刷新悬停时内容顶部要多垫的空白
  final Widget Function(BuildContext context, double extraTop) builder;

  /// 拉过这个距离松手就刷新，也是描边长满的位置
  final double threshold;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  /// 指示器只跟着一小部分手指位移走：内容走满格、指示器只挪一点，
  /// 拉得越远两者离得越开，看起来才有「重心落在后面」的手感
  static const double _damping = 0.1;

  /// 圆形底直径
  static const double _size = 50;

  /// 动画画布是 132×132，但那条描边只占画布的 44%×49%（导出时自带留白），
  /// 所以画布要和圆底一样大——画布给小了，描边就只剩一小坨。
  static const double _noteBox = _size;

  /// 拉过这个距离指示器才开始露头，之前完全不出现。
  /// 和 `threshold` 是同一把尺子（下拉距离），注意别取到比 threshold 还大
  static const double _appearAt = 28;

  /// 描边在第 42 帧长满（整段 78 帧），之后是呼吸。
  /// 跟手阶段只走到这里，剩下的留给刷新中循环。
  static const double _growth = 42 / 78;

  /// 松手后收回用的时长。
  ///
  /// 别指望物理回弹：`BouncingScrollPhysics` 在「零速度松手 + 越界」时走的是
  /// 一条半衰期 70ms 的指数衰减，80ms 就冲过大半，等到被留白接住那一刻
  /// 速度还有八九百 px/s，等于硬生生截停。所以可见位置不听物理的，
  /// 按这条曲线自己走，起止速度都是 0。
  static const Duration _settleDuration = Duration(milliseconds: 340);

  late final AnimationController _scrub = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 松手后「收回到位」的进度：0 → 1
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _settleDuration,
  );

  /// 内容顶部的留白（dp）。它和物理回弹互为补偿，差额由 [_targetOffset] 决定
  final ValueNotifier<double> _pad = ValueNotifier<double>(0);

  /// 内容的视觉位移（被顶下去多少 dp），指示器跟它走
  final ValueNotifier<double> _pull = ValueNotifier<double>(0);

  /// 手指还按在屏幕上
  bool _dragging = false;

  /// 这一轮手势已经判过松手了，别重复触发
  bool _decided = false;

  bool _refreshing = false;

  /// 这一轮手势里最后一帧手指拉的位移；松手后像素会立刻回弹，
  /// 判定要用松手前的值，不能用回弹后的
  double _lastDragPull = 0;

  /// 最近一次滚动通知里的越界距离（>= 0）
  double _over = 0;

  /// 最近一次的视觉位移（留白 + 越界），收回曲线的起点要取它。
  /// 别在松手那一帧现算：那时物理已经先跑掉几十像素，起点会被吃掉一截，
  /// 表现为松手瞬间内容先蹦一下
  double _visual = 0;

  /// 收回的起点 / 终点（dp）
  double _landFrom = 0;
  double _landTo = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(_syncOffset);
  }

  @override
  void dispose() {
    _settle.dispose();
    _scrub.dispose();
    _pad.dispose();
    _pull.dispose();
    super.dispose();
  }

  /// 内容现在该被顶下去多少（dp）。
  ///
  /// 手指拉着时就是越界距离，一比一跟手；松手之后交给 [_settle] 的曲线，
  /// 从松手那一格走到悬停位（或者归零）。
  double get _targetOffset {
    if (_dragging) {
      return _over;
    }
    final double t = Curves.easeInOutCubic.transform(_settle.value);
    return _landFrom + (_landTo - _landFrom) * t;
  }

  /// 把「想让它停在哪」换算成留白：滚动位置已经越界了，留白只补差额，
  /// 加起来正好落在曲线上。
  ///
  /// 留白不能是负的（没法把内容往上拽），所以这条曲线只能比物理回弹走得慢
  /// 或一样快——物理回弹本来就快，正常情况下一直是留白在主导。
  void _syncOffset() {
    final double target = _targetOffset;
    final double pad = (target - _over).clamp(0.0, double.infinity);
    _pad.value = pad;
    _visual = pad + _over;
    _pull.value = _visual;
    // 刷新中描边自己在呼吸，别被这里覆盖
    if (!_refreshing) {
      _scrub.value = (_visual / widget.threshold).clamp(0.0, 1.0) * _growth;
    }
  }

  bool _onScroll(ScrollNotification notification) {
    _over = notification.metrics.pixels < 0 ? -notification.metrics.pixels : 0;

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        // 手指在拉：一比一跟手
        _dragging = true;
        // 只要还有拖拽帧就说明手指没松，上一轮的判定作废
        _decided = false;
        _lastDragPull = _over;
        _syncOffset();
      } else if (_dragging) {
        // 松手后的第一帧：先判要不要刷新，之后交给曲线
        _release();
      } else {
        // 曲线在走、物理也在回弹，逐帧重算留白
        _syncOffset();
      }
    } else if (notification is ScrollEndNotification && _dragging) {
      _release();
    }
    return false;
  }

  void _release() {
    _dragging = false;
    if (_decided) {
      return;
    }
    _decided = true;
    if (_lastDragPull >= widget.threshold) {
      _startRefresh();
    } else {
      // 没拉够：从当前位置收回零位
      _settleTo(0);
    }
  }

  /// 从当前视觉位置走一条曲线到 [to]
  void _settleTo(double to) {
    _landFrom = _visual;
    _landTo = to;
    _settle.forward(from: 0);
    _syncOffset();
  }

  void _startRefresh() {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    _scrub.value = _growth;
    // 刷新中来回呼吸第 42–78 帧，和启动页停下来之后那段是同一段
    _scrub.repeat(
      min: _growth,
      max: 1,
      reverse: true,
      period: const Duration(milliseconds: 900),
    );
    _settleTo(widget.threshold);
    _runRefresh();
  }

  Future<void> _runRefresh() async {
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _refreshing = false;
        _scrub.stop();
        // 描边跟着内容一起收：_syncOffset 每帧按视觉位置重算
        _settleTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: <Widget>[
          // 只有留白真的变了才重建内容；跟手阶段留白恒为 0，不牵连滚动视图
          AnimatedBuilder(
            animation: _pad,
            builder: (BuildContext context, Widget? child) =>
                widget.builder(context, _pad.value),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pull,
                // 圆底和音符只在主题变化时重建，不跟着每一帧下拉走
                child: _buildIndicator(colors),
                builder: (BuildContext context, Widget? child) {
                  final double shown = _pull.value;
                  final double span = widget.threshold - _appearAt;
                  final double t = span <= 0
                      ? 1.0
                      : ((shown - _appearAt) / span).clamp(0.0, 1.0);
                  if (t == 0) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: shown.clamp(0, widget.threshold) * _damping,
                      ),
                      child: Opacity(opacity: t, child: child),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 浅灰圆底 + 中间的网易云音符
  Widget _buildIndicator(AppColors colors) {
    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.textPrimary.withValues(alpha: 0.06),
        ),
        child: ClipOval(
          child: ColorFiltered(
            // 动画里只有一条纯黑描边，深色底必须整体换色，否则等于隐形
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
            child: Lottie.asset(
              'assets/anim/netease_loading.json',
              controller: _scrub,
              width: _noteBox,
              height: _noteBox,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
