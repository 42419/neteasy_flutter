import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../stores/home_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../viewmodels/home_block.dart';
import '../../viewmodels/playlist.dart';
import '../../viewmodels/rank.dart';

/// 首页（发现音乐）。
///
/// 主体由 `/homepage/block/page` 的 `blocks` 驱动，按 `blockCode` 选择渲染方式；
/// 不认识的区块、没有内容的区块直接不画，不留空白。
/// 排行榜和「我的歌单」是独立接口，按官方的位置插进区块之间。
///
/// 点击跳转暂未接入，卡片目前只负责展示。
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// 排行榜卡片的底色，按顺序循环。官方是绿/橙/蓝/紫几套。
  static const List<List<Color>> _rankPalettes = <List<Color>>[
    <Color>[Color(0xFF7BD3A8), Color(0xFF3BAF7A)],
    <Color>[Color(0xFFFFC46B), Color(0xFFF08C2E)],
    <Color>[Color(0xFF9EC5FF), Color(0xFF5B8DEF)],
    <Color>[Color(0xFFD3A8FF), Color(0xFF9A5BEF)],
  ];

  /// 播客节目行高（沿用旧值，未按新版截图校准）
  static const double _rowHeight = 68;

  /// 歌曲行高：官方「近期云村热播」实测 58dp，封面 48
  static const double _songRowHeight = 58;

  /// 有声书行高：官方实测 90dp，封面 64，文字占三行（标题 / 简介 / 分类+播放量）
  static const double _bookRowHeight = 90;

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
          Expanded(child: _buildBody(context, store)),
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

          for (final Widget section in sections)
            SliverToBoxAdapter(child: section),

          // 给阶段的悬浮迷你播放器留空间
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// 把服务端区块、排行榜、我的歌单排成官方的顺序：
  /// 推荐歌单 → 曲风歌曲 → 排行榜 → 我的歌单 → 雷达歌单 → 其余区块。
  /// 服务端没有的区块就跳过，排行榜和我的歌单找不到锚点时落在末尾。
  List<Widget> _buildSections(BuildContext context, HomeStore store) {
    final List<Widget> sections = <Widget>[];
    bool ranksAdded = false;
    bool mineAdded = false;

    void addRanks() {
      if (ranksAdded || store.ranks.isEmpty) {
        return;
      }
      ranksAdded = true;
      sections.add(_buildRankSection(store));
    }

    void addMine() {
      if (mineAdded || store.myPlaylists.isEmpty) {
        return;
      }
      mineAdded = true;
      sections.add(_buildMyPlaylistSection(context, store));
    }

    for (final HomeBlock block in store.blocks) {
      if (block.blockCode == HomeBlock.mgcPlaylist) {
        addRanks();
        addMine();
      }
      final Widget? widget = _buildBlock(context, block);
      if (widget != null) {
        sections.add(widget);
      }
      if (block.blockCode == HomeBlock.styleRcmd) {
        addRanks();
      }
    }
    addRanks();
    addMine();
    return sections;
  }

  // ---------- 区块 ----------

  /// 按 blockCode 选渲染方式；不认识或没内容返回 null（整块不画）。
  Widget? _buildBlock(BuildContext context, HomeBlock block) {
    if (block.isEmpty) {
      return null;
    }
    final Widget body;
    switch (block.blockCode) {
      case HomeBlock.playlistRcmd:
        // 官方推荐歌单卡不带播放量，只有播放键
        body = _buildCoverRow(context, block, showCount: false);
      case HomeBlock.mgcPlaylist:
      case HomeBlock.officialPlaylist:
      case HomeBlock.videoPlaylist:
        body = _buildCoverRow(context, block);
      case HomeBlock.voicelistRcmd:
        body = _buildCoverRow(
          context,
          block,
          showCount: false,
          showPlay: false,
        );
      case HomeBlock.styleRcmd:
      case HomeBlock.newAlbumNewSong:
        body = _buildSongPages(context, block);
      case HomeBlock.musicPodcastRcmd:
        body = _buildRowPages(
          context,
          block.creatives
              .expand((HomeCreative c) => c.resources)
              .map((HomeResource r) => _buildVoiceTile(context, r))
              .toList(),
          rowHeight: _rowHeight,
        );
      case HomeBlock.voicebookRcmd:
        if (block.books.isEmpty) {
          return null;
        }
        body = _buildRowPages(
          context,
          block.books.map((HomeBook b) => _buildBookTile(context, b)).toList(),
          rowHeight: _bookRowHeight,
        );
      default:
        return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (block.hasHeader)
          _buildSectionHeader(
            title: block.displayTitle,
            showMore: block.hasMore,
          ),
        body,
      ],
    );
  }

  /// 横向滑动的一排
  Widget _buildHorizontalList({
    required double height,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        itemCount: itemCount,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 10),
        itemBuilder: itemBuilder,
      ),
    );
  }

  /// 封面卡一排：歌单、热门播客
  Widget _buildCoverRow(
    BuildContext context,
    HomeBlock block, {
    bool showCount = true,
    bool showPlay = true,
  }) {
    return _buildHorizontalList(
      height: 200,
      itemCount: block.creatives.length,
      itemBuilder: (BuildContext context, int index) {
        final HomeCreative creative = block.creatives[index];
        final HomeResource? res = creative.primary;
        final String image = res != null && res.imageUrl.isNotEmpty
            ? res.imageUrl
            : creative.imageUrl;
        // 热门播客的 resources 是空的，名字只在 creative 上
        final String resName = res?.displayName ?? '';
        return _buildCoverCard(
          context,
          image: image,
          name: resName.isNotEmpty ? resName : creative.title,
          playCount: showCount ? (res?.playCount ?? 0) : 0,
          showPlay: showPlay,
        );
      },
    );
  }

  /// 一页三首歌：曲风推荐、新歌新碟。
  /// 和播客、有声书共用同一套分页：每张卡原本的 3 首歌拆成 3 行，3 行一页横向翻。
  Widget _buildSongPages(BuildContext context, HomeBlock block) {
    final List<Widget> tiles = <Widget>[
      for (final HomeCreative creative in block.creatives)
        for (final HomeResource song in creative.resources.take(3))
          _buildSongTile(context, song),
    ];
    // 区块里一首歌都没有时不占空白
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildRowPages(context, tiles, rowHeight: _songRowHeight);
  }

  /// 把一串条目按每 3 条一页横向铺开（歌曲、播客节目、有声书）。
  ///
  /// 几何照官方实测：页宽 = 屏幕宽 − 32，页内左 16 / 右 8，页与页之间**不留间隙**。
  /// 这样下一页的封面只在屏幕右缘露出约 16dp，三组宽度完全一致。
  Widget _buildRowPages(
    BuildContext context,
    List<Widget> tiles, {
    required double rowHeight,
  }) {
    final List<List<Widget>> pages = <List<Widget>>[];
    for (int i = 0; i < tiles.length; i += 3) {
      pages.add(tiles.sublist(i, i + 3 > tiles.length ? tiles.length : i + 3));
    }
    final double pageWidth =
        MediaQuery.sizeOf(context).width - AppTheme.pagePadding * 2;
    return SizedBox(
      height: rowHeight * 3,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: pages.length,
        itemBuilder: (BuildContext context, int index) => SizedBox(
          width: pageWidth,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.pagePadding,
              right: 8,
            ),
            child: Column(
              children: <Widget>[
                for (final Widget tile in pages[index])
                  SizedBox(height: rowHeight, child: tile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 排行榜 / 我的歌单 ----------

  Widget _buildRankSection(HomeStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeader(title: '排行榜', showMore: true),
        _buildHorizontalList(
          height: 200,
          itemCount: store.ranks.length,
          itemBuilder: (BuildContext context, int index) =>
              _buildRankCard(store.ranks[index], index),
        ),
      ],
    );
  }

  Widget _buildMyPlaylistSection(BuildContext context, HomeStore store) {
    final String title = store.nickname.isEmpty
        ? '我的歌单'
        : '${store.nickname}的歌单';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionHeader(title: title),
        _buildHorizontalList(
          height: 200,
          itemCount: store.myPlaylists.length,
          itemBuilder: (BuildContext context, int index) {
            final Playlist playlist = store.myPlaylists[index];
            return _buildCoverCard(
              context,
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

  /// 区块标题。箭头只在这个区块有「更多」入口时才画。
  Widget _buildSectionHeader({required String title, bool showMore = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        20,
        AppTheme.pagePadding,
        10,
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sectionTitle,
            ),
          ),
          if (showMore)
            const Icon(
              Icons.chevron_right_rounded,
              size: 25,
              color: AppTheme.textPrimary,
            ),
        ],
      ),
    );
  }

  // ---------- 卡片 ----------

  /// 封面卡：歌单、播客这种「一张图 + 标题」的方块。
  /// 左上播放量、右下播放键都按需显示。
  Widget _buildCoverCard(
    BuildContext context, {
    required String image,
    required String name,
    int playCount = 0,
    bool showPlay = true,
  }) {
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
                children: <Widget>[
                  Positioned.fill(child: _buildCover(context, image)),
                  if (playCount > 0)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusChip,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.headphones,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatCount(playCount),
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showPlay)
                    const Positioned(
                      right: 4,
                      bottom: 4,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle,
            ),
          ),
        ],
      ),
    );
  }

  /// 歌曲行：官方「近期云村热播」样式。
  /// 封面 48 / 歌名一行 / 标签 + 歌手 / 右侧实心播放三角。
  /// 标签（`subtitle`）是「超51%人收藏」这类文案，歌手要读 `artists`。
  Widget _buildSongTile(BuildContext context, HomeResource song) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 48,
            height: 48,
            child: _buildCover(context, song.imageUrl, logicalWidth: 48),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      song.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (song.isVip) ...<Widget>[
                    const SizedBox(width: 4),
                    SvgPicture.asset(AppConstants.vipBadge, height: 12),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: <Widget>[
                  if (song.subtitle.isNotEmpty) ...<Widget>[
                    Flexible(child: _buildTagChip(song.subtitle)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      song.artistLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.play_arrow_rounded,
          size: 26,
          color: AppTheme.iconPlay,
        ),
      ],
    );
  }

  /// 分类/标签小标签：透明底 + 蓝灰细描边（截图采样 #B6C3DD / #5975B2）。
  Widget _buildTagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.chipBorder, width: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          height: 1.2,
          color: AppTheme.chipText,
        ),
      ),
    );
  }

  /// 播客节目行：封面 / 标题（两行）/ 标签 + 所属播客
  Widget _buildVoiceTile(BuildContext context, HomeResource voice) {
    final String label = voice.labelTexts.isEmpty ? '' : voice.labelTexts.first;
    return _buildMediaTile(
      context,
      cover: voice.imageUrl,
      title: voice.displayName,
      chip: label,
      subtitle: voice.subtitle,
    );
  }

  /// 有声书行：官方三行——标题（两行）/ 灰色简介 / 分类标签 + 播放量，右侧评分。
  ///
  /// 评分在官方用的是自有字体，这里只用字号/字重/颜色近似，不追求字形一致。
  Widget _buildBookTile(BuildContext context, HomeBook book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 64,
            height: 64,
            child: _buildCover(context, book.coverUrl, logicalWidth: 64),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (book.desc.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  book.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppTheme.textDescription,
                  ),
                ),
              ],
              if (book.category.isNotEmpty ||
                  book.playCount.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    if (book.category.isNotEmpty) ...<Widget>[
                      _buildTagChip(book.category),
                      const SizedBox(width: 6),
                    ],
                    if (book.playCount.isNotEmpty) ...<Widget>[
                      const Icon(
                        Icons.play_arrow_outlined,
                        size: 12,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        book.playCount,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (book.score.isNotEmpty)
          // 与封面垂直居中，和官方一致
          SizedBox(
            height: 64,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                book.score,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 播客节目行：封面 56 + 两行标题 + 标签 + 所属播客。
  Widget _buildMediaTile(
    BuildContext context, {
    required String cover,
    required String title,
    String chip = '',
    String subtitle = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildCover(context, cover, logicalWidth: 56),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (chip.isNotEmpty || subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      if (chip.isNotEmpty) ...<Widget>[
                        Flexible(child: _buildTagChip(chip)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                // 榜名居中大字
                Center(
                  child: Text(
                    rank.name,
                    textAlign: .center,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 左上角播放量
                if (rank.playCount > 0)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.headphones,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          formatCount(rank.playCount),
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.1,
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
          // 卡片下方接前 3 首歌名，顿号连接
          Text(
            rank.trackLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle,
          ),
        ],
      ),
    );
  }

  /// 封面：走磁盘 + 内存两级缓存，滚动回来不会再请求一次。
  ///
  /// - 服务端返回的封面是 `http://` 开头，Android 默认拦明文，这里统一升到 https
  /// - [logicalWidth] 用于限制解码尺寸：150dp 的卡片没必要按原图 1000px 解码，
  ///   否则 ImageCache 很快被撑满、一滚动就开始淘汰重下
  Widget _buildCover(
    BuildContext context,
    String url, {
    double logicalWidth = 150,
  }) {
    final String normalized = _normalizeUrl(url);
    if (normalized.isEmpty) {
      return const ColoredBox(color: AppTheme.placeholder);
    }
    final int cacheWidth =
        (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
    return CachedNetworkImage(
      imageUrl: normalized,
      fit: BoxFit.cover,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (BuildContext context, String url) =>
          const ColoredBox(color: AppTheme.placeholder),
      errorWidget: (BuildContext context, String url, Object error) =>
          const ColoredBox(color: AppTheme.placeholder),
    );
  }

  String _normalizeUrl(String raw) {
    final String url = raw.trim();
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('http://')) {
      return 'https://${url.substring(7)}';
    }
    return url;
  }
}
