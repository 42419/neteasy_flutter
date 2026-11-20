import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/daily_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/song.dart';
import '../home/widgets/cover_image.dart';

/// 每日推荐页：首页「每日推荐」卡进入，数据来自 `/recommend/songs`。
///
/// 结构照官方：橙色渐变头（日期 + 默认/风格切换 + 历史日推）、
/// 播放全部与换一批、口味提示、30 首列表。
class DailyRecommendPage extends StatelessWidget {
  const DailyRecommendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DailyStore store = context.watch<DailyStore>();
    final bool failed = store.error != null && store.songs.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
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
            // 给悬浮播放器留位置
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}

/// 橙色渐变头：返回 / 二级切换 / 更多 / 日期 / 今日运势 / 历史日推
class _Header extends StatelessWidget {
  const _Header({required this.store});

  final DailyStore store;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String day = '${now.day}';
    final String month = now.month.toString().padLeft(2, '0');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF5A15E),
            Color(0xFFFBC79B),
            Color(0xFFFFF6F0),
            Colors.white,
          ],
          stops: <double>[0, 0.45, 0.82, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 44,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 22),
                    color: Colors.white,
                    tooltip: '返回',
                  ),
                  const Spacer(),
                  const _Segment(),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, size: 22),
                    color: Colors.white,
                    tooltip: '更多',
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.pagePadding,
                top: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' /$month',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                8,
                AppTheme.pagePadding,
                18,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '查看今日运势',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          '历史日推',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.lock,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 默认推荐 / 风格推荐 的胶囊切换（风格推荐暂无内容）
class _Segment extends StatelessWidget {
  const _Segment();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              '默认推荐',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '风格推荐',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 播放全部 / 换一批
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.store});

  final DailyStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        14,
        AppTheme.pagePadding,
        6,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.play_circle_fill_rounded,
            size: 28,
            color: AppTheme.brand,
          ),
          const SizedBox(width: 6),
          const Text(
            '播放全部',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: store.refreshing ? null : () => store.load(refresh: true),
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.divider, width: 0.8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: store.refreshing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Text(
                      '换一批',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.low_priority,
            size: 22,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// 「根据你的音乐口味生成」提示行
class _HintRow extends StatelessWidget {
  const _HintRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        2,
        AppTheme.pagePadding,
        8,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            '根据你的音乐口味生成，每日 6:00 更新',
            style: AppTheme.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 列表行：封面 / 歌名 / VIP+推荐语+歌手专辑 / 播放与更多
class _SongRow extends StatelessWidget {
  const _SongRow({required this.song});

  final Song song;

  /// VIP 标签的红，与品牌红区分开（官方这个更偏玫红）
  static const Color _vipColor = Color(0xFFE54545);

  /// 推荐语标签的橙
  static const Color _reasonColor = Color(0xFFE2703A);

  String get _meta {
    if (song.albumName.isEmpty) {
      return song.artist;
    }
    return '${song.artist} - ${song.albumName}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 10,
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CoverImage(url: song.coverUrl, logicalWidth: 48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    if (song.isVip) ...<Widget>[
                      const _MiniTag(text: 'VIP', color: _vipColor),
                      const SizedBox(width: 4),
                    ],
                    if (song.reason.isNotEmpty) ...<Widget>[
                      _MiniTag(text: song.reason, color: _reasonColor),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        _meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.play_circle_outline,
            size: 24,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.more_vert, size: 20, color: AppTheme.textTertiary),
        ],
      ),
    );
  }
}

/// 描边小标签（VIP / 推荐语）
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 9, height: 1.25, color: color),
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
