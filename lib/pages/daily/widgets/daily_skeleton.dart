import 'package:material_ui/material_ui.dart';

import '../../../components/skeleton.dart';
import '../../../theme/app_theme.dart';
import 'daily_song_row.dart';

/// 每日推荐页的骨架：数据还没到时的列表占位。
///
/// 首次进入、跨天失效后都会走到这里。行高、封面边长、左右边距全部照
/// [DailySongRow] 的真值取，数据到达后高度不变，页面不会跳。
///
/// 扫光只有一个 controller（跟首页同款），系统开了「减少动态效果」就退化成
/// 静态灰块。
class DailySkeleton extends StatefulWidget {
  const DailySkeleton({super.key});

  /// 占位行数：够铺满一屏
  static const int rows = 8;

  @override
  State<DailySkeleton> createState() => _DailySkeletonState();
}

class _DailySkeletonState extends State<DailySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    return Shimmer(
      animation: _controller.isAnimating ? _controller : null,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < DailySkeleton.rows; i++) const _SkeletonRow(),
        ],
      ),
    );
  }
}

/// 一行占位：40 封面 + 两行字 + 右侧 ⋮
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DailySongRow.rowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: AppTheme.pagePadding, right: 16),
        child: Row(
          children: <Widget>[
            const SkeletonBone(width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 歌名 16sp、副标题 12sp，高度按字高折半取值
                  const SkeletonBone(width: 168, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonBone(width: 104, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SkeletonBone(width: 4, height: 18),
          ],
        ),
      ),
    );
  }
}
