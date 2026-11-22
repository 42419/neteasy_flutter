import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/empty_hint.dart';
import '../../components/error_retry.dart';
import '../../components/pull_to_refresh.dart';
import '../../stores/profile_store.dart';
import '../../stores/session_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/playlist.dart';
import '../../viewmodels/profile_summary.dart';
import '../../viewmodels/user_profile.dart';
import '../login/login_view.dart';
import 'widgets/profile_action_rows.dart';
import 'widgets/profile_blur_backdrop.dart';
import 'widgets/profile_identity.dart';
import 'widgets/profile_list_tools.dart';
import 'widgets/profile_login_entry.dart';
import 'widgets/profile_playlist_row.dart';
import 'widgets/profile_quick_entries.dart';
import 'widgets/profile_record_row.dart';
import 'widgets/profile_tab_bar.dart';
import 'widgets/profile_top_bar.dart';

/// 「我的」页。
///
/// 结构：模糊头像背景 → 工具栏 → 头像 / 昵称 / 会员徽章 → 统计行 →
/// 快捷入口 → 三个标签（音乐 / 播客 / 笔记）→ 歌单列表。
///
/// 这里只做编排和两个页面级状态（选中的大标签、歌单小标签）：
/// 每一块 UI 都在 `widgets/` 下，滚动折叠靠订阅 [_scrollController]。
/// 目前只实现「音乐」标签；「播客」「笔记」点进去是占位提示。
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  /// 当前选中的标签：0 音乐 / 1 播客 / 2 笔记
  int _tab = 0;

  /// 音乐标签下的小标签：0 近期 / 1 创建 / 2 收藏
  int _listTab = 0;

  /// 滚动距离：顶部工具栏折叠和背景淡出都看它
  final ScrollController _scrollController = ScrollController();

  /// 超过这个偏移，工具栏中间换成「小头像 + 昵称」
  static const double _collapseOffset = 100;

  /// 模糊背景在这个距离内淡到透明
  static const double _fadeOffset = 220;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final SessionStore session = context.watch<SessionStore>();
    final ProfileStore store = context.watch<ProfileStore>();
    final ProfileSummary? data = store.data;

    if (!session.loggedIn && !session.restoring) {
      return SafeArea(child: _buildLoginEntry(context));
    }
    if (data == null) {
      if (store.error != null) {
        return SafeArea(
          child: ErrorRetry(
            message: store.error!,
            onRetry: store.load,
            style: AppTheme.caption(colors),
            spacing: 12,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    final UserProfile user = data.user;
    // 过滤 + 排序只在这里算一次，别放进 itemBuilder 里每行重算
    final List<Playlist> visiblePlaylists = _visiblePlaylists(data);
    return Stack(
      children: <Widget>[
        // 头像扩散模糊出来的背景；往上滚时淡出，让列表落到纯色底上
        if (user.avatarUrl.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: ProfileBlurBackdrop.height,
            child: AnimatedBuilder(
              animation: _scrollController,
              child: ProfileBlurBackdrop(avatarUrl: user.avatarUrl),
              builder: (BuildContext context, Widget? child) => Opacity(
                opacity: (1 - _scrollOffset / _fadeOffset).clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              // 工具栏常驻；是否折叠只看滚动距离
              AnimatedBuilder(
                animation: _scrollController,
                builder: (BuildContext context, Widget? child) => ProfileTopBar(
                  user: user,
                  collapsed: _scrollOffset > _collapseOffset,
                ),
              ),
              Expanded(
                child: PullToRefresh(
                  onRefresh: store.load,
                  builder: (BuildContext context, double extraTop) =>
                      _buildScrollView(
                        context,
                        data: data,
                        user: user,
                        playlists: visiblePlaylists,
                        extraTop: extraTop,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollView(
    BuildContext context, {
    required ProfileSummary data,
    required UserProfile user,
    required List<Playlist> playlists,
    required double extraTop,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      // 允许越界：下拉时内容才会真的跟着手指走，
      // 也才量得到负偏移喂给指示器
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: <Widget>[
        // 刷新悬停时撑住位置，松手与否都为 0
        SliverToBoxAdapter(child: SizedBox(height: extraTop)),
        SliverToBoxAdapter(
          child: ProfileIdentity(user: user, data: data),
        ),
        SliverToBoxAdapter(
          child: ProfileQuickEntries(onTapEntry: _onQuickEntry),
        ),
        // 标签栏吸顶：滚过头部后始终贴在工具栏下面
        SliverPersistentHeader(
          pinned: true,
          delegate: ProfilePinnedHeader(
            height: ProfileTabBar.height,
            child: ProfileTabBar(
              selected: _tab,
              onSelect: (int index) => setState(() => _tab = index),
            ),
          ),
        ),
        if (_tab == 0) ...<Widget>[
          SliverToBoxAdapter(
            child: ProfileListTools(
              data: data,
              selected: _listTab,
              onSelect: (int index) => setState(() => _listTab = index),
            ),
          ),
          SliverList.builder(
            itemCount: playlists.length,
            itemBuilder: (BuildContext context, int index) =>
                ProfilePlaylistRow(
                  playlist: playlists[index],
                  onHeartMode: () => _toast('心动模式暂未支持'),
                ),
          ),
          SliverToBoxAdapter(
            child: ProfileRecordRow(user: user, data: data),
          ),
          const SliverToBoxAdapter(child: ProfileActionRows()),
        ] else
          const SliverToBoxAdapter(
            child: EmptyHint(
              text: '播客 / 笔记暂未支持',
              padding: EdgeInsets.symmetric(vertical: 80),
            ),
          ),
        // extendBody 下 Scaffold 把底栏总高写进 MediaQuery 的 padding，
        // 用它留白，最后一行才不会被迷你播放器压住
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
        ),
      ],
    );
  }

  /// 未登录：保留原来的登录引导卡片
  Widget _buildLoginEntry(BuildContext context) {
    return ProfileLoginEntry(
      onLogin: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const LoginView(),
        ),
      ),
    );
  }

  /// 按小标签过滤：创建 = 自己建的（含「我喜欢的音乐」），收藏 = subscribed 为 true
  List<Playlist> _visiblePlaylists(ProfileSummary data) {
    switch (_listTab) {
      case 1:
        return data.playlists
            .where(
              (Playlist p) => p.creatorId == data.user.uid || !p.subscribed,
            )
            .toList();
      case 2:
        return data.playlists.where((Playlist p) => p.subscribed).toList();
      default:
        return data.playlists;
    }
  }

  /// 当前滚动偏移；还没挂上 clients 时按 0 算
  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  void _onQuickEntry(String label) => _toast('$label暂未支持');

  void _toast(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
  }
}
