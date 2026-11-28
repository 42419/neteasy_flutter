import 'dart:convert';

import '../../viewmodels/feed_comment.dart';
import '../../viewmodels/feed_event.dart';
import 'json_utils.dart';

/// 动态流与关注关系。
///
/// 两个坑（都是实测踩出来的）：
/// - `/event` 的列表键是 **`event`（单数）**，`/user/event` 用的是 `events`，
///   两个键都得认，否则关注流永远是空的
/// - `events[i].json` 是**字符串**，要再 `jsonDecode` 一次；解不出来不能整条丢掉，
///   至少把作者、配图、互动数留下

/// `/event`、`/user/event` → 一页动态。
///
/// 解锁失败（不是 JSON、或者不是对象）时按空对象处理：正文和分享内容都为空，
/// 页面会跳过这条没有主体的动态，但不会因为一条脏数据把整页打挂。
FeedPage toFeedPage(Map<dynamic, dynamic> json) {
  final Object? raw = json['event'] ?? json['events'];
  final List<FeedEvent> events = mapList<FeedEvent>(raw, toFeedEvent);
  return FeedPage(
    events: events,
    more: json['more'] == true,
    lasttime: asInt(json['lasttime']),
  );
}

/// 单条动态；缺 id 或作者时返回 null 让上层过滤。
FeedEvent? toFeedEvent(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final Map<dynamic, dynamic>? userJson = asMap(json['user']);
  final int uid = asInt(userJson?['userId']);
  if (id == 0 || uid == 0) {
    return null;
  }

  final Map<dynamic, dynamic> payload = _payload(json['json']);
  final Map<dynamic, dynamic>? info = asMap(json['info']);
  final Map<dynamic, dynamic>? ipLocation = asMap(json['ipLocation']);

  return FeedEvent(
    id: id,
    type: asInt(json['type']),
    timeMs: asInt(json['eventTime']),
    user: _feedUser(userJson)!,
    text: _text(payload['msg']),
    title: _text(payload['title']),
    pics: _pics(json['pics']),
    playlist: _playlist(payload['playlist']),
    song: _song(payload['song']),
    liked: info?['liked'] == true,
    likedCount: asInt(info?['likedCount']),
    commentCount: asInt(info?['commentCount']),
    shareCount: asInt(info?['shareCount']),
    threadId: (info?['threadId'] as String?) ?? '',
    location: (ipLocation?['location'] as String?) ?? '',
    topEvent: json['topEvent'] == true,
  );
}

/// `/user/follow/mixed` → 头像条候选。
///
/// `data.records[]` 里混着用户和歌手：`type == 3` 是歌手，
/// 互关看 `mutualFollowTime`，乐迷团看 `fansGroupInfo`。
List<FollowContact> toFollowContacts(Map<dynamic, dynamic> json) {
  final Map<dynamic, dynamic>? data = asMap(json['data']);
  final Object? records = data?['records'];
  if (records is! List) {
    return const <FollowContact>[];
  }
  final List<FollowContact> contacts = <FollowContact>[];
  for (final Map<dynamic, dynamic> record in records.whereType<Map>()) {
    final Map<dynamic, dynamic>? profile = asMap(record['userProfile']);
    final int uid = asInt(profile?['userId']);
    if (uid == 0) {
      continue;
    }
    final Map<dynamic, dynamic>? fans = asMap(record['fansGroupInfo']);
    contacts.add(
      FollowContact(
        user: FeedUser(
          uid: uid,
          nickname: (profile?['nickname'] as String?) ?? '',
          avatarUrl: (profile?['avatarUrl'] as String?) ?? '',
          userType: asInt(profile?['userType']),
          vipType: asInt(profile?['vipType']),
        ),
        isArtist: asInt(record['type']) == 3,
        isMutual: asInt(record['mutualFollowTime']) > 0,
        // 空对象也算「没有」：服务端对非乐迷返回的是 {}
        hasFansGroup: fans != null && fans.isNotEmpty,
      ),
    );
  }
  return contacts;
}

/// `json` 字段：可能是字符串、可能已经是对象、也可能是空串
Map<dynamic, dynamic> _payload(Object? raw) {
  if (raw is Map) {
    return raw;
  }
  if (raw is! String || raw.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    final Object? decoded = jsonDecode(raw);
    return decoded is Map ? decoded : const <String, dynamic>{};
  } catch (_) {
    return const <String, dynamic>{};
  }
}

/// 正文可能是 null，也可能带前后空白
String _text(Object? raw) => raw is String ? raw.trim() : '';

List<FeedPic> _pics(Object? raw) {
  if (raw is! List) {
    return const <FeedPic>[];
  }
  final List<FeedPic> pics = <FeedPic>[];
  for (final Map<dynamic, dynamic> pic in raw.whereType<Map>()) {
    // 方图最省流量；缺了退回竖图、再退回原图
    final String thumb = firstText(<Object?>[
      pic['squareUrl'],
      pic['pcSquareUrl'],
      pic['rectangleUrl'],
      pic['originUrl'],
    ]);
    if (thumb.isEmpty) {
      continue;
    }
    pics.add(
      FeedPic(
        url: thumb,
        originUrl: firstText(<Object?>[pic['originUrl'], pic['squareUrl']]),
        width: asInt(pic['width']),
        height: asInt(pic['height']),
      ),
    );
  }
  return pics;
}

