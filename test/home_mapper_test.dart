import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/ncm_mapper.dart';
import 'package:neteasy_flutter/viewmodels/home_block.dart';

/// 结构取自真实 `/homepage/block/page` 响应（登录态），只保留解析用到的字段。
Map<String, dynamic> _fixture() {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'blocks': <Map<String, dynamic>>[
        <String, dynamic>{
          'blockCode': 'HOMEPAGE_BLOCK_STYLE_RCMD',
          'showType': 'HOMEPAGE_SLIDE_SONGLIST_ALIGN',
          'uiElement': <String, dynamic>{
            'mainTitle': <String, dynamic>{'title': ''},
            'subTitle': <String, dynamic>{'title': '循环不止的「宝藏佳作」'},
            'button': <String, dynamic>{
              'action': 'play_all_song',
              'text': '播放全部',
            },
          },
          'creatives': <Map<String, dynamic>>[
            <String, dynamic>{
              'creativeType': 'SONG_LIST_HOMEPAGE',
              'uiElement': <String, dynamic>{'rcmdShowType': 'DEFAULT'},
              'resources': <Map<String, dynamic>>[
                <String, dynamic>{
                  'resourceType': 'song',
                  'resourceId': '3447962480',
                  'uiElement': <String, dynamic>{
                    'mainTitle': <String, dynamic>{'title': '七宗罪进行曲'},
                    'subTitle': <String, dynamic>{'title': '超51%人收藏'},
                  },
                  'resourceExtInfo': <String, dynamic>{
                    'artists': <Map<String, dynamic>>[
                      <String, dynamic>{'name': 'Shiloh Yu'},
                      <String, dynamic>{'name': '苏牧尧'},
                    ],
                    'songPrivilege': <String, dynamic>{'fee': 1},
                  },
                },
              ],
            },
          ],
        },
        <String, dynamic>{
          'blockCode': 'HOMEPAGE_VOICELIST_RCMD',
          'showType': 'SLIDE_RCMDLIKE_VOICELIST',
          'uiElement': <String, dynamic>{
            'subTitle': <String, dynamic>{'title': '热门播客'},
            'button': <String, dynamic>{
              'action': 'orpheus://nm/mainTab/select?tab=voice',
            },
          },
          'creatives': <Map<String, dynamic>>[
            <String, dynamic>{
              'creativeType': 'voiceList',
              'uiElement': <String, dynamic>{
                'mainTitle': <String, dynamic>{'title': '一首歌一个故事'},
                'labelTexts': <String>[''],
              },
              'resources': <Map<String, dynamic>>[],
            },
          ],
        },
        <String, dynamic>{
          'blockCode': 'HOMEPAGE_VOICEBOOK_RCMD',
          'showType': 'SLIDE_RCMDLIKE_VOICELIST',
          'creatives': null,
          'dslData': <String, dynamic>{
            'blockCode': 'HOMEPAGE_IMG_TEXT_VOICEBOOK_RCMD',
            'home_podcast_book_rcmd_list_x': <String, dynamic>{
              'blockName': 'SVIP专享有声书免费听',
              'header': <String, dynamic>{
                'showMore': true,
                'title': 'SVIP专享有声书免费听',
              },
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'items': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'resourceId': 1480999998,
                      'title': '给孩子的海洋大百科',
                      'coverUrl': 'http://p4.music.126.net/a.jpg',
                      'score': '9.2',
                      'playCount': '49.2万',
                      'label': <String, dynamic>{'text': '学习教育'},
                    },
                  ],
                },
              ],
            },
          },
        },
      ],
    },
  };
}

void main() {
  final List<HomeBlock> blocks = toHomeBlocks(_fixture());

  test('歌手来自 artists，副标题是标签，fee==1 算 VIP', () {
    final HomeResource song = blocks[0].creatives.first.resources.first;
    expect(song.artistLine, 'Shiloh Yu/苏牧尧');
    expect(song.subtitle, '超51%人收藏');
    expect(song.isVip, isTrue);
  });

  test('「播放全部」不算更多入口，orpheus 跳转才算', () {
    expect(blocks[0].hasMore, isFalse);
    expect(blocks[1].hasMore, isTrue);
  });

  test('热门播客：名字在 creative 上，空标签被滤掉', () {
    final HomeCreative creative = blocks[1].creatives.first;
    expect(creative.title, '一首歌一个故事');
    expect(creative.resources, isEmpty);
    expect(creative.labelTexts, isEmpty);
  });

  test('有声书：从 dslData 里按 blockName 找到并拍平', () {
    final HomeBlock book = blocks[2];
    expect(book.creatives, isEmpty);
    expect(book.isEmpty, isFalse);
    expect(book.displayTitle, 'SVIP专享有声书免费听');
    expect(book.hasMore, isTrue);
    expect(book.books.single.title, '给孩子的海洋大百科');
    expect(book.books.single.subtitle, '学习教育 · 49.2万次播放');
    expect(book.books.single.score, '9.2');
  });
}
