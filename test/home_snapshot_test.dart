import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/mapper/snapshot_mapper.dart';
import 'package:neteasy_flutter/utils/home_snapshot_store.dart';
import 'package:neteasy_flutter/viewmodels/home_block.dart';
import 'package:neteasy_flutter/viewmodels/home_entry.dart';
import 'package:neteasy_flutter/viewmodels/home_snapshot.dart';
import 'package:neteasy_flutter/viewmodels/playlist.dart';
import 'package:neteasy_flutter/viewmodels/rank.dart';

/// 覆盖所有会被首页用到的字段：区块 / 卡片 / 资源 / 有声书 / 榜单 / 歌单 / 入口卡
HomeSnapshot _sample() {
  return HomeSnapshot(
    loggedIn: true,
    uid: 12345,
    nickname: '云村村民',
    dailyCover: 'https://p1.music.126.net/daily.jpg',
    entries: <HomeEntry>[
      const HomeEntry(
        id: '1',
        title: '每日推荐',
        subtitle: '根据你的音乐口味生成',
        imageUrl: 'https://p1.music.126.net/entry.jpg',
        action: 'orpheus://daily',
      ),
    ],
    blocks: <HomeBlock>[
      HomeBlock(
        blockCode: HomeBlock.playlistRcmd,
        showType: 'HOMEPAGE_SLIDE_PLAYLIST',
        title: '',
        subtitle: '推荐歌单',
        hasMore: true,
        creatives: <HomeCreative>[
          HomeCreative(
            creativeType: 'list',
            action: 'orpheus://playlist/1',
            title: '',
            imageUrl: 'https://p1.music.126.net/cover.jpg',
            labelTexts: const <String>['华语'],
            resources: <HomeResource>[
              const HomeResource(
                resourceType: 'list',
                resourceId: '1',
                name: '华语经典100首',
                title: '',
                subtitle: '',
                imageUrl: 'https://p1.music.126.net/cover.jpg',
                labelTexts: <String>['华语'],
                playCount: 12000,
              ),
            ],
          ),
        ],
      ),
      HomeBlock(
        blockCode: HomeBlock.voicebookRcmd,
        showType: 'HOMEPAGE_VOICEBOOK',
        title: '',
        subtitle: 'SVIP专享有声书',
        hasMore: false,
        creatives: const <HomeCreative>[],
        books: const <HomeBook>[
          HomeBook(
            id: '2',
            title: '甄嬛传',
            coverUrl: 'https://p1.music.126.net/book.jpg',
            category: '小说速读',
            desc: '十三载，再重逢',
            playCount: '11.5万',
            score: '9.5',
          ),
        ],
      ),
    ],
    ranks: <Rank>[
      Rank(
        id: 19723756,
        name: '飙升榜',
        coverUrl: 'https://p1.music.126.net/rank.jpg',
        playCount: 987654,
        updateFrequency: '每天更新',
        toplistType: 'S',
      )..tracks = const <String>['第一首', '第二首', '第三首'],
    ],
    myPlaylists: const <Playlist>[
      Playlist(id: 5, name: '我喜欢的音乐', coverUrl: '', specialType: 5),
    ],
    savedAt: DateTime.fromMillisecondsSinceEpoch(1763000000000),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('快照编解码', () {
    test('往返后字段不变', () {
      final Map<String, dynamic> json = snapshotToJson(_sample());
      // 走一遍真实序列化，确认没有不可编码的对象
      final Object? decoded = jsonDecode(jsonEncode(json));
      final HomeSnapshot? restored = snapshotFromJson(decoded);

      expect(restored, isNotNull);
      final HomeSnapshot snapshot = restored!;
      expect(snapshot.loggedIn, isTrue);
      expect(snapshot.uid, 12345);
      expect(snapshot.nickname, '云村村民');
      expect(snapshot.dailyCover, 'https://p1.music.126.net/daily.jpg');
      expect(snapshot.savedAt?.millisecondsSinceEpoch, 1763000000000);

      expect(snapshot.entries.single.title, '每日推荐');

      final HomeBlock block = snapshot.blocks.first;
      expect(block.blockCode, HomeBlock.playlistRcmd);
      expect(block.hasMore, isTrue);
      expect(block.displayTitle, '推荐歌单');
      final HomeResource resource = block.creatives.single.primary!;
      expect(resource.resourceId, '1');
      expect(resource.displayName, '华语经典100首');
      expect(resource.playCount, 12000);
      expect(resource.labelTexts, <String>['华语']);

      final HomeBook book = snapshot.blocks.last.books.single;
      expect(book.title, '甄嬛传');
      expect(book.score, '9.5');

      final Rank rank = snapshot.ranks.single;
      expect(rank.homeWeight, 3);
      expect(rank.trackLine, '第一首、第二首、第三首');

      expect(snapshot.myPlaylists.single.isLikedMusic, isTrue);
    });

    test('版本不符返回 null', () {
      final Map<String, dynamic> json = snapshotToJson(_sample());
      json['version'] = HomeSnapshot.version + 1;
      expect(snapshotFromJson(json), isNull);
    });

    test('结构不对返回 null', () {
      expect(snapshotFromJson(null), isNull);
      expect(snapshotFromJson('不是对象'), isNull);
      expect(snapshotFromJson(<String, dynamic>{}), isNull);
      expect(snapshotFromJson(<String, dynamic>{'version': 1}), isNull);
    });

    test('没有可画内容时不算缓存', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'version': HomeSnapshot.version,
        'blocks': <dynamic>[],
        'ranks': <dynamic>[],
      };
      expect(snapshotFromJson(json), isNull);
    });
  });

  group('快照存储', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('ncm_snapshot');
    });

    tearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    HomeSnapshotStore store() => HomeSnapshotStore(directory: () async => dir);

    File snapshotFile() => File(
      '${dir.path}${Platform.pathSeparator}${HomeSnapshotStore.fileName}',
    );

    test('写入后能读回，不留临时文件', () async {
      final HomeSnapshotStore snapshots = store();
      expect(await snapshots.load(), isNull);

      await snapshots.save(_sample());

      final HomeSnapshot? loaded = await snapshots.load();
      expect(loaded, isNotNull);
      expect(loaded!.ranks.single.name, '飙升榜');
      expect(loaded.blocks.length, 2);
      // 先写 .tmp 再 rename，成功后临时文件不该留下
      expect(File('${snapshotFile().path}.tmp').existsSync(), isFalse);

      await snapshots.clear();
      expect(await snapshots.load(), isNull);
    });

    test('脏数据当没有缓存处理，并把文件删掉', () async {
      final File file = snapshotFile();
      await file.writeAsString('{坏掉的 json');

      expect(await store().load(), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('版本不符同样丢掉旧文件', () async {
      final File file = snapshotFile();
      await file.writeAsString(
        jsonEncode(<String, dynamic>{
          'version': HomeSnapshot.version + 1,
          'blocks': <dynamic>[
            <String, dynamic>{'blockCode': HomeBlock.playlistRcmd},
          ],
        }),
      );

      expect(await store().load(), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('空快照不写入', () async {
      await store().save(
        const HomeSnapshot(
          loggedIn: false,
          uid: null,
          nickname: '',
          dailyCover: '',
          entries: <HomeEntry>[],
          blocks: <HomeBlock>[],
          ranks: <Rank>[],
          myPlaylists: <Playlist>[],
        ),
      );
      expect(snapshotFile().existsSync(), isFalse);
    });
  });
}
