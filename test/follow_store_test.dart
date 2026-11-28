import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/api_client.dart';
import 'package:neteasy_flutter/api/ncm_repository.dart';
import 'package:neteasy_flutter/constants/app_constants.dart';
import 'package:neteasy_flutter/stores/follow_store.dart';
import 'package:neteasy_flutter/viewmodels/feed_event.dart';

/// 关注流的三条硬规则：
/// - 未登录不发请求（页面自己显示登录引导）
/// - 近 3 天全显示；不足 3 条就用更旧的补到 3 条（见 [FollowStore.visibleOf]）
/// - 第二次加载（下拉刷新）失败时不能把已有内容清掉

Map<String, dynamic> _event(int id, int timeMs) {
  return <String, dynamic>{
    'id': id,
    'type': 35,
    'eventTime': timeMs,
    'user': <String, dynamic>{
      'userId': 100 + id,
      'nickname': '用户$id',
      'userType': 2,
      'mutual': false,
    },
    'json': '{"msg":"第 $id 条","title":""}',
    'pics': <dynamic>[],
    'info': <String, dynamic>{'likedCount': id, 'commentCount': 0},
  };
}

int _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

FeedEvent _model(int id, int timeMs) {
  return FeedEvent(
    id: id,
    type: FeedEvent.typeText,
    timeMs: timeMs,
    user: const FeedUser(uid: 1, nickname: '某人'),
  );
}

void main() {
  group('visibleOf：近 3 天全显示，不足 3 条补旧的', () {
    test('近 3 天有 5 条：只显示这 5 条，不往前补', () {
      final List<FeedEvent> all = <FeedEvent>[
        for (int i = 0; i < 5; i++) _model(i, _daysAgo(0)),
        _model(9, _daysAgo(10)),
      ];
      expect(FollowStore.visibleOf(all, now: DateTime.now()), hasLength(5));
    });

    test('近 3 天只有 1 条：补 2 条更旧的凑够 3 条', () {
      final List<FeedEvent> all = <FeedEvent>[
        _model(1, _daysAgo(0)),
        _model(2, _daysAgo(4)),
        _model(3, _daysAgo(5)),
        _model(4, _daysAgo(6)),
      ];
      final List<FeedEvent> visible = FollowStore.visibleOf(
        all,
        now: DateTime.now(),
      );
      expect(visible.map((FeedEvent e) => e.id), <int>[1, 2, 3]);
    });

    test('近 3 天一条都没有：显示最旧的 3 条（其实是列表最前面 3 条）', () {
      final List<FeedEvent> all = <FeedEvent>[
        _model(1, _daysAgo(4)),
        _model(2, _daysAgo(5)),
        _model(3, _daysAgo(6)),
        _model(4, _daysAgo(7)),
      ];
      expect(
        FollowStore.visibleOf(
          all,
          now: DateTime.now(),
        ).map((FeedEvent e) => e.id),
        <int>[1, 2, 3],
      );
    });

    test('总共不到 3 条：有多少给多少', () {
      final List<FeedEvent> all = <FeedEvent>[_model(1, _daysAgo(9))];
      expect(FollowStore.visibleOf(all), hasLength(1));
      expect(FollowStore.visibleOf(const <FeedEvent>[]), isEmpty);
    });
  });

  test('未登录：不发请求，列表清空', () async {
    int calls = 0;
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) {
          calls++;
          return _page(<Map<String, dynamic>>[_event(1, _daysAgo(0))]);
        },
      ),
      loggedInProvider: () => false,
    );

    await store.load();

    expect(calls, 0);
    expect(store.events, isEmpty);
    expect(store.error, isNull);
    expect(store.loading, isFalse);
  });

  test('登录：拿到第一页和头像条，官方号不上条', () async {
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) => _page(
          <Map<String, dynamic>>[
            _event(1, _daysAgo(0)),
            _event(2, _daysAgo(1)),
          ],
          lasttime: 111,
          more: true,
        ),
      ),
      loggedInProvider: () => true,
    );

    await store.load();

    expect(store.events, hasLength(2));
    expect(store.contacts, hasLength(3));
    expect(store.stripContacts, hasLength(2), reason: '官方号不进头像条');
  });

  test('第一页不足 3 条：自动带 lasttime 再翻一页', () async {
    final List<String> seen = <String>[];
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) {
          seen.add(lasttime ?? 'first');
          if (lasttime == null) {
            return _page(
              <Map<String, dynamic>>[_event(1, _daysAgo(0))],
              lasttime: 222,
              more: true,
            );
          }
          return _page(<Map<String, dynamic>>[
            _event(2, _daysAgo(4)),
            _event(3, _daysAgo(5)),
          ], lasttime: 333);
        },
      ),
      loggedInProvider: () => true,
    );

    await store.load();

    expect(seen, <String>['first', '222'], reason: '不足 3 条时自动补一页');
    expect(store.events.map((FeedEvent e) => e.id), <int>[1, 2, 3]);
  });

  test('第一页已经够 3 条就不再翻页', () async {
    int calls = 0;
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) {
          calls++;
          return _page(
            <Map<String, dynamic>>[
              for (int i = 0; i < 3; i++) _event(i + 1, _daysAgo(0)),
            ],
            lasttime: 444,
            more: true,
          );
        },
      ),
      loggedInProvider: () => true,
    );

    await store.load();

    expect(calls, 1);
  });

  test('首次失败：给错误；已有内容时失败：保留旧内容', () async {
    bool fail = true;
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) => fail
            ? throw DioException(
                requestOptions: RequestOptions(path: '/event'),
                type: DioExceptionType.badResponse,
              )
            : _page(<Map<String, dynamic>>[_event(1, _daysAgo(0))]),
      ),
      loggedInProvider: () => true,
    );

    await store.load();
    expect(store.events, isEmpty);
    expect(store.error, isNotNull);

    fail = false;
    await store.load();
    expect(store.error, isNull);
    expect(store.events, hasLength(1));

    fail = true;
    await store.load();
    expect(store.events, hasLength(1), reason: '刷新失败不能把已有动态清掉');
  });

  test('reset 之后回到未加载状态', () async {
    final FollowStore store = FollowStore(
      _repo(
        onEvent: (String? lasttime) =>
            _page(<Map<String, dynamic>>[_event(1, _daysAgo(0))]),
      ),
      loggedInProvider: () => true,
    );
    await store.load();
    expect(store.events, isNotEmpty);

    store.reset();

    expect(store.events, isEmpty);
    expect(store.contacts, isEmpty);
  });
}

