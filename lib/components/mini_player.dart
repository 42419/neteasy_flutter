import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../pages/home/widgets/cover_image.dart';
import '../stores/player_store.dart';
import '../theme/app_theme.dart';

/// 底部迷你播放器：圆形封面 / 歌名 - 歌手 / 带进度环的播放键 / 下一首。
///
/// 放在页面的 `bottomNavigationBar` 里，由 Scaffold 把内容区顶上去，
/// 不用各页再留空白。还没放过歌时高度为 0。
/// 在主页（底栏上方）直接用；在没有底栏的子页面里传 `safeBottom: true`，
/// 让它自己避开手势条。
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key, this.safeBottom = false});

  final bool safeBottom;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final PlayerStore player = context.watch<PlayerStore>();
    final MediaItem? item = player.current;
    final AppColors colors = AppTheme.colorsOf(context);
    final double bottomInset = safeBottom
        ? MediaQuery.paddingOf(context).bottom
        : 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: item == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: EdgeInsets.fromLTRB(12, 6, 12, 6 + bottomInset),
              child: Container(
                height: height,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CoverImage(
                          url: item.artUri?.toString() ?? '',
                          logicalWidth: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTitle(item, colors)),
                    _PlayButton(player: player, item: item, colors: colors),
                    const SizedBox(width: 4),
                    _TapIcon(
                      icon: Icons.skip_next_rounded,
                      color: colors.textPrimary,
                      onTap: player.next,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTitle(MediaItem item, AppColors colors) {
    final String artist = item.artist ?? '';
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: item.title,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
          if (artist.isNotEmpty)
            TextSpan(
              text: ' - $artist',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    final int totalMs = item.duration?.inMilliseconds ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: player.toggle,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: 32,
              height: 32,
              child: player.loading
                  // 不传 value：不定进度的转圈
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textPrimary,
                    )
                  : StreamBuilder<Duration>(
                      stream: player.position,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<Duration> snapshot,
                          ) {
                            final int posMs =
                                snapshot.data?.inMilliseconds ?? 0;
                            return CircularProgressIndicator(
                              value: totalMs > 0
                                  ? (posMs / totalMs).clamp(0.0, 1.0)
                                  : 0,
                              strokeWidth: 2,
                              color: colors.textPrimary,
                              backgroundColor: colors.divider,
                            );
                          },
                    ),
            ),
            Icon(
              player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TapIcon extends StatelessWidget {
  const _TapIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}
