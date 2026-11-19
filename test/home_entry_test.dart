import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/ncm_mapper.dart';
import 'package:neteasy_flutter/viewmodels/home_entry.dart';

void main() {
  test('入口卡：name + bannerUrl 的标准结构', () {
    final List<HomeEntry> entries = toHomeEntries(<String, dynamic>{
      'code': 200,
      'data': <Map<String, dynamic>>[
        {
          'id': 1,
          'name': '每日推荐',
          'subTitle': '今日限定好歌推荐',
          'bannerUrl': 'https://p1.music.126.net/a.jpg',
          'url': 'orpheus://daily',
        },
        {
          'id': 2,
          'name': '榜单推荐',
          'subTitle': '云音乐官方top排行',
          'iconUrl': 'https://p1.music.126.net/b.jpg',
        },
      ],
    });
    expect(entries.length, 2);
    expect(entries[0].title, '每日推荐');
    expect(entries[0].subtitle, '今日限定好歌推荐');
    expect(entries[0].imageUrl, 'https://p1.music.126.net/a.jpg');
    expect(entries[0].action, 'orpheus://daily');
    // 图字段名换一个也要能取到
    expect(entries[1].imageUrl, 'https://p1.music.126.net/b.jpg');
    expect(entries[1].subtitle, '云音乐官方top排行');
  });

  test('入口卡：游客态 data 为空数组', () {
    expect(
      toHomeEntries(<String, dynamic>{'code': 200, 'data': <dynamic>[]}),
      isEmpty,
    );
    expect(toHomeEntries(<String, dynamic>{}), isEmpty);
    expect(toHomeEntries(<String, dynamic>{'data': 'not a list'}), isEmpty);
  });

  test('入口卡：没标题的条目直接丢弃，图片缺失仍保留', () {
    final List<HomeEntry> entries = toHomeEntries(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        {'id': 1, 'name': ''},
        {'id': 2, 'title': '心动模式', 'subtitle': ''},
      ],
    });
    expect(entries.length, 1);
    expect(entries.single.title, '心动模式');
    expect(entries.single.imageUrl, '');
    expect(entries.single.subtitle, '');
    expect(entries.single.usable, isTrue);
  });

  test('入口卡：name 是空串时取 title，副标题和跳转同理', () {
    final List<HomeEntry> entries = toHomeEntries(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        {
          'id': 1,
          'name': '  ',
          'title': '榜单推荐',
          'subTitle': '',
          'subtitle': '云音乐官方 top 排行榜',
          'url': '',
          'action': 'orpheus://toplist',
        },
      ],
    });
    expect(entries.single.title, '榜单推荐');
    expect(entries.single.subtitle, '云音乐官方 top 排行榜');
    expect(entries.single.action, 'orpheus://toplist');
  });
}