/// 一页动态的响应体
Map<String, dynamic> _page(
  List<Map<String, dynamic>> events, {
  int lasttime = -1,
  bool more = false,
}) {
  return <String, dynamic>{
    'code': 200,
    'more': more,
    'lasttime': lasttime,
    'event': events,
  };
}

NcmRepository _repo({required Map<String, dynamic> Function(String?) onEvent}) {
  return NcmRepository(
    ApiClient(
      dio:
          Dio(
              BaseOptions(
                baseUrl: AppConstants.backendBaseUrl,
                validateStatus: (int? status) => status != null,
              ),
            )
            ..httpClientAdapter = _FakeAdapter((RequestOptions options) {
              if (options.path == '/event') {
                return _json(onEvent(options.uri.queryParameters['lasttime']));
              }
              if (options.path == '/user/follow/mixed') {
                return _json(<String, dynamic>{
                  'code': 200,
                  'data': <String, dynamic>{
                    'records': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'type': 1,
                        'mutualFollowTime': 1790344602050,
                        'userProfile': <String, dynamic>{
                          'userId': 11,
                          'nickname': '好友甲',
                          'userType': 0,
                        },
                      },
                      <String, dynamic>{
                        'type': 3,
                        'userProfile': <String, dynamic>{
                          'userId': 12,
                          'nickname': '歌手乙',
                          'userType': 2,
                        },
                        'fansGroupInfo': <String, dynamic>{'level': '4'},
                      },
                      <String, dynamic>{
                        'type': 1,
                        'userProfile': <String, dynamic>{
                          'userId': 13,
                          'nickname': '官方号',
                          'userType': 10,
                        },
                      },
                    ],
                  },
                });
              }
              return _json(<String, dynamic>{'code': 200});
            }),
    ),
  );
}

ResponseBody _json(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

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
