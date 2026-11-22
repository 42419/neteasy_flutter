import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/mapper/library_mapper.dart';
import 'package:neteasy_flutter/api/mapper/snapshot_mapper.dart';
import 'package:neteasy_flutter/viewmodels/home_block.dart';
import 'package:neteasy_flutter/viewmodels/home_entry.dart';
import 'package:neteasy_flutter/viewmodels/home_snapshot.dart';
import 'package:neteasy_flutter/viewmodels/playlist.dart';
import 'package:neteasy_flutter/viewmodels/rank.dart';

/// 共享歌单的角标要显示「对方」的头像，而接口给的信息不够：
/// `sharedUsers` 里把自己也列进去了，别人建好共享给我的歌单更是只有我自己。
/// 这里按真实响应把两种情况都钉住。
void main() {
  const int selfUid = 10062938859;

  group('toPlaylist 解析共享字段', () {
    test('列表接口只给 userId：捞得到 uid 列表，头像为空等回填', () {
      final Playlist? playlist = toPlaylist(<String, dynamic>{
        'id': 18582023388,
        'name': '星露谷',
        'coverImgUrl': 'http://p1.music.126.net/cover.jpg',
        'specialType': 300,
        'creator': <String, dynamic>{
          'userId': 12911428416,
          'nickname': '玩物尚志-_',
          'avatarUrl': 'http://p1.music.126.net/creator.jpg',
        },
        'sharedUsers': <Map<String, dynamic>>[
          <String, dynamic>{'userId': selfUid},
        ],
      });

      expect(playlist, isNotNull);
      expect(playlist!.sharedUserIds, <int>[selfUid]);
      expect(playlist.creatorAvatarUrl, 'http://p1.music.126.net/creator.jpg');
      expect(playlist.sharedAvatarUrl, isEmpty);
    });

    test('普通歌单 sharedUsers 为 null：两个列表都为空', () {
      final Playlist? playlist = toPlaylist(<String, dynamic>{
        'id': 1,
        'name': '8090经典老歌',
        'sharedUsers': null,
      });

      expect(playlist!.sharedUserIds, isEmpty);
      expect(playlist.sharedBadgeUid(selfUid), 0);
    });

    test('sharedUsers 为空数组也安全', () {
      final Playlist? playlist = toPlaylist(<String, dynamic>{
        'id': 2,
        'name': '空数组',
        'sharedUsers': <Object?>[],
      });

      expect(playlist!.sharedUserIds, isEmpty);
    });

    test('首项不是对象时跳过，不抛异常', () {
      final Playlist? playlist = toPlaylist(<String, dynamic>{
        'id': 3,
        'name': '脏数据',
        'sharedUsers': <Object?>['bad', 42],
      });

      expect(playlist!.sharedUserIds, isEmpty);
    });
  });

  group('sharedBadgeUid 选「对方」', () {
    test('别人建好共享给我：共享者只有自己 → 取创建者', () {
      const Playlist playlist = Playlist(
        id: 1,
        name: '星露谷',
        coverUrl: '',
        specialType: Playlist.sharedType,
        creatorId: 12911428416,
        sharedUserIds: <int>[selfUid],
      );

      expect(playlist.sharedBadgeUid(selfUid), 12911428416);
    });

    test('我建好共享给别人：共享者里有别人 → 取那个人', () {
      const Playlist playlist = Playlist(
        id: 2,
        name: '我的共享',
        coverUrl: '',
        specialType: Playlist.sharedType,
        creatorId: selfUid,
        sharedUserIds: <int>[selfUid, 777],
      );

      expect(playlist.sharedBadgeUid(selfUid), 777);
    });

    test('多人共享时取第一个不是自己的', () {
      const Playlist playlist = Playlist(
        id: 3,
        name: '多人共享',
        coverUrl: '',
        specialType: Playlist.sharedType,
        creatorId: selfUid,
        sharedUserIds: <int>[selfUid, 888, 999],
      );

      expect(playlist.sharedBadgeUid(selfUid), 888);
    });

    test('自己的歌单没共享出去 → 0，不画角标', () {
      const Playlist playlist = Playlist(id: 4, name: '私密', coverUrl: '');

      expect(playlist.sharedBadgeUid(selfUid), 0);
    });
  });

  test('withSharedAvatar 只改头像，其余字段原样保留', () {
    const Playlist before = Playlist(
      id: 18582023388,
      name: '星露谷',
      coverUrl: 'http://p1.music.126.net/cover.jpg',
      playCount: 12,
      trackCount: 67,
      specialType: Playlist.sharedType,
      creatorName: '玩物尚志-_',
      creatorId: 12911428416,
      creatorAvatarUrl: 'http://p1.music.126.net/creator.jpg',
      subscribed: true,
      updateTime: 1700000000000,
      sharedUserIds: <int>[selfUid],
    );

    final Playlist after = before.withSharedAvatar(
      'http://p1.music.126.net/creator.jpg',
    );

    expect(after.sharedAvatarUrl, 'http://p1.music.126.net/creator.jpg');
    expect(after.sharedUserIds, before.sharedUserIds);
    expect(after.creatorAvatarUrl, before.creatorAvatarUrl);
    expect(after.id, before.id);
    expect(after.name, before.name);
    expect(after.coverUrl, before.coverUrl);
    expect(after.playCount, before.playCount);
    expect(after.trackCount, before.trackCount);
    expect(after.specialType, before.specialType);
    expect(after.creatorName, before.creatorName);
    expect(after.creatorId, before.creatorId);
    expect(after.subscribed, before.subscribed);
    expect(after.updateTime, before.updateTime);
  });

  test('快照只存原始字段，角标头像不落盘（由 store 现算）', () {
    final HomeSnapshot snapshot = HomeSnapshot(
      loggedIn: true,
      uid: 1,
      nickname: '',
      dailyCover: '',
      entries: const <HomeEntry>[],
      blocks: const <HomeBlock>[],
      // 快照要求「有内容」才有效：blocks/ranks 全空会被当作没有缓存
      ranks: <Rank>[Rank(id: 1, name: '热歌榜', coverUrl: '')],
      myPlaylists: <Playlist>[
        const Playlist(
          id: 18582023388,
          name: '星露谷',
          coverUrl: '',
          specialType: Playlist.sharedType,
          creatorId: 12911428416,
          creatorAvatarUrl: 'http://p1.music.126.net/creator.jpg',
          sharedUserIds: <int>[selfUid],
          // 派生值：不该被写进快照
          sharedAvatarUrl: 'http://p1.music.126.net/stale.jpg',
        ),
      ],
      savedAt: DateTime(2026, 11, 22),
    );

    final Map<String, dynamic> json = snapshotToJson(snapshot);
    final Map<String, dynamic> saved =
        (json['myPlaylists'] as List<dynamic>).single as Map<String, dynamic>;
    expect(saved.containsKey('sharedAvatarUrl'), isFalse);

    final HomeSnapshot? restored = snapshotFromJson(json);
    expect(restored, isNotNull);
    final Playlist playlist = restored!.myPlaylists.single;
    expect(playlist.sharedUserIds, <int>[selfUid]);
    expect(playlist.creatorAvatarUrl, 'http://p1.music.126.net/creator.jpg');
    // 读回来是空的，等 ProfileStore 重新算
    expect(playlist.sharedAvatarUrl, isEmpty);
  });
}
