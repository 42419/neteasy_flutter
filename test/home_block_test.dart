import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/ncm_mapper.dart';
import 'package:neteasy_flutter/viewmodels/home_block.dart';

/// 结构照 `/homepage/block/page` 的真实响应裁剪：
/// 游客态三个区块，标题在 subTitle、封面是 http、歌曲卡的歌手在 resource 的 subTitle。
const Map<String, dynamic> _payload = <String, dynamic>{
  'code': 200,
  'data': {
    'blocks': <Map<String, dynamic>>[
      {
        'blockCode': 'HOMEPAGE_BLOCK_PLAYLIST_RCMD',
        'showType': 'HOMEPAGE_SLIDE_PLAYLIST',
        'uiElement': {
          'mainTitle': {'title': ''},
          'subTitle': {'title': '推荐歌单'},
        },
        'creatives': <Map<String, dynamic>>[
          {
            'creativeType': 'list',
            'action': 'orpheus://playlist/17744833377?autoplay=0',
            'uiElement': {
              'image': {'imageUrl': 'http://p3.music.126.net/a.jpg'},
              'labelTexts': ['流行'],
            },
            'resources': <Map<String, dynamic>>[
              {
                'resourceType': 'list',
                'resourceId': 17744833377,
                'name': '2026火遍全网的歌曲精选',
                'uiElement': {
                  'mainTitle': {'title': '2026火遍全网的歌曲精选'},
                  'image': {'imageUrl': 'http://p3.music.126.net/a.jpg'},
                  'labelTexts': ['流行', '华语', '网络歌曲'],
                },
              },
            ],
          },
        ],
      },
      {
        'blockCode': 'HOMEPAGE_BLOCK_STYLE_RCMD',
        'showType': 'HOMEPAGE_SLIDE_SONGLIST_ALIGN',
        'uiElement': {
          'subTitle': {'title': '猜你喜欢的「欧美」好歌'},
        },
        'creatives': <Map<String, dynamic>>[
          {
            'creativeType': 'SONG_LIST_HOMEPAGE',
            'resources': <Map<String, dynamic>>[
              {
                'resourceType': 'song',
                'resourceId': 21274655,
                'name': 'Lonely',
                'uiElement': {
                  'mainTitle': {'title': 'Lonely'},
                  'subTitle': {'title': 'Akon'},
                  'image': {'imageUrl': 'http://p3.music.126.net/b.jpg'},
                },
              },
              {
                'resourceType': 'song',
                'resourceId': 21274656,
                'name': 'Right Now',
                'uiElement': {
                  'mainTitle': {'title': 'Right Now'},
                  'subTitle': {'title': 'Akon'},
                },
              },
            ],
          },
        ],
      },
    ],
    'hasMore': false,
  },
};

void main() {
  test('区块标题落在 subTitle 时也能取到', () {
    final List<HomeBlock> blocks = toHomeBlocks(_payload);
    expect(blocks.length, 2);
    expect(blocks[0].title, '');
    expect(blocks[0].subtitle, '推荐歌单');
    // 主标题为空时 displayTitle 兜底到副标题
    expect(blocks[0].displayTitle, '推荐歌单');
    expect(blocks[0].hasHeader, isTrue);
  });

  test('歌单卡：名称、封面、标签都从 resource 取', () {
    final HomeBlock block = toHomeBlocks(_payload)[0];
    final HomeCreative creative = block.creatives.single;
    expect(creative.creativeType, 'list');
    // 歌单卡只有一个资源，不是一卡多歌
    expect(creative.resources.length, 1);
    expect(creative.action, startsWith('orpheus://playlist/'));

    final HomeResource? res = creative.primary;
    expect(res, isNotNull);
    expect(res!.resourceType, 'list');
    expect(res.resourceId, '17744833377');
    expect(res.displayName, '2026火遍全网的歌曲精选');
    expect(res.imageUrl, 'http://p3.music.126.net/a.jpg');
    expect(res.labelTexts, <String>['流行', '华语', '网络歌曲']);
  });

  test('一卡多歌：按 resources 数量识别，歌手在 subTitle', () {
    final HomeBlock block = toHomeBlocks(_payload)[1];
    final HomeCreative creative = block.creatives.single;
    expect(creative.creativeType, 'SONG_LIST_HOMEPAGE');
    expect(creative.resources.length, 2);
    expect(creative.resources[0].isSong, isTrue);
    expect(creative.resources[0].displayName, 'Lonely');
    expect(creative.resources[0].subtitle, 'Akon');
    expect(creative.resources[0].resourceId, '21274655');
  });

  test('缺失字段不抛异常：没有 blocks / 空资源', () {
    expect(toHomeBlocks(<String, dynamic>{}), isEmpty);
    expect(toHomeBlocks(<String, dynamic>{'data': <String, dynamic>{}}), isEmpty);
    final List<HomeBlock> blocks = toHomeBlocks(<String, dynamic>{
      'data': {
        'blocks': <Map<String, dynamic>>[
          {'blockCode': 'X', 'creatives': null},
          {'blockCode': '', 'creatives': <dynamic>[]},
        ],
      },
    });
    // 没有 blockCode 的丢掉，剩下的 creatives 为空但区块保留
    expect(blocks.length, 1);
    expect(blocks.single.blockCode, 'X');
    expect(blocks.single.creatives, isEmpty);
    expect(blocks.single.hasHeader, isFalse);
  });
}
