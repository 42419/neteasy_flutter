import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/vip_badge.dart';
import '../../constants/app_constants.dart';
import '../../stores/daily_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/song.dart';
import '../home/widgets/cover_image.dart';

/// 每日推荐页：首页「每日推荐」卡进入，数据来自 `/recommend/songs`。
///
/// 版式逐项量出来（406×904dp）：
/// 渐变头（顶栏 52 + 留白 60 + 日期 55 + 运势行 30）、动作栏 48、
/// 提示行 40、列表行 60。改数值前先对一遍截图。
class DailyRecommendPage extends StatelessWidget {
  const DailyRecommendPage({super.key});

  /// 顶栏高度（不含状态栏）
  static const double _topBarHeight = 52;

  /// 顶栏到日期之间的留白，压掉整片会挤在一起
  static const double _topGap = 60;

  @override
  Widget build(BuildContext context) {
    final DailyStore store = context.watch<DailyStore>();
    final bool failed = store.error != null && store.songs.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).background,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _Header(store: store)),
          if (failed)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorView(message: store.error!, onRetry: store.load),
            )
          else ...<Widget>[
            SliverToBoxAdapter(child: _ActionBar(store: store)),
            const SliverToBoxAdapter(child: _HintRow()),
            SliverList.builder(
              itemCount: store.songs.length,
              itemBuilder: (BuildContext context, int index) =>
                  _SongRow(song: store.songs[index]),
            ),
            // 给悬浮迷你播放器留位置
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}

/// 暖橙渐变头：返回 / 默认推荐·风格推荐 / 更多 / 日期 / 今日运势 / 历史日推
class _Header extends StatelessWidget {
  const _Header({required this.store});

  final DailyStore store;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String day = '${now.day}';
    final String month = now.month.toString().padLeft(2, '0');
    // 深色下渐变要落回页面底色，不能落到白
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const <Color>[
                  Color(0xFFF0A176),
                  Color(0xFFD9825B),
                  Color(0xFF8A5647),
                  Color(0xFF4A3230),
                  Color(0xFF221A18),
                  Color(0xFF151515),
                ]
              : const <Color>[
                  Color(0xFFFFB687),
                  Color(0xFFFFAB84),
                  Color(0xFFFDAB8E),
                  Color(0xFFFBC7BB),
                  Color(0xFFFEF7F5),
                  Color(0xFFFFFFFF),
                ],
          // 渐变到 210dp 左右才开始淡出，300dp 处与页面底色一致
          stops: const <double>[0, 0.42, 0.70, 0.84, 0.95, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: DailyRecommendPage._topBarHeight,
              child: Stack(
                children: <Widget>[
                  // 胶囊严格居中，不跟着左右按钮的宽度走
                  const Center(child: _Segment()),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        color: Colors.white,
                        tooltip: '返回',
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, size: 24),
                        color: Colors.white,
                        tooltip: '更多',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DailyRecommendPage._topGap),
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.pagePadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/$month',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                6,
                AppTheme.pagePadding,
                14,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '查看今日运势',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  const Spacer(),
                  _HistoryPill(onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 历史日推：半透明白胶囊 + VIP 徽章
class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '历史日推',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            const SizedBox(width: 5),
            SvgPicture.asset(AppConstants.vipBadge, height: 12),
          ],
        ),
      ),
    );
  }
}

/// 默认推荐 / 风格推荐 的胶囊切换：整条 200×32，选中半区是白色滑块
class _Segment extends StatelessWidget {
  const _Segment();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '默认推荐',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D2A22),
              ),
            ),
          ),
          const SizedBox(
            width: 100,
            child: Center(
              child: Text(
                '风格推荐',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 播放全部 / 换一批 / 多选
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.store});

  final DailyStore store;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 8, 12, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            const _BrandPlayButton(),
            const SizedBox(width: 10),
            Text(
              '播放全部',
              style: TextStyle(fontSize: 17, color: colors.textPrimary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: store.refreshing ? null : () => store.load(refresh: true),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: store.refreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Text(
                        '换一批',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 5),
            // 多选还没实现，先只放图标占位
            Image.asset(
              AppConstants.multiselectIcon,
              width: 25,
              height: 25,
              color: colors.iconPlay,
              colorBlendMode: BlendMode.srcIn,
            ),
          ],
        ),
      ),
    );
  }
}

/// 实心红圆 + 白色三角
class _BrandPlayButton extends StatelessWidget {
  const _BrandPlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppTheme.brand,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}

/// 「根据你的音乐口味生成，每日 6:00 更新」提示行
class _HintRow extends StatelessWidget {
  const _HintRow();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 8, 12, 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            '根据你的音乐口味生成，每日6:00更新',
            style: AppTheme.caption(colors).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// 列表行：40 封面 + 歌名 + 推荐语/歌手专辑 + MV 徽章（有才画）+ 更多。
///
/// 官方行里没有播放键——右边第一个图标就是 MV，容易认错。
class _SongRow extends StatelessWidget {
  const _SongRow({required this.song});

  final Song song;

  /// 行高，官方量出来就是 60
  static const double rowHeight = 60;

  /// VIP 标签红（比品牌红更偏玫）
  static const Color _vipColor = Color(0xFFFF3A3A);

  /// 推荐语：粉底红字
  static const Color _reasonBg = Color(0xFFFFE9E9);

  String get _meta {
    if (song.albumName.isEmpty) {
      return song.artist;
    }
    return '${song.artist} - ${song.albumName}';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: rowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: AppTheme.pagePadding, right: 16),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CoverImage(url: song.coverUrl, logicalWidth: 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      if (song.isVip) ...<Widget>[
                        const VipBadge(height: VipBadge.rowHeight),
                        const SizedBox(width: 4),
                      ],
                      if (song.reason.isNotEmpty) ...<Widget>[
                        _Badge(
                          text: song.reason,
                          color: _vipColor,
                          // 深色下用暗红底，粉底在黑夜模式里太刺眼
                          background: dark
                              ? const Color(0xFF3A2222)
                              : _reasonBg,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          _meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption(colors)
                              .copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (song.mvId > 0) ...<Widget>[
              // 有 MV 才画徽章：实测 19×17dp，右边距 16 接 ⋮
              Image.asset(
                AppConstants.mvIcon,
                height: 17,
                color: colors.textSecondary,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(width: 16),
            ],
            SizedBox(
              width: 24,
              height: 40,
              child: Center(
                child: Image.asset(
                  AppConstants.moreIcon,
                  width: 4,
                  height: 20,
                  color: colors.textSecondary,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 小标签：VIP 是实心红底白字，推荐语是粉底红字
class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, height: 1.2, color: color),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
