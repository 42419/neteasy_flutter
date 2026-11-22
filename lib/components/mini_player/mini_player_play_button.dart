import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';

import '../../stores/player_store.dart';
import '../../theme/app_theme.dart';

/// 播放 / 暂停键：外圈是播放进度，取地址或缓冲时换成转圈。
class MiniPlayerPlayButton extends StatelessWidget {
  const MiniPlayerPlayButton({
    super.key,
    required this.player,
    required this.item,
    required this.colors,
  });

  final PlayerStore player;
  final MediaItem item;
  final AppColors colors;

  /// 进度环直径与线宽（截图 70px / 5px）
  static const double _ringSize = 24;
  static const double _stroke = 1.8;

  @override
  Widget build(BuildContext context) {
    final int totalMs = item.duration?.inMilliseconds ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: player.toggle,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: player.loading
                // 不传 value：不定进度的转圈
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircularProgressIndicator(
                      strokeWidth: _stroke,
                      color: colors.textPrimary,
                    ),
                  )
                : StreamBuilder<Duration>(
                    stream: player.position,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<Duration> snapshot,
                        ) {
                          final int posMs = snapshot.data?.inMilliseconds ?? 0;
                          final double progress = totalMs > 0
                              ? (posMs / totalMs).clamp(0.0, 1.0)
                              : 0;
                          return CustomPaint(
                            painter: MiniPlayerRingPainter(
                              progress: progress,
                              track: colors.progressTrack,
                              color: colors.textPrimary,
                              stroke: _stroke,
                            ),
                            child: Center(
                              child: Icon(
                                player.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 16,
                                color: colors.textPrimary,
                              ),
                            ),
                          );
                        },
                  ),
          ),
        ),
      ),
    );
  }
}

/// 播放进度环：灰色底槽 + 从 12 点顺时针的进度弧。
///
/// 进度为 0 时官方只剩一个圆头小点，弧形画不出来，单独补一个。
class MiniPlayerRingPainter extends CustomPainter {
  const MiniPlayerRingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, paint);

    if (progress < 0.01) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - radius),
        stroke / 2,
        Paint()..color = color,
      );
      return;
    }
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(MiniPlayerRingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
