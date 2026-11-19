import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/api/api_client.dart';
import 'package:neteasy_flutter/api/ncm_repository.dart';
import 'package:neteasy_flutter/constants/app_constants.dart';
import 'package:neteasy_flutter/pages/home/home_view.dart';
import 'package:neteasy_flutter/stores/home_store.dart';
import 'package:provider/provider.dart';

/// 用假 adapter 顶掉网络，按真机尺寸（406×904dp）渲染首页，
/// 用来抓行高算错导致的溢出——这类问题肉眼要到真机上才发现。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    },
  );
}

/// 三行播客（含两行标题 + 两行简介的最坏情况）和三行有声书（带 desc、评分）。
Map<String, dynamic> _payload() {
  String longText(String prefix) => '$prefix总有一首歌属于你，用我喜欢的音乐治愈你所有的疲惫和忧伤';

  return <String, dynamic>{
    'code': 200,
    'data': <String, dynamic>{
      'blocks': <Map<String, dynamic>>[
        {
          'blockCode': 'HOMEPAGE_MUSIC_PODCAST_RCMD_BLOCK',
          'uiElement': {
            'subTitle': {'title': '根据你听过的热门节目推荐'},
          },
          'creatives': <Map<String, dynamic>>[
            {
              'resources': <Map<String, dynamic>>[
                for (int i = 0; i < 3; i++)
                  {
                    'resourceType': 'voice',
                    'resourceId': i,
                    'uiElement': {
                      'mainTitle': {'title': longText('车载DJ神曲：掌控好油门，嗨起来！')},
                      'subTitle': {'title': '过耳难忘|最热音乐推荐'},
                      'labelTexts': <String>['超高点攒'],
                      'image': {'imageUrl': 'https://p1.music.126.net/a.jpg'},
                    },
                    'resourceExtInfo': {
                      'djProgram': {'description': longText('#音乐百科全说#')},
                    },
                  },
              ],
            },
          ],
        },
        {
          'blockCode': 'HOMEPAGE_VOICEBOOK_RCMD',
          'dslData': <String, dynamic>{
            'header': {'title': 'SVIP专享有声书免费听', 'showMore': true},
            'home_podcast_book_rcmd_list_x': <String, dynamic>{
              'blockName': 'SVIP专享有声书免费听',
              'items': <Map<String, dynamic>>[
                {
                  'items': <Map<String, dynamic>>[
                    for (int i = 0; i < 3; i++)
                      {
                        'resourceId': i,
                        'title': '《甄嬛传》原著小说解读|孙俪、陈建斌主演，后宫之中华妃与皇后分庭抗礼',
                        'desc': '十三载，再重逢！后宫之中，华妃与皇后分庭抗礼',
                        'score': '9.5',
                        'playCount': '11.5万',
                        'coverUrl': 'https://p1.music.126.net/b.jpg',
                        'label': <String, dynamic>{'text': '小说速读'},
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

ApiClient _client() {
  return ApiClient(
    dio:
        Dio(
            BaseOptions(
              baseUrl: AppConstants.backendBaseUrl,
              validateStatus: (int? status) => status != null,
            ),
          )
          ..httpClientAdapter = _FakeAdapter((RequestOptions options) {
            if (options.path.contains('homepage')) {
              return _json(_payload());
            }
            return _json(<String, dynamic>{'code': 200, 'list': <dynamic>[]});
          }),
  );
}

void main() {
  testWidgets('真机尺寸下播客行 / 有声书行都不溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1220, 2712);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final HomeStore store = HomeStore(NcmRepository(_client()));
    // Dio 依赖真实事件循环，testWidgets 跑在 FakeAsync 上，直接 await 会永久挂起
    await tester.runAsync(store.load);
    await tester.pumpWidget(
      ChangeNotifierProvider<HomeStore>.value(
        value: store,
        child: const MaterialApp(home: Scaffold(body: HomeView())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 有溢出时 RenderFlex 会抛异常，takeException 能抓到
    expect(tester.takeException(), isNull);
    expect(find.text('过耳难忘|最热音乐推荐'), findsWidgets);
    expect(find.text('小说速读'), findsWidgets);
  });
}
