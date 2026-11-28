/// 动态的评论。
///
/// 网易云的评论结构各端一致：`user` / `content` / `time` / `likedCount` /
/// `beReplied`。这里只取详情页要展示的字段，楼层回复只留第一层预览。
library;

import 'feed_event.dart';

/// 一条评论。
class FeedComment {
  const FeedComment({
    required this.id,
    required this.user,
    required this.content,
    this.timeMs = 0,
    this.liked = false,
    this.likedCount = 0,
    this.replyToName = '',
    this.replyToContent = '',
    this.replyCount = 0,
  });

  final int id;
  final FeedUser user;
  final String content;
  final int timeMs;
  final bool liked;
  final int likedCount;

  /// 楼中楼：被回复人的昵称与他那句话（`beReplied[0]`）
  final String replyToName;
  final String replyToContent;

  /// 楼中楼的条数（`showReplyCount` / `replyCount`），0 表示没有
  final int replyCount;
}

/// 一页评论。
class FeedCommentPage {
  const FeedCommentPage({
    this.total = 0,
    this.comments = const <FeedComment>[],
    this.more = false,
  });

  /// 评论总数（页面标题「评论 N」用它）
  final int total;

  final List<FeedComment> comments;

  final bool more;
}
