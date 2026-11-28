import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/ncm_mapper.dart';
import 'package:neteasy_flutter/viewmodels/feed_comment.dart';
import 'package:neteasy_flutter/viewmodels/feed_event.dart';

/// 结构取自真实响应：`/event` 的列表键是 `event`（单数），
/// `/user/event` 是 `events`；`events[i].json` 是字符串，要再解析一次。
Map<String, dynamic> _textEvent({
  int id = 38097492898,
  int time = 1795665609508,
  int userType = 10,
  bool mutual = false,
}) {
  return <String, dynamic>{
    'id': id,
    'type': 35,
    'eventTime': time,
    'user': <String, dynamic>{
      'userId': 1452176465,
      'nickname': '云音乐VIP',
      'avatarUrl': 'https://p3.music.126.net/a.jpg',
      'userType': userType,
      'mutual': mutual,
      'vipType': 11,
      'vipRights': <String, dynamic>{
        'redVipLevel': 7,
        'redplus': <String, dynamic>{'rights': true},
        'extInfo': <String, dynamic>{
          'logo': <String, dynamic>{'vipType': 300},
        },
      },
    },
    'json': '{"msg":"#黑哥的打工日常# 秋天真好","title":""}',
    'pics': <Map<String, dynamic>>[
      <String, dynamic>{
        'squareUrl': 'https://p3.music.126.net/square.jpg',
        'originUrl': 'https://p4.music.126.net/origin.jpg',
        'width': 1080,
        'height': 1920,
      },
    ],
    'info': <String, dynamic>{
      'liked': true,
      'likedCount': 2121,
      'commentCount': 237,
      'shareCount': 7,
      'threadId': 'A_EV_2_38097492898_1452176465',
    },
    'ipLocation': <String, dynamic>{'location': '浙江'},
    'topEvent': false,
  };
}

Map<String, dynamic> _playlistEvent() {
  return <String, dynamic>{
    'id': 38088409688,
    'type': 13,
    'eventTime': 1795320007311,
    'user': <String, dynamic>{
      'userId': 1452176465,
      'nickname': '云音乐VIP',
      'userType': 10,
    },
    'json':
        '{"msg":"#心语推歌墙#","title":"周日一起听自由自在开心的歌！",'
        '"playlist":{"id":123,"name":"周日歌单","coverImgUrl":"https://p3.music.126.net/p.jpg","trackCount":30}}',
    'pics': <dynamic>[],
    'info': <String, dynamic>{'liked': false, 'likedCount': 3},
  };
}

