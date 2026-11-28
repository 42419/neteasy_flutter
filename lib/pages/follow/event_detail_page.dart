import 'package:animations/animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../api/ncm_repository.dart';
import '../../components/cover_image.dart';
import '../../components/cover_thumb.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/result.dart';
import '../../viewmodels/feed_comment.dart';
import '../../viewmodels/feed_event.dart';
import 'image_viewer_page.dart';
import 'widgets/expandable_text.dart';
import 'widgets/feed_vip_badge.dart';

/// 动态详情：黑底 + 白色圆角面板，上面是发布者、全文、配图，下面是评论。
///
/// 两种入口共用同一页：点「查看全文」从顶部看起，
/// 点评论按钮进来自动滚到评论区（[openAtComments]）。
///
/// 评论走 `/comment/event?threadId=`，`threadId` 取 `info.threadId`，
/// 不是动态 id。
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    required this.event,
    this.openAtComments = false,
  });

  final FeedEvent event;

  /// 打开后是否直接滚到评论区
  final bool openAtComments;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  /// 顶栏高度（不含状态栏）
  static const double _barHeight = 56;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();

  FeedCommentPage? _comments;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadComments();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final String threadId = widget.event.threadId;
    if (threadId.isEmpty) {
      return;
    }
    final NcmRepository repo = context.read<NcmRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final Result<FeedCommentPage> result = await repo.eventComments(threadId);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final FeedCommentPage value):
          _comments = value;
        case Err(:final AppError error):
          _error = error.message;
      }
    });
    if (widget.openAtComments) {
      _scrollToComments();
    }
  }

  /// 等评论区真的挂上去再滚，不然 currentContext 还是 null
  void _scrollToComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = _commentsKey.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: AppTheme.viewerBackground,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 4),
                  _CloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: ColoredBox(
                color: colors.card,
                child: Column(
                  children: <Widget>[
                    Expanded(child: _buildScroll(context, colors)),
                    _buildBottomBar(context, colors),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScroll(BuildContext context, AppColors colors) {
    final FeedEvent event = widget.event;
    return SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildAuthor(context, colors),
          ),
          if (event.text.isNotEmpty) _buildText(colors),
          if (event.pics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildPics(colors),
            ),
          const SizedBox(height: 14),
          Divider(height: 0.5, thickness: 0.5, color: colors.divider),
          _buildComments(context, colors),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
        ],
      ),
    );
  }

  /// 正文 + 话题：话题和列表一样从正文里摘出来，放在最下面一行
  Widget _buildText(AppColors colors) {
    final ({String body, List<String> topics}) parts = splitTopics(
      widget.event.text,
    );
    final TextStyle bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: colors.textPrimary,
    );
    final TextStyle linkStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: colors.linkText,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (parts.body.isNotEmpty) Text(parts.body, style: bodyStyle),
          if (parts.topics.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: parts.body.isEmpty ? 0 : 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final String topic in parts.topics)
                    Text(topic, style: linkStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthor(BuildContext context, AppColors colors) {
    final FeedEvent event = widget.event;
    final String meta = <String>[
      formatRelativeTime(event.timeMs),
      event.location,
    ].where((String part) => part.isNotEmpty).join(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: event.user.avatarUrl.isEmpty
                ? ColoredBox(color: colors.placeholder)
                : CoverImage(url: event.user.avatarUrl, logicalWidth: 40),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      event.user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (event.user.vipLevel > 0) ...<Widget>[
                    const SizedBox(width: 6),
                    FeedVipBadge(user: event.user),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: AppTheme.tabularNumbers(
                  TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 配图：和列表一样按 152 宽展示，点开进大图页（同样走容器变换）
  Widget _buildPics(AppColors colors) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final (int index, FeedPic pic) in widget.event.pics.indexed)
          OpenContainer(
            closedColor: AppTheme.transparent,
            closedElevation: 0,
            closedShape: const RoundedRectangleBorder(),
            openColor: AppTheme.viewerBackground,
            middleColor: AppTheme.viewerBackground,
            openBuilder: (BuildContext context, VoidCallback _) =>
                ImageViewerPage(event: widget.event, initialIndex: index),
            closedBuilder: (BuildContext context, VoidCallback open) =>
                GestureDetector(
                  onTap: open,
                  child: CoverThumb(url: pic.url, size: 108, crop: false),
                ),
          ),
      ],
    );
  }

  Widget _buildComments(BuildContext context, AppColors colors) {
    final int total = _comments?.total ?? widget.event.commentCount;
    return Column(
      key: _commentsKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            '评论 $total',
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(_error!, style: AppTheme.caption(colors)),
            ),
          )
        else if ((_comments?.comments ?? const <FeedComment>[]).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text('还没有评论', style: AppTheme.caption(colors)),
            ),
          )
        else
          for (final FeedComment comment in _comments!.comments)
            _CommentRow(
              comment: comment,
              onLike: () => _toast('点赞暂未支持'),
              onExpand: () => _toast('展开评论暂未支持'),
            ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, AppColors colors) {
    final FeedEvent event = widget.event;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: () => _toast('发评论暂未支持'),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.placeholder,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '说点什么...',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            _BarAction(
              asset: event.liked
                  ? AppConstants.feedPraisedIcon
                  : AppConstants.feedPraiseIcon,
              count: event.likedCount,
              tinted: !event.liked,
              onTap: () => _toast('点赞暂未支持'),
            ),
            const SizedBox(width: 16),
            _BarAction(
              asset: AppConstants.feedCommentIcon,
              count: event.commentCount,
              onTap: () => _toast('评论暂未支持'),
            ),
          ],
        ),
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

/// 顶部关闭按钮：与动态页一致，白色 X
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              AppConstants.viewerCloseIcon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(colors.onMedia, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

/// 一条评论
class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, this.onLike, this.onExpand});

  final FeedComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final String meta = formatRelativeTime(comment.timeMs);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: comment.user.avatarUrl.isEmpty
                  ? ColoredBox(color: colors.placeholder)
                  : CoverImage(url: comment.user.avatarUrl, logicalWidth: 32),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        comment.user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    if (comment.user.vipLevel > 0) ...<Widget>[
                      const SizedBox(width: 5),
                      FeedVipBadge(user: comment.user, height: 14),
                    ],
                    if (meta.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(meta, style: AppTheme.caption(colors)),
                    ],
                  ],
                ),
                if (comment.replyToName.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '回复 @${comment.replyToName}：${comment.replyToContent}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: colors.textPrimary,
                  ),
                ),
                if (comment.replyCount > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onExpand,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      '展开${comment.replyCount}条评论',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        color: colors.linkText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  comment.liked
                      ? AppConstants.feedPraisedIcon
                      : AppConstants.feedPraiseIcon,
                  width: 16,
                  height: 16,
                  colorFilter: comment.liked
                      ? null
                      : ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
                ),
                const SizedBox(width: 4),
                Text(
                  formatCount(comment.likedCount),
                  style: AppTheme.numeric(
                    TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部栏右侧的图标 + 数字
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.asset,
    required this.count,
    this.tinted = true,
    this.onTap,
  });

  final String asset;
  final int count;
  final bool tinted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            asset,
            width: 20,
            height: 20,
            colorFilter: tinted
                ? ColorFilter.mode(colors.textPrimary, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(width: 5),
          Text(
            formatCount(count),
            style: AppTheme.numeric(
              TextStyle(fontSize: 13, height: 1.2, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