FeedPlaylist? _playlist(Object? raw) {
  final Map<dynamic, dynamic>? json = asMap(raw);
  final int id = asInt(json?['id']);
  if (json == null || id == 0) {
    return null;
  }
  return FeedPlaylist(
    id: id,
    name: (json['name'] as String?) ?? '',
    coverUrl: (json['coverImgUrl'] as String?) ?? '',
    trackCount: asInt(json['trackCount']),
  );
}

FeedSong? _song(Object? raw) {
  final Map<dynamic, dynamic>? json = asMap(raw);
  final int id = asInt(json?['id']);
  if (json == null || id == 0) {
    return null;
  }
  // 歌曲有两种形态：`ar` / `al` 或平铺的 `artists` / `album`
  final Object? artists = json['ar'] ?? json['artists'];
  final String artist = artists is List && artists.isNotEmpty
      ? ((asMap(artists.first)?['name'] as String?) ?? '')
      : '';
  final Map<dynamic, dynamic>? album = asMap(json['al'] ?? json['album']);
  return FeedSong(
    id: id,
    name: (json['name'] as String?) ?? '',
    artist: artist,
    coverUrl: (album?['picUrl'] as String?) ?? '',
  );
}

/// 是不是黑胶 SVIP。
///
/// 优先看 `vipRights.extInfo.logo.vipType`（300 = SVIP，实测值），
/// 这个字段缺失时退到 `redplus.rights`——两者任一为真就按 SVIP 画徽章
bool _isSvip(Map<dynamic, dynamic>? rights) {
  final Map<dynamic, dynamic>? logo = asMap(asMap(rights?['extInfo'])?['logo']);
  if (asInt(logo?['vipType']) == 300) {
    return true;
  }
  return asMap(rights?['redplus'])?['rights'] == true;
}

/// `/comment/event` → 一页评论。
///
/// 优先 `comments`，它是空的时候退到 `hotComments`：部分资源只下发热评。
FeedCommentPage toCommentPage(Map<dynamic, dynamic> json) {
  final Object? latest = json['comments'];
  final Object? source = latest is List && latest.isNotEmpty
      ? latest
      : json['hotComments'];
  return FeedCommentPage(
    total: asInt(json['total']),
    comments: mapList<FeedComment>(source, toFeedComment),
    more: json['more'] == true,
  );
}

/// 一条评论；缺用户或既没 id 又没正文时返回 null。
FeedComment? toFeedComment(Map<dynamic, dynamic> json) {
  final FeedUser? user = _feedUser(asMap(json['user']));
  final int id = asInt(json['commentId'] ?? json['id']);
  final String content = (json['content'] as String?) ?? '';
  if (user == null || (id == 0 && content.trim().isEmpty)) {
    return null;
  }

  // 楼中楼预览：只取第一条被回复的内容
  String replyToName = '';
  String replyToContent = '';
  final Object? replied = json['beReplied'];
  if (replied is List && replied.isNotEmpty) {
    final Map<dynamic, dynamic>? first = asMap(replied.first);
    replyToName = (asMap(first?['user'])?['nickname'] as String?) ?? '';
    replyToContent = (first?['content'] as String?) ?? '';
  }

  final int replyCount =
      asInt(json['replyCount'] ?? json['beRepliedCount']) != 0
      ? asInt(json['replyCount'] ?? json['beRepliedCount'])
      : (replied is List ? replied.length : 0);

  return FeedComment(
    id: id,
    user: user,
    content: content,
    timeMs: asInt(json['time']),
    liked: json['liked'] == true,
    likedCount: asInt(json['likedCount']),
    replyToName: replyToName,
    replyToContent: replyToContent,
    replyCount: replyCount > 1 ? replyCount : 0,
  );
}

/// 动态和评论里的用户对象是同一套字段，统一在这里解析
FeedUser? _feedUser(Map<dynamic, dynamic>? json) {
  final int uid = asInt(json?['userId']);
  if (json == null || uid == 0) {
    return null;
  }
  final Map<dynamic, dynamic>? vipRights = asMap(json['vipRights']);
  return FeedUser(
    uid: uid,
    nickname: (json['nickname'] as String?) ?? '',
    avatarUrl: (json['avatarUrl'] as String?) ?? '',
    userType: asInt(json['userType']),
    mutual: json['mutual'] == true,
    vipType: asInt(json['vipType']),
    // 等级徽章（「SVIP·柒」）用的是 redVipLevel，不是 vipType
    vipLevel: asInt(vipRights?['redVipLevel']),
    svip: _isSvip(vipRights),
  );
}
