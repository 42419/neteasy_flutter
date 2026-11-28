import 'package:animations/animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../components/cover_thumb.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../viewmodels/feed_event.dart';
import '../image_viewer_page.dart';
import 'expandable_text.dart';
import 'feed_image.dart';
import 'feed_vip_badge.dart';

/// 关注流里的一条动态。
///
/// 结构取自真机截图：40dp 圆头像，右侧依次是昵称、时间、正文、配图/分享卡、
/// 动作条；正文左边界和昵称对齐（不是和头像对齐），所以整块右边的内容
/// 都塞在头像右边那个 Expanded 里。
class FollowFeedItem extends StatelessWidget {
  const FollowFeedItem({
    super.key,
    required this.event,
    this.onForward,
    this.onComment,
    this.onPraise,
    this.onMore,
    this.onOpenDetail,
    this.onPlaylist,
    this.onSong,
  });

  final FeedEvent event;

  final VoidCallback? onForward;
  final VoidCallback? onComment;
  final VoidCallback? onPraise;
  final VoidCallback? onMore;

  /// 点「查看全文」/ 正文打开动态详情
  final VoidCallback? onOpenDetail;
  final VoidCallback? onPlaylist;
  final VoidCallback? onSong;

  /// 头像直径
  static const double _avatarSize = 40;

