import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';

import '../../constants/app_constants.dart';
import '../cover_image.dart';
import 'mini_player_metrics.dart';

/// 黑胶唱片 + 压在上面的封面。
///
/// 播放时整体顺时针匀速转（封面跟着转，像真唱片），暂停就停在当前角度，
/// 再播从那儿接着转，不回到 0。
class MiniPlayerDisc extends StatefulWidget {
  const MiniPlayerDisc({super.key, required this.item, required this.playing});

  final MediaItem item;
  final bool playing;

  @override
  State<MiniPlayerDisc> createState() => _MiniPlayerDiscState();
}

class _MiniPlayerDiscState extends State<MiniPlayerDisc>
    with SingleTickerProviderStateMixin {
  /// 转一圈的时长。官方截图是静止帧，量不出转速，先给一个偏慢的值，
  /// 看着不像电风扇又不至于看不出在转
  static const Duration _turn = Duration(seconds: 20);

  /// 唱片上盖的封面直径：截图量出来是 89/132 ≈ 三分之二
  static const double _coverSize = 30;

  /// 唱片素材自带一圈透明留白：只有中间 83% 是不透明的。
  /// 按 44dp 原样画，可见唱片只剩 36.6dp，黑环细得几乎看不出来，
  /// 所以放大到 1/0.83，让可见直径正好等于胶囊高度。
  static const double _discScale = 1 / 0.832;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _turn,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) {
      _spin.repeat();
    }
  }

  @override
  void didUpdateWidget(MiniPlayerDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        // 从当前角度接着转，别跳回 0
        _spin.repeat();
      } else {
        _spin.stop();
      }
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: SizedBox(
        width: MiniPlayerMetrics.height,
        height: MiniPlayerMetrics.height,
        child: Stack(
          alignment: Alignment.center,
          // 放大的唱片会超出这 44dp，交给胶囊的圆角去裁，
          // 别让 Stack 先按硬边切一刀把唱片边缘切平
          clipBehavior: Clip.none,
          children: <Widget>[
            // 放大到可见直径 44dp，多出来的透明边被胶囊的圆角裁掉
            Transform.scale(
              scale: _discScale,
              child: Image.asset(
                AppConstants.vinylDisc,
                width: MiniPlayerMetrics.height,
                height: MiniPlayerMetrics.height,
                filterQuality: FilterQuality.medium,
              ),
            ),
            ClipOval(
              child: SizedBox(
                width: _coverSize,
                height: _coverSize,
                child: CoverImage(
                  url: widget.item.artUri?.toString() ?? '',
                  logicalWidth: _coverSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
