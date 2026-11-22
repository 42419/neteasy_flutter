import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../pages/home/widgets/cover_image.dart';
import '../stores/player_store.dart';
import '../theme/app_theme.dart';

/// 底部迷你播放器：黑胶唱片封面 / 歌名 - 歌手 / 带进度环的播放键 / 播放列表。
///
/// 放在页面的 `bottomNavigationBar` 里，由 Scaffold 把内容区顶上去，
/// 不用各页再留空白。还没放过歌时高度为 0。
/// 在主页（底栏上方）直接用；在没有底栏的子页面里传 `safeBottom: true`，
/// 让它自己避开手势条。
///
/// 几何按真机截图取：胶囊 44dp 高、左右各 16dp 边距、整圆角；
/// 唱片 44dp 正好嵌在左端圆角里（圆角半径 = 唱片半径，所以贴边不露缝），
/// 封面是唱片的三分之二，压在唱片中间。
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key, this.safeBottom = false, this.scrimColor});

  final bool safeBottom;

  /// 底部渐隐的实色端。默认用主题里的 `scrim`（页面底色）；
  /// 挂在底部导航栏上面时要传导航栏的底色，让导航栏的背景顺着往上一路渐隐，
  /// 而不是在胶囊下面切出一条硬边。
  final Color? scrimColor;

  /// 胶囊高度，同时也是黑胶唱片的直径
  static const double height = 44;

  /// 唱片上盖的封面直径：截图量出来是 89/132 ≈ 三分之二
  static const double _coverSize = 30;

  /// 唱片素材自带一圈透明留白：只有中间 83% 是不透明的。
  /// 按 44dp 原样画，可见唱片只剩 36.6dp，黑环细得几乎看不出来，
  /// 所以放大到 1/0.83，让可见直径正好等于胶囊高度。
  static const double _discScale = 1 / 0.832;

  /// 封面右边到歌名的间距
  static const double _titleGap = 9;

  /// 左右两端的留白：左边让唱片贴着圆角，右边留 14 给队列图标
  static const double _sidePadding = 16;
  static const double _trailingPadding = 14;

  /// 上下留白
  static const double _gap = 8;

  /// 胶囊底边到屏幕底边的距离（官方截图 126px = 42dp）。
  /// 手势条本身已经占了一截，所以这里只补差额——按 8dp 硬留
  /// 会比官方贴得近 18dp。
  static const double _bottomDistance = 42;

  @override
  Widget build(BuildContext context) {
    final PlayerStore player = context.watch<PlayerStore>();
    final MediaItem? item = player.current;
    final AppColors colors = AppTheme.colorsOf(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final double bottomInset = safeBottom
        ? MediaQuery.paddingOf(context).bottom
        : 0;
    // 三键导航的 inset 比目标距离还大时，别算出负留白
    final double bottomGap = safeBottom
        ? math.max(_gap, _bottomDistance - bottomInset)
        : _gap;

    // 没有歌就彻底不占位置；有歌立刻出现。
    // 别用 AnimatedSize 做 0 → 60dp 的高度动画：页面被别的路由盖住时
    // TickerMode 是关的，动画推不动，回到这个页面就可能卡在 0 高度，
    // 看起来像「迷你播放器没了」。
    if (item == null) {
      return const SizedBox(width: double.infinity);
    }

    return Stack(
      children: <Widget>[
        // 底部渐隐：胶囊中线以下铺实色一直到屏幕底边，往上渐到透明，
        // 让列表从这一带淡出去（浅色下实色=页面底色，深色下比页面更暗）
        Positioned.fill(
          child: IgnorePointer(
            child: MiniPlayerScrim(
              color: scrimColor ?? colors.scrim,
              fadeHeight: _gap + height / 2,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            _sidePadding,
            _gap,
            _sidePadding,
            bottomGap + bottomInset,
          ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: <BoxShadow>[
                // 深色下投影只会糊成一团，压得很淡
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.28 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Row(
                children: <Widget>[
                  _Disc(item: item, playing: player.playing),
                  const SizedBox(width: _titleGap),
                  Expanded(child: _buildTitle(item, colors)),
                  _PlayButton(player: player, item: item, colors: colors),
                  const SizedBox(width: 2),
                  _QueueButton(colors: colors),
                  const SizedBox(width: _trailingPadding),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 歌名和歌手同字号，只靠颜色区分——截图里两段字高量出来是一样的
  Widget _buildTitle(MediaItem item, AppColors colors) {
    final String artist = item.artist ?? '';
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: item.title,
            style: TextStyle(fontSize: 15, color: colors.textPrimary),
          ),
          if (artist.isNotEmpty)
            TextSpan(
              text: ' - $artist',
              style: TextStyle(fontSize: 15, color: colors.textDescription),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 迷你播放器底下那层渐隐。
///
/// 中线以上从透明渐到实色、中线以下实色铺到屏幕底边，
/// 列表滑到这儿就淡出去，不会硬邦邦地被胶囊切断。
///
/// 单独抽出来是因为这里有个坑：Column 默认 `center` 是横向松约束，
/// 没有子节点的 `DecoratedBox` / `ColoredBox` 宽度会塌成 0——
/// 遮罩整条不画，但页面看起来一切正常，很难发现。必须 `stretch`。
class MiniPlayerScrim extends StatelessWidget {
  const MiniPlayerScrim({
    super.key,
    required this.color,
    required this.fadeHeight,
  });

  /// 实色端（浅色=页面底色，深色比页面更暗）
  final Color color;

  /// 从透明到实色的高度，也就是胶囊中线的位置
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: fadeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[color.withValues(alpha: 0), color],
              ),
            ),
          ),
        ),
        Expanded(child: ColoredBox(color: color)),
      ],
    );
  }
}

/// 黑胶唱片 + 压在上面的封面。
///
/// 播放时整体顺时针匀速转（封面跟着转，像真唱片），暂停就停在当前角度，
/// 再播从那儿接着转，不回到 0。
class _Disc extends StatefulWidget {
  const _Disc({required this.item, required this.playing});

  final MediaItem item;
  final bool playing;

  @override
  State<_Disc> createState() => _DiscState();
}

class _DiscState extends State<_Disc> with SingleTickerProviderStateMixin {
  /// 转一圈的时长。官方截图是静止帧，量不出转速，先给一个偏慢的值，
  /// 看着不像电风扇又不至于看不出在转
  static const Duration _turn = Duration(seconds: 20);

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
  void didUpdateWidget(_Disc oldWidget) {
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
        width: MiniPlayerBar.height,
        height: MiniPlayerBar.height,
        child: Stack(
          alignment: Alignment.center,
          // 放大的唱片会超出这 44dp，交给胶囊的圆角去裁，
          // 别让 Stack 先按硬边切一刀把唱片边缘切平
          clipBehavior: Clip.none,
          children: <Widget>[
            // 放大到可见直径 44dp，多出来的透明边被胶囊的圆角裁掉
            Transform.scale(
              scale: MiniPlayerBar._discScale,
              child: Image.asset(
                AppConstants.vinylDisc,
                width: MiniPlayerBar.height,
                height: MiniPlayerBar.height,
                filterQuality: FilterQuality.medium,
              ),
            ),
            ClipOval(
              child: SizedBox(
                width: MiniPlayerBar._coverSize,
                height: MiniPlayerBar._coverSize,
                child: CoverImage(
                  url: widget.item.artUri?.toString() ?? '',
                  logicalWidth: MiniPlayerBar._coverSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放 / 暂停键：外圈是播放进度，取地址或缓冲时换成转圈。
class _PlayButton extends StatelessWidget {
  const _PlayButton({
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
                            painter: _RingPainter(
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

/// 队列按钮。队列页还没做，先只占位不接跳转。
class _QueueButton extends StatelessWidget {
  const _QueueButton({required this.colors});

  final AppColors colors;

  /// SVG 的 viewBox 是 24，但图形只占中间 74%（3.36→21.11），
  /// 想要 17dp 的墨迹就得开 24dp 的画布——按 17 画出来只有 12.6dp。
  static const double _box = 24;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SvgPicture.asset(
            AppConstants.queueIcon,
            width: _box,
            height: _box,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

/// 播放进度环：灰色底槽 + 从 12 点顺时针的进度弧。
///
/// 进度为 0 时官方只剩一个圆头小点，弧形画不出来，单独补一个。
class _RingPainter extends CustomPainter {
  const _RingPainter({
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
