import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/player_store.dart';
import '../../theme/app_theme.dart';
import 'mini_player_disc.dart';
import 'mini_player_play_button.dart';
import 'mini_player_queue_button.dart';
import 'mini_player_scrim.dart';

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
///
/// 各块在 `components/mini_player/` 下：唱片、播放键、队列键、底部渐隐。
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key, this.safeBottom = false, this.scrimColor});

  final bool safeBottom;

  /// 底部渐隐的实色端。默认用主题里的 `scrim`（页面底色）；
  /// 挂在底部导航栏上面时要传导航栏的底色，让导航栏的背景顺着往上一路渐隐，
  /// 而不是在胶囊下面切出一条硬边。
  final Color? scrimColor;

  /// 胶囊高度，同时也是黑胶唱片的直径
  static const double height = 44;

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
                BoxShadow(
                  color: colors.floatingShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Row(
                children: <Widget>[
                  MiniPlayerDisc(item: item, playing: player.playing),
                  const SizedBox(width: _titleGap),
                  Expanded(child: _buildTitle(item, colors)),
                  MiniPlayerPlayButton(
                    player: player,
                    item: item,
                    colors: colors,
                  ),
                  const SizedBox(width: 2),
                  MiniPlayerQueueButton(colors: colors),
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
