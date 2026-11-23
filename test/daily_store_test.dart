import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/api_client.dart';
import 'package:neteasy_flutter/api/ncm_repository.dart';
import 'package:neteasy_flutter/constants/app_constants.dart';
import 'package:neteasy_flutter/stores/daily_store.dart';
import 'package:neteasy_flutter/stores/home_store.dart';

/// 每日推荐的刷新时刻是 6:00：5:59 打开还属于「昨天那批」，
/// 6:00 一过旧列表就该作废。跨天判定错一小时，用户就会看到前一天的推荐。
///
/// 另外要钉住「首页和每日推荐页共用同一个 in-flight 请求」：
/// 冷启动后立刻点进去不能打两枪。
void main() {
  group('dayKeyOf 按 6:00 分界', () {
    test('5:59 属于前一天', () {
      expect(DailyStore.dayKeyOf(DateTime(2026, 11, 23, 5, 59)), 20261122);
    });

    test('6:00 整属于当天', () {
      expect(DailyStore.dayKeyOf(DateTime(2026, 11, 23, 6)), 20261123);
    });

    test('23:59 仍属于当天', () {
      expect(DailyStore.dayKeyOf(DateTime(2026, 11, 23, 23, 59)), 20261123);
    });

    test('跨年：元旦凌晨属于上一年最后一天', () {
      expect(DailyStore.dayKeyOf(DateTime(2026, 1, 1, 3)), 20251231);
    });
  });

  test('第一次进入且还没请求过：画骨架，且不会顺手发请求', () {
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(counter, dailySongs: <Map<String, dynamic>>[]),
      clock: () => DateTime(2026, 11, 23, 12),
    );

    expect(store.waiting, isTrue);
    expect(counter.value, 0);
  });

  test('load 之后立即可显示', () async {
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(counter, dailySongs: <Map<String, dynamic>>[_songJson(1, '星露谷')]),
      clock: () => DateTime(2026, 11, 23, 12),
    );

    await store.load();

    expect(store.songs, hasLength(1));
    expect(store.waiting, isFalse);
    expect(store.isFresh, isTrue);
  });

  test('凌晨 5:59 仍算「昨天那批」，6:00 一到作废', () async {
    DateTime now = DateTime(2026, 11, 23, 12);
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(counter, dailySongs: <Map<String, dynamic>>[_songJson(1, '星露谷')]),
      clock: () => now,
    );
    await store.load();
    expect(store.isFresh, isTrue);

    now = DateTime(2026, 11, 24, 5, 59);
    expect(store.isFresh, isTrue, reason: '还没到 6:00，昨天那批仍然有效');

    now = DateTime(2026, 11, 24, 6);
    expect(store.isFresh, isFalse);
    expect(store.songs, isEmpty, reason: '跨天后不再对外暴露旧列表');
    expect(store.waiting, isTrue, reason: '等新数据期间画骨架');
  });

  test('接口返回空（未登录）时不再画骨架，也不反复请求', () async {
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(counter, dailySongs: <Map<String, dynamic>>[]),
      clock: () => DateTime(2026, 11, 23, 12),
    );

    await store.load();
    expect(store.songs, isEmpty);
    expect(store.waiting, isFalse, reason: '今天问过了，空就是空，骨架该收起来');

    await store.ensureLoaded();
    expect(counter.value, 1, reason: '同一天不重复请求');
  });

  test('clear 之后回到没有数据的状态', () async {
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(counter, dailySongs: <Map<String, dynamic>>[_songJson(1, '星露谷')]),
      clock: () => DateTime(2026, 11, 23, 12),
    );
    await store.load();
    store.clear();

    expect(store.songs, isEmpty);
    expect(store.isFresh, isFalse);
    expect(store.error, isNull);
    expect(store.waiting, isTrue, reason: '清空后要重新等数据');
  });

  test('首页和每日推荐页共用同一个 in-flight 请求', () async {
    final _Counter counter = _Counter();
    final NcmRepository repo = _repo(
      counter,
      dailySongs: <Map<String, dynamic>>[_songJson(42, '山丘')],
    );
    final DailyStore daily = DailyStore(
      repo,
      clock: () => DateTime(2026, 11, 23, 12),
    );
    final HomeStore home = HomeStore(
      repo,
      uidProvider: () => 1,
      dailyFeed: daily,
    );

    // 首页先发起，用户这时立刻点进每日推荐
    final Future<void> homeLoad = home.load();
    final Future<void> pageLoad = daily.ensureLoaded();
    await Future.wait(<Future<void>>[homeLoad, pageLoad]);

    expect(counter.value, 1, reason: '两次调用只发一次请求');
    expect(daily.songs.single.id, 42);
    expect(home.dailyCover, isNotEmpty, reason: '首页封面取自同一批数据');
  });

  test('换一批必须带 afresh=true，光有 timestamp 拿回的还是同一批', () async {
    Uri? lastUri;
    final _Counter counter = _Counter();
    final DailyStore store = DailyStore(
      _repo(
        counter,
        dailySongs: <Map<String, dynamic>>[_songJson(1, '星露谷')],
        onRequest: (Uri uri) => lastUri = uri,
      ),
      clock: () => DateTime(2026, 11, 23, 12),
    );

    await store.load(refresh: true);

    expect(lastUri?.queryParameters['afresh'], 'true');
    expect(store.refreshing, isFalse, reason: '刷新结束要复位');
  });

  test('加载失败后可以重试，不会被 in-flight 卡住', () async {
    final _Counter counter = _Counter();
    bool fail = true;
    final DailyStore store = DailyStore(
      _repo(
        counter,
        dailySongs: <Map<String, dynamic>>[_songJson(1, '星露谷')],
        shouldFail: () => fail,
      ),
      clock: () => DateTime(2026, 11, 23, 12),
    );

    await store.load();
    expect(store.error, isNotNull);
    expect(counter.value, 1);

    fail = false;
    await store.load();
    expect(store.error, isNull);
    expect(store.songs, hasLength(1));
    expect(counter.value, 2, reason: '失败之后再请求要真的发出去');
  });
}

/// 请求计数：断言「只发一次」用
class _Counter {
  int value = 0;
}

Map<String, dynamic> _songJson(int id, String name) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'al': <String, dynamic>{'picUrl': 'https://p1.music.126.net/$id.jpg'},
    'ar': <Map<String, dynamic>>[
      <String, dynamic>{'name': '某人'},
    ],
  };
}

NcmRepository _repo(
  _Counter counter, {
  required List<Map<String, dynamic>> dailySongs,
  bool Function()? shouldFail,
  void Function(Uri uri)? onRequest,
}) {
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
              if (options.path.contains('recommend/songs')) {
                counter.value++;
                onRequest?.call(options.uri);
                if (shouldFail?.call() ?? false) {
                  return _json(500, <String, dynamic>{
                    'code': 500,
                    'msg': 'boom',
                  });
                }
                return _json(200, <String, dynamic>{
                  'code': 200,
                  'data': <String, dynamic>{'dailySongs': dailySongs},
                });
              }
              return _json(200, <String, dynamic>{
                'code': 200,
                'data': <dynamic>[],
              });
            }),
    ),
  );
}

ResponseBody _json(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
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
