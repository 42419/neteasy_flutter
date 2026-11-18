import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/playlist.dart';
import '../../viewmodels/rank.dart';
import '../../viewmodels/song.dart';

/// 首页（发现音乐）。
///
/// 只做「推荐」这一个二级 tab：顶部六个 tab 只改选中态，其余内容留到后续阶段。
/// 后端没有对应路由的模块用占位块顶住官方位置，接口补齐后直接替换成真实区块。
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// 排行榜卡片的底色，按顺序循环。官方是绿/橙/蓝/紫几套。
  static const List<List<Color>> _rankPalettes = <List<Color>>[
    <Color>[Color(0xFF7BD3A8), Color(0xFF3BAF7A)],
    <Color>[Color(0xFFFFC46B), Color(0xFFF08C2E)],
    <Color>[Color(0xFF9EC5FF), Color(0xFF5B8DEF)],
    <Color>[Color(0xFFD3A8FF), Color(0xFF9A5BEF)],
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final HomeStore store = context.watch<HomeStore>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          _buildTopBar(theme, scheme),
          Expanded(child: _buildBody(store, theme, scheme)),
        ],
      ),
    );
  }

  // ---------- 顶部栏 ----------

  Widget _buildTopBar(ThemeData theme, ColorScheme scheme) {
    return SizedBox(
      height: AppTheme.tabBarHeight,
      child: Row(
        crossAxisAlignment: .center,
        children: <Widget>[
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, size: 24),
            color: AppTheme.textPrimary,
            tooltip: '菜单',
          ),
          Expanded(
            child: SizedBox.expand(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < AppConstants.homeTabs.length; i++)
                    Expanded(
                      child: _buildTabItem(
                        label: AppConstants.homeTabs[i],
                        selected: i == AppConstants.homeDefaultTab,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 24),
            color: AppTheme.textPrimary,
            tooltip: '搜索',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String label, required bool selected}) {
    return Transform.translate(
      offset: const Offset(0, 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? AppTheme.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 主体 ----------

  Widget _buildBody(HomeStore store, ThemeData theme, ColorScheme scheme) {
    if (store.loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final String? error = store.error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: store.load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: store.load,
      color: AppTheme.brand,
      child: CustomScrollView(
        slivers: <Widget>[
          // 三张入口大卡：官方是运营图，这里没有图源，用渐变顶住
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  8,
                  AppTheme.pagePadding,
                  0,
                ),
                children: <Widget>[
                  _buildEntryCard(
                    title: '每日推荐',
                    subtitle: '今日限定好歌推荐',
                    colors: const <Color>[Color(0xFF4A4A52), Color(0xFF23232A)],
                  ),
                  const SizedBox(width: 8),
                  _buildEntryCard(
                    title: '榜单推荐',
                    subtitle: '云音乐官方 top 排...',
                    colors: const <Color>[Color(0xFFFF6B6B), Color(0xFFD63B3B)],
                  ),
                  const SizedBox(width: 8),
                  _buildEntryCard(
                    title: '心动模式',
                    subtitle: '红心歌曲和相似歌单',
                    colors: const <Color>[Color(0xFF3E5AA8), Color(0xFF23335F)],
                  ),
                  const SizedBox(width: 8),
                  _buildEntryCard(
                    title: '雷达歌单',
                    subtitle: '反复聆听你爱的歌',
                    colors: const <Color>[Color(0xFF2E1559), Color(0xFF050C20)],
                  ),
                  const SizedBox(width: 8),
                  _buildEntryCard(
                    title: '漫游',
                    subtitle: '多样频道无限畅听',
                    colors: const <Color>[Color(0xFF91A83E), Color(0xFF5F5523)],
                  ),
                  const SizedBox(width: 8),
                  _buildEntryCard(
                    title: '相似歌曲',
                    subtitle: '从你喜欢的歌听起',
                    colors: const <Color>[Color(0xFF3EA888), Color(0xFF235F31)],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),

          if (store.recommended.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: _buildSectionHeader(title: '推荐歌单')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  itemCount: store.recommended.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int index) =>
                      _buildPlaylistCard(store.recommended[index]),
                ),
              ),
            ),
          ],

          // 后端没有对应路由的模块，按官方位置占位
          SliverToBoxAdapter(
            child: _buildMissingSection(
              title: '近期云村热播',
              hint: AppConstants.pendingCloudVillage,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildMissingSection(
              title: '说唱 | 电子 | 摇滚 热门精选',
              hint: AppConstants.pendingHotGenre,
            ),
          ),

          if (store.ranks.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: _buildSectionHeader(title: '排行榜')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  itemCount: store.ranks.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int index) =>
                      _buildRankCard(store.ranks[index], index),
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: _buildMissingSection(
              title: '选择你喜欢的艺人，为你定制歌单',
              hint: AppConstants.pendingArtist,
            ),
          ),
          if (store.loggedIn)
            SliverToBoxAdapter(
              child: _buildMissingSection(
                title: '我的雷达歌单',
                hint: AppConstants.pendingRadar,
              ),
            ),

          if (store.daily.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: '每日推荐',
                trailing: '${store.daily.length} 首',
              ),
            ),
            SliverList.builder(
              itemCount: store.daily.length,
              itemBuilder: (BuildContext context, int index) =>
                  _buildSongRow(store.daily[index], index),
            ),
          ],

          SliverToBoxAdapter(
            child: _buildMissingSection(
              title: '根据你听过的热门节目推荐',
              hint: AppConstants.pendingProgram,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildMissingSection(
              title: 'SVIP 专享有声书免费听',
              hint: AppConstants.pendingVoiceList,
            ),
          ),

          // 给阶段的悬浮迷你播放器留空间
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ---------- 区块 ----------

  Widget _buildSectionHeader({required String title, String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        10,
      ),
      child: Row(
        children: <Widget>[
          Text(title, style: AppTheme.sectionTitle),
          const Icon(
            Icons.chevron_right_rounded,
            size: 25,
            color: AppTheme.textPrimary,
          ),
          const Spacer(),
          if (trailing != null) Text(trailing, style: AppTheme.caption),
        ],
      ),
    );
  }

  /// 后端还没有对应接口的模块占位：标题照抄官方文案，中间一行说明缺什么接口。
  Widget _buildMissingSection({required String title, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeader(title: title, trailing: '待接入'),
        SizedBox(
          height: 88,
          child: Center(child: Text(hint, style: AppTheme.caption)),
        ),
      ],
    );
  }

  // ---------- 卡片 ----------

  Widget _buildEntryCard({
    required String title,
    required String subtitle,
    required List<Color> colors,
  }) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // 底部压暗，保证文字可读
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const <double>[0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 12,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[_buildCover(playlist.coverUrl)],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            playlist.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(Rank rank, int index) {
    final List<Color> colors = _rankPalettes[index % _rankPalettes.length];
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 12,
                  top: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        rank.head,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        rank.tail,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 3,
                  bottom: 3,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 33,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rank.updateFrequency.isEmpty ? rank.name : rank.updateFrequency,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildSongRow(Song song, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: AppTheme.caption.copyWith(
                fontSize: 13,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _buildCover(song.coverUrl),
            ),
          ),
          const SizedBox(width: 10),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  /// 封面：先给底色再淡入，列表滚动时不闪白
  Widget _buildCover(String url) {
    if (url.isEmpty) {
      return const ColoredBox(color: AppTheme.placeholder);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder:
          (BuildContext context, Widget child, int? frame, bool wasSyncLoaded) {
            if (wasSyncLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: child,
            );
          },
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) => const ColoredBox(color: AppTheme.placeholder),
    );
  }
}
