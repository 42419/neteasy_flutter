import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/error_retry.dart';
import '../../components/pull_to_refresh.dart';
import '../../stores/follow_store.dart';
import '../../stores/session_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/feed_event.dart';
import '../login/login_view.dart';
import 'event_detail_page.dart';
import 'widgets/follow_feed_item.dart';
import 'widgets/follow_states.dart';
import 'widgets/follow_strip.dart';
import 'widgets/follow_tabs.dart';
import 'widgets/follow_top_bar.dart';

/// 「关注」页（底部导航第二个 tab）。
///
/// 结构：顶栏 → 头像条 → 「我的关注」+ 全部/音乐人/朋友 → 动态流。
/// 只做编排：数据在 [FollowStore]，每块 UI 在 `widgets/` 下。
///
/// 三个标签是**客户端过滤**（服务端没有按关系分流的参数）：
/// 音乐人看 `userType == 2`，朋友看互关，其余只在「全部」里出现。
/// 过滤完再套 [FollowStore.visibleOf]（近 3 天全显示，不足 3 条补旧的），
/// 所以每个标签各算各的，切到没内容的标签就会是空态。
///
/// 这个流**不分页**：官方的关注 tab 只给这么多，更多内容在「全部动态」页，
/// 所以列表到底就显示「你关心的动态看完啦」。
class FollowView extends StatefulWidget {
  const FollowView({super.key});

  @override
  State<FollowView> createState() => _FollowViewState();
}

class _FollowViewState extends State<FollowView> {
  /// 0 全部 / 1 音乐人 / 2 朋友
  int _tab = 0;

  /// 各标签的空态文案（前两条是截图上原文，全部那条按同一句式补）
  static const List<String> _emptyTexts = <String>[
    '关注的人近3天没有新动态',
    '关注的音乐人近3天没有新动态',
    '关注的好友近3天没有新动态',
  ];

  @override
  void initState() {
    super.initState();
    // 首帧之后再拉：登录态要先从 SessionStore 恢复
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FollowStore>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final SessionStore session = context.watch<SessionStore>();
    final FollowStore store = context.watch<FollowStore>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          FollowTopBar(
            onSearch: () => _toast('搜索暂未支持'),
            onCompose: () => _toast('发布动态暂未支持'),
          ),
          Expanded(child: _buildBody(context, session, store, colors)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionStore session,
    FollowStore store,
    AppColors colors,
  ) {
    if (!session.loggedIn) {
      if (session.restoring) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
      }
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FollowGuestState(onLogin: _openLogin),
      );
    }
    if (store.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    final String? error = store.error;
    if (error != null && store.events.isEmpty) {
      return ErrorRetry(
        message: error,
        onRetry: store.load,
        style: AppTheme.caption(colors),
        spacing: 12,
      );
    }

    final List<FeedEvent> visible = FollowStore.visibleOf(
      _visibleEvents(store),
    );

    return PullToRefresh(
      onRefresh: store.load,
      builder: (BuildContext context, double extraTop) => CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(child: SizedBox(height: extraTop)),
          SliverToBoxAdapter(
            child: FollowStrip(
              contacts: store.stripContacts,
              onContact: (FollowContact contact) =>
                  _toast('${contact.user.displayName}主页暂未支持'),
              onAllFriends: () => _toast('全部好友暂未支持'),
            ),
          ),
          SliverToBoxAdapter(
            child: FollowTabs(
              selected: _tab,
              onSelect: (int index) => setState(() => _tab = index),
            ),
          ),
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: <Widget>[
                  FollowEmptyState(
                    text: _emptyTexts[_tab],
                    onViewAll: () => _toast('全部动态暂未支持'),
                  ),
                  const FollowBottomTip(),
                ],
              ),
            )
          else ...<Widget>[
            SliverList.separated(
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int i) => FollowFeedItem(
                event: visible[i],
                onForward: () => _toast('转发暂未支持'),
                onComment: () => _openDetail(visible[i], openAtComments: true),
                onOpenDetail: () => _openDetail(visible[i]),
                onPraise: () => _toast('点赞暂未支持'),
                onMore: () => _toast('更多操作暂未支持'),
                onPlaylist: () => _toast('歌单详情暂未支持'),
                onSong: () => _toast('播放页暂未支持'),
              ),
              separatorBuilder: (BuildContext context, int index) =>
                  Divider(height: 0.5, thickness: 0.5, color: colors.divider),
            ),
            SliverToBoxAdapter(
              child: FollowEndState(onViewAll: () => _toast('全部动态暂未支持')),
            ),
          ],
          // extendBody 下 Scaffold 把底栏总高写进 MediaQuery 的 padding，
          // 用它留白，最后一行才不会被迷你播放器压住
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ),
        ],
      ),
    );
  }

  /// 按标签过滤；「全部」不做过滤
  List<FeedEvent> _visibleEvents(FollowStore store) {
    switch (_tab) {
      case 1:
        return store.events
            .where((FeedEvent e) => e.isArtist)
            .toList(growable: false);
      case 2:
        return store.events
            .where((FeedEvent e) => e.isFriend)
            .toList(growable: false);
      default:
        return store.events;
    }
  }

  /// 打开动态详情：评论按钮进来时直接滚到评论区
  void _openDetail(FeedEvent event, {bool openAtComments = false}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            EventDetailPage(event: event, openAtComments: openAtComments),
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginView(),
      ),
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
