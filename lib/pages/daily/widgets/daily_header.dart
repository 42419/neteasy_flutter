import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../stores/daily_store.dart';
import '../../../stores/player_store.dart';
import '../../../theme/app_theme.dart';
import 'daily_action_bar.dart';
import 'daily_history_pill.dart';
import 'daily_segment.dart';

/// 每日推荐的暖橙渐变头。
///
/// 从上到下：返回 / 默认推荐·风格推荐 / 更多 → 日期 → 今日运势 / 历史日推 →
/// 播放全部、换一批、多选。整块压在渐变上，所以文字一律走 `onMedia` 白系。
///
/// 渐变最后一段必须等于页面背景（浅 `#F4F7FA` / 深 `#151515`），否则和下面的
/// 列表之间会切出一条硬边；落点延长到「播放全部」那行，按钮才不会被渐变截断。
class DailyHeader extends StatelessWidget {
  const DailyHeader({super.key, required this.store});

  final DailyStore store;

  /// 顶栏高度（不含状态栏）
  static const double topBarHeight = 52;

  /// 顶栏到日期之间的留白，压掉整片会挤在一起
  static const double _topGap = 54;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    final DateTime now = DateTime.now();
    final String day = '${now.day}';
    final String month = now.month.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: daily.headerGradient,
          stops: daily.headerGradientStops,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTopBar(context, colors),
            const SizedBox(height: _topGap),
            // 日期
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.pagePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: colors.onMedia,
                    ),
                  ),
                  Text(
                    '/$month',
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
            // 查看今日运势 / 历史日推
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                6,
                AppTheme.pagePadding,
                30,
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
            // 播放全部：也在渐变背景内部
            DailyActionBar(
              refreshing: store.refreshing,
              onPlayAll: () =>
                  context.read<PlayerStore>().playQueue(store.songs),
              onRefresh: () => store.load(refresh: true),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶栏：返回 / 胶囊居中 / 更多
  Widget _buildTopBar(BuildContext context, AppColors colors) {
    return SizedBox(
      height: topBarHeight,
      child: Stack(
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
      ),
    );
  }
}
