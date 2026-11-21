import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../stores/profile_store.dart';
import '../../stores/session_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/playlist.dart';
import '../../viewmodels/profile_summary.dart';
import '../../viewmodels/user_profile.dart';
import '../login/login_view.dart';

/// 「我的」页。
///
/// 结构：模糊头像背景 → 工具栏 → 头像 / 昵称 / 会员徽章 → 统计行 →
/// 快捷入口 → 三个标签（音乐 / 播客 / 笔记）→ 歌单列表。
///
/// 目前只实现「音乐」标签；「播客」「笔记」点进去是占位提示。
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  /// 模糊背景的高度：铺到快捷入口下方，再渐变回页面底色
  static const double _headerHeight = 380;

  /// 头像直径（截图量出来 73dp）
  static const double _avatarSize = 73;

  /// SVIP 昵称的金色（截图上取到的亮部）
  static const Color _svipNameColor = Color(0xFFFEE7B9);

  /// 当前选中的标签：0 音乐 / 1 播客 / 2 笔记
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // 首帧之后再拉数据：登录态要先从 SessionStore 恢复
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileStore>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors colors = AppTheme.colorsOf(context);
    final SessionStore session = context.watch<SessionStore>();
    final ProfileStore store = context.watch<ProfileStore>();
    final ProfileSummary? data = store.data;

    if (!session.loggedIn && !session.restoring) {
      return SafeArea(child: _buildLoginEntry(context, theme, colors));
    }
    if (data == null) {
      if (store.error != null) {
        return SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(store.error!, style: AppTheme.caption(colors)),
                const SizedBox(height: 12),
                FilledButton(onPressed: store.load, child: const Text('重试')),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    final UserProfile user = data.user;
    return Stack(
      children: <Widget>[
        // 头像扩散模糊出来的背景；没有头像就退回纯色
        if (user.avatarUrl.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: _buildBlurredAvatar(user.avatarUrl, colors),
          ),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildTopBar(colors)),
              SliverToBoxAdapter(child: _buildIdentity(user, data, colors)),
              SliverToBoxAdapter(child: _buildQuickEntries(colors)),
              SliverToBoxAdapter(child: _buildTabs(colors)),
              if (_tab == 0) ...<Widget>[
                SliverToBoxAdapter(child: _buildListTools(data, colors)),
                SliverList.builder(
                  itemCount: data.playlists.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _buildPlaylistRow(data.playlists[index], colors),
                ),
                SliverToBoxAdapter(child: _buildRecordRow(user, colors)),
                SliverToBoxAdapter(child: _buildNewPlaylistRow(colors)),
              ] else
                SliverToBoxAdapter(child: _buildTabPlaceholder(colors)),
              // 给悬浮迷你播放器留空间
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ],
    );
  }

  /// 头像放大后高斯模糊，再压一层由浅到深的遮罩，向下过渡到页面底色
  Widget _buildBlurredAvatar(String url, AppColors colors) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              // 背景只需要一团颜色，取小图放大就够，省一次大图解码
              memCacheWidth: 120,
              httpHeaders: AppConstants.coverHeaders,
              errorWidget: (BuildContext context, String url, Object error) =>
                  const SizedBox.shrink(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  colors.background.withValues(alpha: dark ? 0.62 : 0.72),
                  colors.background.withValues(alpha: dark ? 0.86 : 0.90),
                  colors.background,
                ],
                stops: const <double>[0, 0.62, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部工具栏：菜单 / 添加状态 / 新建 / 搜索 / 更多
  ///
  /// 「+ 添加状态」必须落在屏幕正中。用 Expanded 居中会被左右按钮的宽度差带偏
  /// （左边 1 个、右边 3 个），所以整条用 Stack，三段各自对齐。
  Widget _buildTopBar(AppColors colors) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu_rounded, size: 25),
                  color: colors.textPrimary,
                  tooltip: '菜单',
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {},
              child: Text(
                '+ 添加状态',
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 26),
                  color: colors.textPrimary,
                  tooltip: '新建',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, size: 24),
                  color: colors.textPrimary,
                  tooltip: '搜索',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded, size: 24),
                  color: colors.textPrimary,
                  tooltip: '更多',
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 头像、昵称、会员徽章、性别与徽章数、四项统计
  Widget _buildIdentity(
    UserProfile user,
    ProfileSummary data,
    AppColors colors,
  ) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        _buildAvatar(user, colors),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  // SVIP 昵称是金色，普通用户和 VIP 都是白色
                  color: data.svipActive ? _svipNameColor : colors.textPrimary,
                ),
              ),
            ),
            if (data.vipLabel.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              _buildVipBadge(data),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (user.gender != 0) ...<Widget>[
              SvgPicture.asset(
                user.isFemale
                    ? 'assets/icons/profile/gender_female.svg'
                    : 'assets/icons/profile/gender_male.svg',
                width: 11,
                height: 11,
                colorFilter: ColorFilter.mode(
                  user.isFemale
                      ? const Color(0xFFFF6B9A)
                      : const Color(0xFF5AA8FF),
                  BlendMode.srcIn,
                ),
              ),
              Text(' · ', style: AppTheme.caption(colors)),
            ],
            Icon(
              Icons.workspace_premium_outlined,
              size: 14,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text('${data.badgeCount}枚徽章', style: AppTheme.caption(colors)),
          ],
        ),
        const SizedBox(height: 18),
        _buildStats(user, data, colors),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvatar(UserProfile user, AppColors colors) {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: <BoxShadow>[
          // 官方头像外面有一圈很淡的白光，别调太亮，否则糊成一坨
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.14),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: user.avatarUrl.isEmpty
            ? ColoredBox(
                color: colors.placeholder,
                child: Icon(Icons.person, color: colors.textTertiary),
              )
            : CachedNetworkImage(
                imageUrl: user.avatarUrl,
                fit: BoxFit.cover,
                memCacheWidth: 240,
                httpHeaders: AppConstants.coverHeaders,
                errorWidget: (BuildContext context, String url, Object error) =>
                    ColoredBox(
                      color: colors.placeholder,
                      child: Icon(Icons.person, color: colors.textTertiary),
                    ),
              ),
      ),
    );
  }

  /// 昵称旁的会员徽章：直接用整套等级图标（52×16，按高度 16 显示）
  Widget _buildVipBadge(ProfileSummary data) {
    final String kind = data.svipActive ? 'svip' : 'vip';
    // 图标只做到 7 级，更高的等级先按 7 显示
    final int level = data.vipLevel.clamp(1, 7);
    return SvgPicture.asset(
      'assets/icons/vip/level/$kind$level.svg',
      height: 16,
    );
  }

  /// 「3 关注  1 粉丝  Lv.9  974 小时」
  Widget _buildStats(UserProfile user, ProfileSummary data, AppColors colors) {
    Widget item(String value, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          if (label.isNotEmpty) ...<Widget>[
            const SizedBox(width: 3),
            Text(label, style: AppTheme.caption(colors)),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        item('${user.follows}', '关注'),
        const SizedBox(width: 18),
        item('${user.followeds}', '粉丝'),
        const SizedBox(width: 18),
        item('Lv.${user.level}', ''),
        const SizedBox(width: 18),
        item('${data.listenHours}', '小时'),
      ],
    );
  }

  /// 快捷入口：最近 / 本地 / 网盘 / 云贝 + 右侧宫格（音乐应用页）
  Widget _buildQuickEntries(AppColors colors) {
    const List<(String, String)> entries = <(String, String)>[
      ('assets/icons/profile/recent.svg', '最近'),
      ('assets/icons/profile/local.svg', '本地'),
      ('assets/icons/profile/cloud.svg', '网盘'),
      ('assets/icons/profile/yunbei.svg', '云贝'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 0, 12, 0),
      child: Row(
        children: <Widget>[
          for (final (String asset, String label) in entries) ...<Widget>[
            Expanded(
              child: _buildQuickChip(
                asset: asset,
                label: label,
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _buildQuickChip(colors: colors, square: true),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    String? asset,
    String label = '',
    required AppColors colors,
    bool square = false,
  }) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _toast('${label.isEmpty ? '音乐应用' : label}暂未支持'),
      child: Container(
        height: 40,
        width: square ? 40 : null,
        decoration: BoxDecoration(
          // 深色下用 8% 白，浅色下用 5% 黑，都能浮在模糊背景上
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (asset != null)
              SvgPicture.asset(
                asset,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  colors.textPrimary,
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: colors.textPrimary,
              ),
            if (label.isNotEmpty) ...<Widget>[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 三个标签：音乐 / 播客 / 笔记
  Widget _buildTabs(AppColors colors) {
    const List<String> labels = <String>['音乐', '播客', '笔记'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        22,
        AppTheme.pagePadding,
        0,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: <Widget>[
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: i == _tab
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i == _tab
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 18,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: i == _tab
                            ? colors.textPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 「近期  创建²  收藏²」+ 右侧排序按钮
  Widget _buildListTools(ProfileSummary data, AppColors colors) {
    Widget tab(String label, int count) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.2,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        18,
        AppTheme.pagePadding,
        10,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.bookmark_border_rounded,
            size: 16,
            color: colors.textPrimary,
          ),
          const SizedBox(width: 4),
          tab('近期', 0),
          const SizedBox(width: 22),
          tab('创建', data.createdPlaylists),
          const SizedBox(width: 22),
          tab('收藏', data.collectedPlaylists),
          const Spacer(),
          Icon(Icons.tune_rounded, size: 18, color: colors.textSecondary),
        ],
      ),
    );
  }

  /// 歌单行：48 封面 + 名称 + 副标题；「我喜欢的音乐」右侧带「心动模式」
  Widget _buildPlaylistRow(Playlist playlist, AppColors colors) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _buildCover(playlist.coverUrl, colors),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      playlist.isLikedMusic ? '我喜欢的音乐' : playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      playlist.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (playlist.isLikedMusic) ...<Widget>[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toast('心动模式暂未支持'),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 13,
                          color: colors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '心动模式',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 「听歌排行」入口：图标 + 标题 + 累计听歌数，右侧「置顶」
  Widget _buildRecordRow(UserProfile user, AppColors colors) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(4),
              ),
              child: user.avatarUrl.isEmpty
                  ? Icon(Icons.bar_chart_rounded, color: colors.textSecondary)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _buildCover(user.avatarUrl, colors),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '听歌排行',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (user.recordPrivate) ...<Widget>[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: colors.textTertiary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '累计听歌${user.listenSongs}首',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text('置顶', style: AppTheme.caption(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPlaylistRow(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        10,
        AppTheme.pagePadding,
        0,
      ),
      child: Text('新建歌单', style: AppTheme.caption(colors)),
    );
  }

  Widget _buildTabPlaceholder(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Text('播客 / 笔记暂未支持', style: AppTheme.caption(colors)),
      ),
    );
  }

  Widget _buildCover(String url, AppColors colors) {
    if (url.isEmpty) {
      return ColoredBox(color: colors.placeholder);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 150,
      httpHeaders: AppConstants.coverHeaders,
      errorWidget: (BuildContext context, String url, Object error) =>
          ColoredBox(color: colors.placeholder),
    );
  }

  /// 未登录：保留原来的登录引导卡片
  Widget _buildLoginEntry(
    BuildContext context,
    ThemeData theme,
    AppColors colors,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        24,
      ),
      children: <Widget>[
        Text(
          '我的',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.placeholder,
                child: Icon(Icons.person, size: 34, color: colors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                '登录网易云账号',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '登录后可看每日推荐、我的歌单与收藏',
                textAlign: TextAlign.center,
                style: AppTheme.caption(colors),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const LoginView(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    minimumSize: const Size(64, 44),
                  ),
                  child: const Text('扫码登录'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toast(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
  }
}
