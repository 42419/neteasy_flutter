import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import 'daily_action_bar.dart';
import 'daily_history_pill.dart';
import 'daily_segment.dart';

/// 每日推荐的暖橙渐变头，**滚动后吸顶**。
///
/// 展开时：状态栏 + 返回/胶囊/更多 → 日期 → 今日运势 / 历史日推 → 播放全部；
/// 收起时只留状态栏 + 顶栏 + 「播放全部」那一行。
///
/// 收起后「播放全部」还在，是官方实测的行为：吸顶之后歌曲列表继续滚，
/// 而这一行钉在顶栏下面不动（录屏里列表在动、播放键的红圆一直在 109dp）。
/// 所以它必须画在头部里、贴着头底边，不能当普通 sliver 放进列表。
///
/// 背景分两截：橙色区铺到播放栏上沿（展开时再往下伸 6dp），下缘做一道**垂直模糊**
/// 化进页面底色；模糊半径随折叠线性收小，吸顶时归零，于是那一下变成官方那种硬边。
/// 橙区里的渐变按当前高度重铺，色带会随折叠缓慢上移，但不留硬接缝。
class DailyHeaderDelegate extends SliverPersistentHeaderDelegate {
  DailyHeaderDelegate({
    required this.statusBarHeight,
    required this.date,
    required this.refreshing,
    required this.onPlayAll,
    required this.onRefresh,
  });

  /// 状态栏高度：头部要从屏幕顶边开始铺，由调用方从 `MediaQuery` 取
  final double statusBarHeight;

  /// 日期按打开页面那天算，跨零点不主动刷新（跟官方一致，重进才算新的一天）
  final DateTime date;

  /// 「换一批」进行中
  final bool refreshing;

  /// 列表还没有内容时传 null：骨架期间「播放全部」不该能点
  final VoidCallback? onPlayAll;
  final VoidCallback onRefresh;

  /// 顶栏高度（不含状态栏）
  static const double topBarHeight = 52;

  /// 「播放全部」那一行的高度：与 [DailyActionBar] 的 8 + 40 + 4 对齐，
  /// 收起后正好是「状态栏 + 顶栏 + 播放栏」= 官方录屏里的 144
  static const double actionBarHeight = 52;

  /// 顶栏到日期之间的留白，压掉整片会挤在一起
  static const double _topGap = 54;

  /// 日期行高：48 号字、`height: 1`
  static const double _dateHeight = 48;

  /// 日期到「查看今日运势」的间距
  static const double _fortuneGap = 6;

  /// 「查看今日运势 / 历史日推」行高：由胶囊的 30 决定，不是文字高度
  static const double _fortuneHeight = 30;

  /// 运势行到播放栏之间的留白
  static const double _bottomPad = 30;

  /// 橙色实色区下缘的最大模糊半径（dp）。展开时橙色在播放栏上沿糊开、
  /// 慢慢化进页面底色；随折叠线性收小，吸顶时归零，变成一条硬边。
  static const double _blurSigma = 15;

  /// 展开时橙色区的硬边压到播放栏上沿**之下** 6dp（官方在顶部时橙色是伸进
  /// 播放栏一点的，那一行底下是淡粉）；收起过程中这个外溢归零，
  /// 硬边正好压在播放栏上沿。
  static const double _edgeOverhang = 6;

  /// 实色区固定取调色板到这一段为止（0.80，四段）。
  ///
  /// 最后一段的颜色按折叠进度在 `#FDAB8E`（饱和，收起时橙条下沿不发白）和
  /// `#F6C2AF`（淡粉，展开时橙色才伸得进播放栏）之间插值。
  /// **不能改成「多取/少取一个色标」**：那样滚动一像素色标数量就变，
  /// 整条渐变的映射跟着换一套，起手那一下会突然跳色。
  static const double _solidStopLimit = 0.80;

  /// 实色区用到的颜色：调色板里到 [_solidStopLimit] 为止，末段按 [remain] 插值
  List<Color> _solidColors(DailyColors daily, double remain) {
    final int count = daily.headerGradientStops
        .where((double stop) => stop <= _solidStopLimit + 1e-6)
        .length
        .clamp(2, daily.headerGradient.length);
    final List<Color> colors = daily.headerGradient.sublist(0, count);
    colors[count - 1] = Color.lerp(
      colors[count - 2],
      colors[count - 1],
      remain,
    )!;
    return colors;
  }

  /// 色标：把上面那几个点铺满实色区，再按「往上多画 3σ」换算
  List<double> _solidStops(DailyColors daily, double orangeHeight, double pad) {
    final int count = _solidColors(daily, 1).length;
    final double last = daily.headerGradientStops[count - 1];
    final double full = orangeHeight + pad;
    return <double>[
      for (int i = 0; i < count; i++)
        (daily.headerGradientStops[i] / last * orangeHeight + pad) / full,
    ];
  }

