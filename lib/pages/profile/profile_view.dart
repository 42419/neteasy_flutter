import 'package:flutter/services.dart' show SystemUiOverlayStyle;
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
/// 结构：深色模糊头像背景 → 工具栏 → 头像 / 昵称 / 会员徽章 → 统计行 →
/// 快捷入口 → 白色圆角面板（三个标签：音乐 / 播客 / 笔记，下面是歌单列表）。
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

  /// 滚动距离：模糊背景平移、顶部工具栏折叠与变色都看它
  final ScrollController _scrollController = ScrollController();

  /// 下拉刷新悬停时内容被垫下去的距离。背景是固定在滚动视图后面的，
  /// 要把这段也算进平移量，否则内容被推下去、背景留在原地，头部下沿会露出一条页面底色
  final ValueNotifier<double> _extraTop = ValueNotifier<double>(0);

  /// 超过这个偏移，工具栏中间换成「小头像 + 昵称」
  static const double _collapseOffset = 100;

  /// 状态栏图标：压在深色头部上用浅色（白）图标，头部滚走后浅色主题换深色图标。
  /// 只设状态栏，导航栏不动——所以不用 `SystemUiOverlayStyle.light/dark`，
  /// 它们会把导航栏也一并改成黑 / 白。
  static const SystemUiOverlayStyle _lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: AppTheme.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
  static const SystemUiOverlayStyle _darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: AppTheme.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

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
    _extraTop.dispose();
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
    final ProfileColors profileColors = AppTheme.profileOf(context);
    final bool darkTheme = Theme.of(context).brightness == Brightness.dark;
    // 状态栏 + 工具栏的总高。必须在这里（SafeArea 外面）取：
    // SafeArea 会把里面的 MediaQuery 顶部边距清零
    final double barBottom =
        MediaQuery.paddingOf(context).top + ProfileTopBar.height;

    final Widget page = Stack(
      children: <Widget>[
        // 头像模糊出来的深色背景。它是固定的一层，随滚动整体平移，
        // 和头像、统计、快捷入口同步走——文字始终压在它上面，不会落到变浅的底上
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: ProfileBlurBackdrop.height,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _scrollController,
              _extraTop,
            ]),
            // RepaintBoundary：模糊只画一次，滚动时只是整层平移
            child: RepaintBoundary(
              child: ProfileBlurBackdrop(avatarUrl: user.avatarUrl),
            ),
            builder: (BuildContext context, Widget? child) =>
                Transform.translate(
                  offset: Offset(0, _extraTop.value - _scrollOffset),
                  child: child,
                ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              // 工具栏常驻；折叠只看滚动距离，颜色随背景下沿划过工具栏渐变
              AnimatedBuilder(
                animation: _scrollController,
                builder: (BuildContext context, Widget? child) {
                  final double p = _barProgress(barBottom);
                  return ProfileTopBar(
                    user: user,
                    collapsed: _scrollOffset > _collapseOffset,
                    color: Color.lerp(
                      profileColors.onHeader,
                      colors.textPrimary,
                      p,
                    )!,
                    mutedColor: Color.lerp(
                      profileColors.onHeaderMuted,
                      colors.textSecondary,
                      p,
                    )!,
                  );
                },
              ),
              Expanded(
                child: PullToRefresh(
                  onRefresh: store.load,
                  extraTop: _extraTop,
                  builder: (BuildContext context, double extraTop) =>
                      _buildScrollView(
                        context,
                        data: data,
                        user: user,
                        playlists: visiblePlaylists,
                        extraTop: extraTop,
                        headerHeight: ProfileBlurBackdrop.sheetTop - barBottom,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // 状态栏图标跟着头部走：头部还罩在状态栏上就用白图标，滚走后再按主题换
    return AnimatedBuilder(
      animation: _scrollController,
      child: page,
      builder: (BuildContext context, Widget? child) =>
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: (darkTheme || _barProgress(barBottom) < 0.5)
                ? _lightStatusBar
                : _darkStatusBar,
            child: child!,
          ),
    );
  }

  /// 工具栏从「压在深色头部上」过渡到「压在页面底色上」的进度，0~1。
  ///
  /// 头部的下沿在滚动距离 `sheetTop - barBottom` 时刚好到工具栏底边，
  /// 再滚一个工具栏的高度就整个离开，这段里颜色逐渐换回正文色。
  double _barProgress(double barBottom) {
    final double start = ProfileBlurBackdrop.sheetTop - barBottom;
    return ((_scrollOffset - start) / ProfileTopBar.height).clamp(0.0, 1.0);
  }

  Widget _buildScrollView(
    BuildContext context, {
    required ProfileSummary data,
    required UserProfile user,
    required List<Playlist> playlists,
    required double extraTop,
    required double headerHeight,
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
        // 头部块：高度固定为「面板顶边 - 工具栏底边」，这样它的下沿
        // 正好落在背景的 sheetTop 上，下面的圆角面板才和背景严丝合缝
        SliverToBoxAdapter(
          child: SizedBox(
            height: headerHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ProfileIdentity(user: user, data: data),
                const Spacer(),
                ProfileQuickEntries(onTapEntry: _onQuickEntry),
                // 官方快捷入口到面板顶边约 25dp（70px ÷ 2.81）
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
        // 白色圆角面板的顶边，盖在背景最下面一个圆角高度上
        const SliverToBoxAdapter(child: ProfileSheetCap()),
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
