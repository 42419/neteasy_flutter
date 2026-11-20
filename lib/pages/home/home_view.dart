import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../api/ncm_repository.dart';
import '../../stores/daily_store.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/home_block.dart';
import '../../viewmodels/playlist.dart';
import '../daily/daily_recommend_page.dart';
import 'widgets/entry_cards.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/playlist_block.dart';
import 'widgets/rank_block.dart';
import 'widgets/section_parts.dart';
import 'widgets/song_block.dart';
import 'widgets/voice_block.dart';

/// 首页（发现音乐）。
///
/// 只做编排：顶部栏 + 入口卡 + 按 `blockCode` 分发的区块。
/// 具体卡片与行的实现都在 `widgets/` 下，这里不写样式细节。
///
/// 主体由 `/homepage/block/page` 的 `blocks` 驱动，不认识的、没内容的区块直接不画；
/// 排行榜和「我的歌单」走独立接口，按官方位置插进区块之间。
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeStore store = context.watch<HomeStore>();
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const HomeTopBar(),
          Expanded(child: _buildBody(context, store)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeStore store) {
    // 只有首次加载才整页转圈；下拉刷新时保留旧内容
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

    final List<Widget> sections = _buildSections(context, store);
    return RefreshIndicator(
      onRefresh: store.load,
      color: AppTheme.brand,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: EntryCards(
              entries: store.entries,
              leadImageUrl: store.dailyCover,
              onTap: (int index) => _openEntry(context, index),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
          for (final Widget section in sections)
            SliverToBoxAdapter(child: section),
          // 给悬浮迷你播放器留空间
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// 把服务端区块、排行榜、我的歌单排成官方的顺序：
  /// 推荐歌单 → 曲风歌曲 → 排行榜 → 我的歌单 → 雷达歌单 → 其余区块。
  /// 排行榜和我的歌单找不到锚点时落在末尾。
  List<Widget> _buildSections(BuildContext context, HomeStore store) {
    final List<Widget> sections = <Widget>[];
    bool ranksAdded = false;
    bool mineAdded = false;

    void addRanks() {
      if (ranksAdded || store.ranks.isEmpty) {
        return;
      }
      ranksAdded = true;
      sections.add(RankSection(ranks: store.ranks));
    }

    void addMine() {
      if (mineAdded || store.myPlaylists.isEmpty) {
        return;
      }
      mineAdded = true;
      sections.add(_buildMyPlaylistSection(store));
    }

    for (final HomeBlock block in store.blocks) {
      if (block.blockCode == HomeBlock.mgcPlaylist) {
        addRanks();
        addMine();
      }
      final Widget? section = _buildBlock(block);
      if (section != null) {
        sections.add(section);
      }
      if (block.blockCode == HomeBlock.styleRcmd) {
        addRanks();
      }
    }
    addRanks();
    addMine();
    return sections;
  }

  /// 按 blockCode 选渲染方式；不认识或没内容返回 null（整块不画）。
  Widget? _buildBlock(HomeBlock block) {
    if (block.isEmpty) {
      return null;
    }
    final Widget body;
    switch (block.blockCode) {
      case HomeBlock.playlistRcmd:
        // 官方推荐歌单卡不带播放量，只有播放键
        body = PlaylistRow(block: block, showCount: false);
      case HomeBlock.mgcPlaylist:
      case HomeBlock.officialPlaylist:
      case HomeBlock.videoPlaylist:
        body = PlaylistRow(block: block);
      case HomeBlock.voicelistRcmd:
        // 热门播客：卡片只有封面和名字，没有播放量与播放键
        body = PlaylistRow(block: block, showCount: false, showPlay: false);
      case HomeBlock.styleRcmd:
      case HomeBlock.newAlbumNewSong:
        body = SongBlock(block: block);
      case HomeBlock.musicPodcastRcmd:
        body = VoiceBlock(block: block);
      case HomeBlock.voicebookRcmd:
        body = BookBlock(block: block);
      default:
        return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (block.hasHeader)
          SectionHeader(title: block.displayTitle, showMore: block.hasMore),
        body,
      ],
    );
  }

  /// 入口卡目前只有第一张「每日推荐」有目标页，其余先不响应
  void _openEntry(BuildContext context, int index) {
    if (index != 0) {
      return;
    }
    final NcmRepository repo = context.read<NcmRepository>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChangeNotifierProvider<DailyStore>(
          create: (BuildContext context) => DailyStore(repo)..load(),
          child: const DailyRecommendPage(),
        ),
      ),
    );
  }

  Widget _buildMyPlaylistSection(HomeStore store) {
    final String title = store.nickname.isEmpty
        ? '我的歌单'
        : '${store.nickname}的歌单';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title: title),
        HorizontalList(
          height: 200,
          itemCount: store.myPlaylists.length,
          itemBuilder: (BuildContext context, int index) {
            final Playlist playlist = store.myPlaylists[index];
            return CoverCard(
              image: playlist.coverUrl,
              // 官方把「我喜欢的音乐」歌单统一显示成这个名字
              name: playlist.isLikedMusic ? '我喜欢的音乐' : playlist.name,
              showPlay: false,
            );
          },
        ),
      ],
    );
  }
}