  /// 多图时每张的边长
  static const double _gridGap = 4;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
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

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        14,
        AppTheme.pagePadding,
        // 动作条到分隔线：真机量得 22dp
        22,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Avatar(url: event.user.avatarUrl),
          const SizedBox(width: 12),
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
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    // 黑胶等级徽章（「SVIP·柒」）。名字太长时先截名字，
                    // 徽章不许被挤掉，所以放在 Flexible 外面
                    if (event.user.vipLevel > 0) ...<Widget>[
                      const SizedBox(width: 6),
                      FeedVipBadge(user: event.user),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatMonthDay(event.timeMs),
                  style: AppTheme.tabularNumbers(
                    TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (event.title.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
                if (event.text.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  ExpandableText(
                    text: event.text,
                    style: bodyStyle,
                    linkStyle: linkStyle,
                    onTap: onOpenDetail,
                  ),
                ],
                if (event.pics.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _buildPics(context),
                ],
                if (event.playlist != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _ShareCard(
                    coverUrl: event.playlist!.coverUrl,
                    title: event.playlist!.name,
                    subtitle: event.playlist!.trackCount > 0
                        ? '歌单 · ${event.playlist!.trackCount}首'
                        : '歌单',
                    onTap: onPlaylist,
                  ),
                ],
                if (event.song != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _ShareCard(
                    coverUrl: event.song!.coverUrl,
                    title: event.song!.name,
                    subtitle: event.song!.artist,
                    onTap: onSong,
                  ),
                ],
                const SizedBox(height: 22),
                _ActionRow(
                  shareCount: event.shareCount,
                  commentCount: event.commentCount,
                  likedCount: event.likedCount,
                  liked: event.liked,
                  onForward: onForward,
                  onComment: onComment,
                  onPraise: onPraise,
                  onMore: onMore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 点图打开大图页：用官方 `animations` 包的 OpenContainer 做容器变换
  /// （图从列表里的位置长成整页），比自己拼 Hero + 路由过渡稳
  Widget _openable({required int index, required Widget thumb}) {
    return OpenContainer(
      // 关闭态透出列表底色，打开态是纯黑，中间那段也走黑，避免闪白
      closedColor: AppTheme.transparent,
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(),
      openColor: AppTheme.viewerBackground,
      middleColor: AppTheme.viewerBackground,
      openBuilder: (BuildContext context, VoidCallback _) =>
          ImageViewerPage(event: event, initialIndex: index),
      closedBuilder: (BuildContext context, VoidCallback open) =>
          GestureDetector(onTap: open, child: thumb),
    );
  }

  /// 一张图按原始宽高比竖着排；多张图排成三列方图
  Widget _buildPics(BuildContext context) {
    if (event.pics.length == 1) {
      // 单图按原比例落到正文栏里（高不超过 240）：
      // 不塞固定框、不 cover，所以既不会切边也不会留灰边
      return _openable(index: 0, thumb: FeedImage(pic: event.pics.first));
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = (constraints.maxWidth - _gridGap * 2) / 3;
        return Wrap(
          spacing: _gridGap,
          runSpacing: _gridGap,
          children: <Widget>[
            for (final (int index, FeedPic pic) in event.pics.take(9).indexed)
              _openable(
                index: index,
                thumb: CoverThumb(url: pic.url, size: side, crop: false),
              ),
          ],
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return ClipOval(
      child: SizedBox(
        width: FollowFeedItem._avatarSize,
        height: FollowFeedItem._avatarSize,
        child: url.isEmpty
            ? ColoredBox(color: colors.placeholder)
            : CoverImage(url: url, logicalWidth: FollowFeedItem._avatarSize),
      ),
    );
  }
}

/// 分享的歌单 / 单曲：一条浅色卡，左边封面、中间标题、右边播放键
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String coverUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: <Widget>[
            CoverThumb(url: coverUrl, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tabularNumbers(AppTheme.caption(colors)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 转发 / 评论 / 点赞 + 行尾更多
///
/// 真机量得：三个图标左缘分别在 68 / 153 / 238dp，间隔正好 85dp，
/// 数字紧跟在图标右侧 6dp 处。所以不是「图标之间留固定间隙」，
/// 而是**三列等宽、各自靠左**——数字变长时下一列也不会被推走。
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.shareCount,
    required this.commentCount,
    required this.likedCount,
    required this.liked,
    this.onForward,
    this.onComment,
    this.onPraise,
    this.onMore,
  });

  /// 一列的宽度
  static const double _slot = 85;

  /// 图标占位：三个图标都按 16dp 的可见大小画，占位统一 16，
  /// 后面数字的起点才会齐平
  static const double _iconBox = 16;

  /// 图标与数字之间
  static const double _iconGap = 6;

  /// 三个资源的留白比例不同（viewBox 16 / 24 / 24，墨迹分别占 100% / 77% / 79%），
  /// 都按 16dp 画会出现「分享偏大、评论和点赞偏小」。
  /// 按各自的墨迹占比折算绘制尺寸，可见部分就都是 16dp。
  static const double _forwardSize = 16;
  static const double _commentSize = 21;
  static const double _praiseSize = 20;
  static const double _praisedSize = 16;

  final int shareCount;
  final int commentCount;
  final int likedCount;
  final bool liked;
  final VoidCallback? onForward;
  final VoidCallback? onComment;
  final VoidCallback? onPraise;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: _slot,
          child: _Action(
            asset: AppConstants.feedForwardIcon,
            size: _forwardSize,
            count: shareCount,
            color: colors.textSecondary,
            onTap: onForward,
          ),
        ),
        SizedBox(
          width: _slot,
          child: _Action(
            asset: AppConstants.feedCommentIcon,
            size: _commentSize,
            count: commentCount,
            color: colors.textSecondary,
            onTap: onComment,
          ),
        ),
        SizedBox(
          width: _slot,
          // 已点赞的图标自带红色，且是 12 格满幅，不能再染色、也不放大
          child: _Action(
            asset: liked
                ? AppConstants.feedPraisedIcon
                : AppConstants.feedPraiseIcon,
            size: liked ? _praisedSize : _praiseSize,
            count: likedCount,
            color: colors.textSecondary,
            tinted: !liked,
            onTap: onPraise,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onMore,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Image.asset(
              AppConstants.moreIcon,
              width: 18,
              height: 18,
              color: colors.textTertiary,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.asset,
    required this.size,
    required this.count,
    required this.color,
    this.tinted = true,
    this.onTap,
  });

  final String asset;

  /// 绘制尺寸（不是可见尺寸，见 [_ActionRow] 里的说明）
  final double size;

  final int count;
  final Color color;

  /// 单色图标统一染成 [color]；自带配色的（已点赞的红心）传 false
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
          // 留白大的图标按原比例放大后，用 OverflowBox 塞回 16dp 的占位里：
          // 可见部分对齐 16dp，而后面数字的起点仍在占位 + 6dp
          SizedBox(
            width: _ActionRow._iconBox,
            height: _ActionRow._iconBox,
            child: OverflowBox(
              maxWidth: size,
              maxHeight: size,
              child: SvgPicture.asset(
                asset,
                width: size,
                height: size,
                colorFilter: tinted
                    ? ColorFilter.mode(color, BlendMode.srcIn)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: _ActionRow._iconGap),
          Text(
            formatCount(count),
            // 数字等宽：点赞数从 9 变 10 时，后面不会跟着挪
            style: AppTheme.numeric(
              TextStyle(fontSize: 12, height: 1.2, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
