import 'package:material_ui/material_ui.dart';

import '../../data/api_client.dart';
import '../../data/home_repository.dart';
import '../../models/home_models.dart';
import '../../theme/tokens.dart';

/// 首页（发现音乐）。
///
/// 当前只做「推荐」这一个二级 tab：顶部六个 tab 是静态结构，切换只改选中态，
/// 其余五个 tab 的内容留给后续阶段。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = ['心动', '推荐', '音乐', '播客', '听书', '福利'];
  static const _activeTab = 1;

  final ApiClient _api = ApiClient();
  late final HomeRepository _repo = HomeRepository(_api);

  bool _loading = true;
  String? _error;
  List<Playlist> _recommended = const [];
  List<Rank> _ranks = const [];
  List<Song> _daily = const [];
  int? _uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recommended = await _repo.recommendPlaylists(limit: 6);
      final ranks = await _repo.toplists();

      // 登录态是附加信息：失败不影响首页主体
      int? uid;
      var daily = const <Song>[];
      try {
        uid = await _repo.currentUid();
        if (uid != null) daily = await _repo.dailySongs();
      } catch (_) {
        uid = null;
      }

      if (!mounted) return;
      setState(() {
        _recommended = recommended;
        _ranks = ranks;
        _uid = uid;
        _daily = daily;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(tabs: _tabs, activeIndex: _activeTab),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomArea(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Tokens.brand,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 178,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  Tokens.gutter,
                  8,
                  Tokens.gutter,
                  0,
                ),
                children: const [
                  _EntryCard(
                    title: '每日推荐',
                    subtitle: '今日限定好歌推荐',
                    colors: [Color(0xFF4A4A52), Color(0xFF23232A)],
                  ),
                  SizedBox(width: 8),
                  _EntryCard(
                    title: '榜单推荐',
                    subtitle: '云音乐官方 top 排...',
                    colors: [Color(0xFFFF6B6B), Color(0xFFD63B3B)],
                  ),
                  SizedBox(width: 8),
                  _EntryCard(
                    title: '心动模式',
                    subtitle: '红心歌曲和相似歌单',
                    colors: [Color(0xFF3E5AA8), Color(0xFF23335F)],
                  ),
                ],
              ),
            ),
          ),

          if (_recommended.isNotEmpty) ...[
            const SliverToBoxAdapter(child: _SectionHeader(title: '推荐歌单')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 186,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.gutter,
                  ),
                  itemCount: _recommended.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) =>
                      _PlaylistCard(playlist: _recommended[i]),
                ),
              ),
            ),
          ],

          if (_ranks.isNotEmpty) ...[
            const SliverToBoxAdapter(child: _SectionHeader(title: '排行榜')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.gutter,
                  ),
                  itemCount: _ranks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _RankCard(rank: _ranks[i], index: i),
                ),
              ),
            ),
          ],

          if (_daily.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '每日推荐',
                trailing: '${_daily.length} 首',
              ),
            ),
            SliverList.builder(
              itemCount: _daily.length,
              itemBuilder: (_, i) => _SongRow(song: _daily[i], index: i),
            ),
          ],

          if (_uid != null && _daily.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '已登录，但每日推荐没有返回数据',
                  style: Tokens.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 给悬浮迷你播放器 + 底部导航留出空间
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.tabs, required this.activeIndex});

  final List<String> tabs;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Tokens.tabBarHeight,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, size: 24),
            color: Tokens.textPrimary,
            tooltip: '菜单',
          ),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabItem(label: tabs[i], selected: i == activeIndex),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 24),
            color: Tokens.textPrimary,
            tooltip: '搜索',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Tokens.textPrimary : Tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        // 选中指示器：20×3 的圆角短线
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: selected ? Tokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 20, Tokens.gutter, 10),
      child: Row(
        children: [
          Text(title, style: Tokens.sectionTitle),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: Tokens.textSecondary,
          ),
          const Spacer(),
          if (trailing != null) Text(trailing!, style: Tokens.caption),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 底部压暗，保证文字可读（对应官方的渐变蒙版）
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            right: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
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
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 12,
            bottom: 12,
            child: Icon(
              Icons.play_circle_outline,
              size: 28,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkCover(url: playlist.coverUrl),
                  if (playlist.playCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _PlayCountBadge(count: playlist.playCount),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            playlist.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Tokens.cardTitle,
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.index});

  final Rank rank;
  final int index;

  static const _palettes = [
    [Color(0xFF7BD3A8), Color(0xFF3BAF7A)],
    [Color(0xFFFFC46B), Color(0xFFF08C2E)],
    [Color(0xFF9EC5FF), Color(0xFF5B8DEF)],
    [Color(0xFFD3A8FF), Color(0xFF9A5BEF)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[index % _palettes.length];
    // 官方把榜单名竖向排在左侧：「新歌榜」→「新歌」+「榜」
    final name = rank.name;
    final head = name.length > 2 ? name.substring(0, 2) : name;
    final tail = name.length > 2 ? name.substring(2) : '';

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radiusCard),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        head,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        tail,
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
                  right: 10,
                  bottom: 10,
                  child: Icon(
                    Icons.play_arrow,
                    size: 22,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rank.updateFrequency.isEmpty ? rank.name : rank.updateFrequency,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tokens.caption,
          ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({required this.song, required this.index});

  final Song song;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.gutter,
        vertical: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: Tokens.caption.copyWith(
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _NetworkCover(url: song.coverUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.play_arrow, size: 20, color: Tokens.textTertiary),
        ],
      ),
    );
  }
}

class _PlayCountBadge extends StatelessWidget {
  const _PlayCountBadge({required this.count});

  final int count;

  String get _text {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 10, color: Colors.white),
          const SizedBox(width: 1),
          Text(
            _text,
            style: const TextStyle(
              fontSize: 10,
              height: 1.1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkCover extends StatelessWidget {
  const _NetworkCover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const ColoredBox(color: Color(0xFFE6E9EE));
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 列表里滚动时避免整块闪白：先给底色，再淡入
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: child,
        );
      },
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE6E9EE)),
    );
  }
}

/// 底部：悬浮迷你播放器 + 底部导航。当前是静态外壳，播放链路在阶段 3 接入。
class _BottomArea extends StatelessWidget {
  const _BottomArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Tokens.bottomNavHeight,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.music_note_outlined,
                label: '发现',
                selected: true,
              ),
              _BottomNavItem(icon: Icons.forum_outlined, label: '云村'),
              _BottomNavItem(icon: Icons.person_outline, label: '我的'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Tokens.textPrimary : Tokens.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
