/// 「关注」页的数据模型：动态流条目 + 顶部头像条的人。
///
/// 与 `Song` / `Playlist` 分开的原因是这里的条目是**聚合体**：
/// 一条动态可能带文字、配图、歌单或单曲，还能混着来，
/// 用同一个模型装不下，也不该让别的页面背上这些字段。
library;

/// 动态的发布者。
///
/// 只保留关注页要用的字段：`userType` 用来分「音乐人」标签，
/// `mutual` 用来分「朋友」标签（互关好友）。
class FeedUser {
  const FeedUser({
    required this.uid,
    required this.nickname,
    this.avatarUrl = '',
    this.userType = 0,
    this.mutual = false,
    this.vipType = 0,
    this.vipLevel = 0,
    this.svip = false,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;

  /// 0 普通用户 / 2 歌手 / 10 官方或音乐人账号（实测值）
  final int userType;

  /// 是否互相关注（「朋友」标签只看它）
  final bool mutual;

  final int vipType;

  /// 黑胶等级 1–7（`vipRights.redVipLevel`）。0 表示没有等级徽章
  final int vipLevel;

  /// 黑胶 SVIP（`vipRights.extInfo.logo.vipType == 300`）
  final bool svip;

  String get displayName => nickname.isEmpty ? '用户 $uid' : nickname;
}

/// 动态里的一张配图。
///
/// 服务端同时给 `squareUrl` / `rectangleUrl` / `originUrl`，
/// 列表用小图，点开大图才用原图（原图这轮用不到，先留着）。
class FeedPic {
  const FeedPic({
    required this.url,
    this.originUrl = '',
    this.width = 0,
    this.height = 0,
  });

  /// 列表用的方图地址（已由 mapper 挑好）
  final String url;

  /// 原图，只有点「原图」时才加载
  final String originUrl;

  final int width;
  final int height;

  /// 宽高比；缺失时按正方形，免得算出一张 0 高的图
  double get aspectRatio => (width > 0 && height > 0) ? width / height : 1;
}

/// 动态里分享的歌单（`type == 13`）。
class FeedPlaylist {
  const FeedPlaylist({
    required this.id,
    required this.name,
    this.coverUrl = '',
    this.trackCount = 0,
  });

  final int id;
  final String name;
  final String coverUrl;
  final int trackCount;
}

/// 动态里分享的单曲（`type == 18`）。
class FeedSong {
  const FeedSong({
    required this.id,
    required this.name,
    this.artist = '',
    this.coverUrl = '',
  });

  final int id;
  final String name;
  final String artist;
  final String coverUrl;
}

/// 一条动态。
class FeedEvent {
  const FeedEvent({
    required this.id,
    required this.type,
    required this.timeMs,
    required this.user,
    this.text = '',
    this.title = '',
    this.pics = const <FeedPic>[],
    this.playlist,
    this.song,
    this.liked = false,
    this.likedCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.threadId = '',
    this.location = '',
    this.topEvent = false,
  });

  /// 图文动态（实测关注流里最多的一类）
  static const int typeText = 35;

  /// 分享歌单
  static const int typePlaylist = 13;

  /// 分享单曲
  static const int typeSong = 18;

  final int id;
  final int type;

  /// 发布时间（毫秒）
  final int timeMs;

  final FeedUser user;

  /// 发布者写的话；话题（`#摄影#`）也在里面，由 UI 切出来染色
  final String text;

  /// 分享类动态自带的标题（`type == 13` 时是那句话，msg 里常只有话题）
  final String title;

  final List<FeedPic> pics;
  final FeedPlaylist? playlist;
  final FeedSong? song;

  final bool liked;
  final int likedCount;
  final int commentCount;
  final int shareCount;

  /// 评论、点赞都用它，形如 `A_EV_2_<动态id>_<用户id>`
  final String threadId;

  /// 发布地（`ipLocation.location`），详情页才显示，列表暂不用
  final String location;

  final bool topEvent;

  /// 「音乐人」标签的判定：只看 `userType == 2`（歌手）。
  ///
  /// 官方账号（`userType == 10`）**不算**音乐人：实测在官方 App 里
  /// 云音乐VIP 的图文只出现在「全部」，切到「音乐人」是空的。
  bool get isArtist => user.userType == 2;

  /// 「朋友」标签的判定：互关。
  ///
  /// 同上，官方账号和单向关注的歌手都只出现在「全部」。
  bool get isFriend => user.mutual;

  /// 有没有可展示的主体内容
  bool get hasBody =>
      text.trim().isNotEmpty ||
      title.trim().isNotEmpty ||
      pics.isNotEmpty ||
      playlist != null ||
      song != null;
}

/// 一页动态。
class FeedPage {
  const FeedPage({
    this.events = const <FeedEvent>[],
    this.more = false,
    this.lasttime = -1,
  });

  final List<FeedEvent> events;

  /// 服务端还有下一页
  final bool more;

  /// 翻页游标：把这一页的 `lasttime` 原样带回下一次请求
  final int lasttime;
}

/// 顶部头像条里的一个人（`/user/follow/mixed` 的 `data.records[]`）。
class FollowContact {
  const FollowContact({
    required this.user,
    this.isArtist = false,
    this.isMutual = false,
    this.hasFansGroup = false,
  });

  final FeedUser user;

  /// `record.type == 3`：关注的歌手（`scene=1` 只返回这类）
  final bool isArtist;

  /// 互相关注（`mutualFollowTime > 0`）
  final bool isMutual;

  /// 这个人的乐迷团（`fansGroupInfo` 非空）。
  /// 头像条首位的「乐迷团」入口由它决定要不要出现。
  final bool hasFansGroup;

  /// 头像条只放「好友」和「歌手」，官方账号/普通单向关注不进条
  bool get fitsStrip => isArtist || isMutual;
}