  /// 展开时的总高度
  static double maxExtentOf(double statusBarHeight) =>
      statusBarHeight +
      topBarHeight +
      _topGap +
      _dateHeight +
      _fortuneGap +
      _fortuneHeight +
      _bottomPad +
      actionBarHeight;

  /// 收起后只剩状态栏 + 顶栏 + 播放栏
  static double minExtentOf(double statusBarHeight) =>
      statusBarHeight + topBarHeight + actionBarHeight;

  @override
  double get maxExtent => maxExtentOf(statusBarHeight);

  @override
  double get minExtent => minExtentOf(statusBarHeight);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    // 折叠进度：0 展开、1 完全收起。日期块跟着上移并淡出，
    // 收到底时它已经滑到顶栏后面，不该再透出半截。
    final double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );
    final double height = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    // 橙色区的硬边：展开时略低于播放栏上沿，收起时回到上沿；
    // 模糊半径随折叠线性收小，吸顶时归零，于是那一下变成硬边
    final double remain = 1 - progress;
    final double grow = _edgeOverhang * remain;
    final double orangeHeight = (height - actionBarHeight + grow).clamp(
      40.0,
      maxExtent - actionBarHeight + _edgeOverhang,
    );
    final double blurSigma = _blurSigma * remain;
    final double blurPad = blurSigma * 3;

    return ClipRect(
      child: Stack(
        children: <Widget>[
          // 播放栏那一条先垫实页面底色：头部是吸顶的，列表会从它下面滚过，
          // 这里不挡就会透出歌名。垫完再把橙色和它的模糊画上去（模糊盖在白底上才是过渡）。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: actionBarHeight,
            child: ColoredBox(color: daily.pageBackground),
          ),
          // 橙色区和播放栏是两截：橙色只铺到播放栏上沿（height - 52），
          // 下缘带一道**垂直模糊**，糊开的橙色盖到页面底色上、慢慢化掉。
          // 模糊半径随折叠线性收小，吸顶时归零 —— 那一下就是官方那种硬边。
          Positioned(
            top: -blurPad,
            left: 0,
            right: 0,
            height: orangeHeight + blurPad,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 0.001,
                sigmaY: blurSigma <= 0 ? 0.001 : blurSigma,
                tileMode: TileMode.decal,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _solidColors(daily, remain),
                    stops: _solidStops(daily, orangeHeight, blurPad),
                  ),
                ),
              ),
            ),
          ),
          // 日期块先画、顶栏后画：收起过程中日期往上滑，要钻到顶栏底下而不是盖住它
          Positioned(
            top: statusBarHeight + topBarHeight + _topGap - shrinkOffset,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 1 - progress,
              child: _buildDateBlock(context, colors, daily),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(top: statusBarHeight),
              child: SizedBox(
                height: topBarHeight,
                child: _buildTopBar(context, colors),
              ),
            ),
          ),
          // 播放栏贴着头底边：吸顶后它就钉在顶栏下面，不再跟着列表滚走。
          // 它自己不铺底色，露出的就是页面底色；上面的橙色只靠模糊带过来一点。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: actionBarHeight,
              child: DailyActionBar(
                refreshing: refreshing,
                onPlayAll: onPlayAll,
                onRefresh: onRefresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶栏：返回 / 胶囊居中 / 更多
  Widget _buildTopBar(BuildContext context, AppColors colors) {
    return Stack(
      children: <Widget>[
        const Center(child: DailySegment()),
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, size: 24),
              color: colors.onMedia,
              tooltip: '返回',
            ),
            const Spacer(),
            IconButton(
              // 「更多」里的操作都没做，先只占位
              onPressed: () {},
              icon: const Icon(Icons.more_vert, size: 24),
              color: colors.onMedia,
              tooltip: '更多',
            ),
          ],
        ),
      ],
    );
  }

  /// 日期 + 今日运势 / 历史日推
  Widget _buildDateBlock(
    BuildContext context,
    AppColors colors,
    DailyColors daily,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: AppTheme.pagePadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: _dateHeight,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colors.onMedia,
                ),
              ),
              Text(
                '/${date.month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: daily.dateSuffix,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _fortuneGap),
        SizedBox(
          height: _fortuneHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '查看今日运势',
                  style: TextStyle(fontSize: 13, color: daily.fortuneText),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: daily.fortuneText,
                ),
                const Spacer(),
                DailyHistoryPill(onTap: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 每次页面重建都重画：里面的回调闭包捕获了当前这批歌曲，
  /// 比对新旧 delegate 的字段省不下什么，反而会让旧闭包留下来。
  @override
  bool shouldRebuild(DailyHeaderDelegate oldDelegate) => true;
}