void main() {
  test('图文动态：正文、配图、互动、threadId 都取到', () {
    final FeedPage page = toFeedPage(<String, dynamic>{
      'code': 200,
      'more': true,
      'lasttime': 1793845112871,
      'event': <Map<String, dynamic>>[_textEvent()],
    });

    expect(page.more, isTrue);
    expect(page.lasttime, 1793845112871);
    expect(page.events, hasLength(1));

    final FeedEvent event = page.events.first;
    expect(event.text, '#黑哥的打工日常# 秋天真好');
    expect(event.pics.single.url, 'https://p3.music.126.net/square.jpg');
    expect(event.pics.single.aspectRatio, closeTo(1080 / 1920, 0.001));
    expect(event.liked, isTrue);
    expect(event.likedCount, 2121);
    expect(event.commentCount, 237);
    expect(event.shareCount, 7);
    expect(event.threadId, 'A_EV_2_38097492898_1452176465');
    expect(event.location, '浙江');
    expect(event.user.displayName, '云音乐VIP');
    expect(event.user.vipLevel, 7, reason: '等级取自 vipRights.redVipLevel');
    expect(event.user.svip, isTrue, reason: 'extInfo.logo.vipType==300 是 SVIP');
  });

  test('列表键 `events` 也认（/user/event 用的是复数）', () {
    final FeedPage page = toFeedPage(<String, dynamic>{
      'events': <Map<String, dynamic>>[_textEvent()],
    });
    expect(page.events, hasLength(1));
    expect(page.more, isFalse, reason: '缺 more 按没有下一页处理');
  });

  test('json 解不出来时不丢条目：正文为空，配图和互动还在', () {
    final Map<String, dynamic> broken = _textEvent()..['json'] = '<html>502';
    final FeedPage page = toFeedPage(<String, dynamic>{
      'event': <Map<String, dynamic>>[broken],
    });
    expect(page.events, hasLength(1));
    expect(page.events.single.text, isEmpty);
    expect(page.events.single.pics, hasLength(1));
    expect(page.events.single.commentCount, 237);
  });

  test('缺 id 或缺作者的条目被过滤', () {
    final FeedPage page = toFeedPage(<String, dynamic>{
      'event': <Map<String, dynamic>>[
        _textEvent(),
        _textEvent(id: 0),
        <String, dynamic>{
          'id': 1,
          'type': 35,
          'user': <String, dynamic>{'nickname': '无 uid'},
        },
      ],
    });
    expect(page.events, hasLength(1));
  });

  test('分享歌单：歌单信息与标题都在', () {
    final FeedPage page = toFeedPage(<String, dynamic>{
      'event': <Map<String, dynamic>>[_playlistEvent()],
    });
    final FeedEvent event = page.events.single;
    expect(event.type, FeedEvent.typePlaylist);
    expect(event.title, '周日一起听自由自在开心的歌！');
    expect(event.playlist?.id, 123);
    expect(event.playlist?.name, '周日歌单');
    expect(event.playlist?.trackCount, 30);
    expect(event.user.vipLevel, 0, reason: '没有 vipRights 时不挂徽章');
    expect(event.user.svip, isFalse);
  });

  test('标签判定：歌手算音乐人，互关算朋友，官方号两边都不算', () {
    final FeedPage page = toFeedPage(<String, dynamic>{
      'event': <Map<String, dynamic>>[
        _textEvent(id: 1, userType: 2),
        _textEvent(id: 2, userType: 0, mutual: true),
        _textEvent(id: 3, userType: 10),
      ],
    });
    expect(page.events[0].isArtist, isTrue);
    expect(page.events[0].isFriend, isFalse);
    expect(page.events[1].isFriend, isTrue);
    expect(page.events[1].isArtist, isFalse);
    expect(page.events[2].isArtist, isFalse, reason: '官方号 userType=10 不算音乐人');
    expect(page.events[2].isFriend, isFalse);
  });

  test('头像条候选：歌手 / 互关 / 乐迷团', () {
    final List<FollowContact> contacts = toFollowContacts(<String, dynamic>{
      'code': 200,
      'data': <String, dynamic>{
        'records': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 1,
            'mutualFollowTime': 1790344602050,
            'userProfile': <String, dynamic>{
              'userId': 12911428416,
              'nickname': '玩物尚志-_',
              'userType': 0,
            },
          },
          <String, dynamic>{
            'type': 3,
            'userProfile': <String, dynamic>{
              'userId': 281382,
              'nickname': 'GEM鄧紫棋',
              'userType': 2,
            },
            'fansGroupInfo': <String, dynamic>{'level': '4', 'segment': '乐迷'},
          },
          <String, dynamic>{
            'type': 1,
            'userProfile': <String, dynamic>{
              'userId': 1452176465,
              'nickname': '云音乐VIP',
              'userType': 10,
            },
            'fansGroupInfo': <String, dynamic>{},
          },
        ],
      },
    });

    expect(contacts, hasLength(3));
    expect(contacts[0].isMutual, isTrue);
    expect(contacts[0].fitsStrip, isTrue);
    expect(contacts[1].isArtist, isTrue);
    expect(contacts[1].hasFansGroup, isTrue);
    expect(contacts[1].fitsStrip, isTrue);
    expect(contacts[2].fitsStrip, isFalse, reason: '官方号不上头像条');
    expect(contacts[2].hasFansGroup, isFalse, reason: '空对象算没有乐迷团');
  });

  test('评论：取到正文、互动数、楼中楼预览', () {
    final FeedCommentPage page = toCommentPage(<String, dynamic>{
      'code': 200,
      'total': 243,
      'more': true,
      'comments': <Map<String, dynamic>>[
        <String, dynamic>{
          'commentId': 111,
          'content': '这张咋样哇',
          'time': 1795500000000,
          'likedCount': 35,
          'liked': false,
          'user': <String, dynamic>{
            'userId': 22,
            'nickname': '闪开我要进厂了',
            'userType': 0,
            'vipRights': <String, dynamic>{'redVipLevel': 3},
          },
          'beReplied': <Map<String, dynamic>>[],
        },
        <String, dynamic>{
          'commentId': 112,
          'content': '好美',
          'time': 1795500000000,
          'user': <String, dynamic>{'userId': 23, 'nickname': '人非若水'},
          'beReplied': <Map<String, dynamic>>[
            <String, dynamic>{
              'user': <String, dynamic>{'nickname': '闪开我要进厂了'},
              'content': '这张咋样哇',
            },
            <String, dynamic>{
              'user': <String, dynamic>{'nickname': '甲'},
            },
          ],
        },
      ],
    });

    expect(page.total, 243);
    expect(page.more, isTrue);
    expect(page.comments, hasLength(2));
    expect(page.comments.first.content, '这张咋样哇');
    expect(page.comments.first.likedCount, 35);
    expect(page.comments.first.user.vipLevel, 3);
    expect(page.comments[1].replyToName, '闪开我要进厂了');
    expect(page.comments[1].replyCount, 2, reason: '楼中楼两条');
  });

  test('评论为空时退回热评；缺用户的条目被丢掉', () {
    final FeedCommentPage page = toCommentPage(<String, dynamic>{
      'total': 1,
      'comments': <dynamic>[],
      'hotComments': <Map<String, dynamic>>[
        <String, dynamic>{
          'commentId': 1,
          'content': '热评',
          'user': <String, dynamic>{'userId': 1, 'nickname': '甲'},
        },
        <String, dynamic>{'commentId': 2, 'content': '无用户'},
      ],
    });
    expect(page.comments, hasLength(1));
    expect(page.comments.single.content, '热评');
  });
}
