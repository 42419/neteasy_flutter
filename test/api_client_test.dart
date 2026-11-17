import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/data/api_client.dart';

/// 用假的 adapter 顶掉真实网络，验证 ApiClient 的契约：
/// cookie 吸收、JSON 解析、后端中文提示优先。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWith(_FakeAdapter adapter) => ApiClient(
  dio: Dio(BaseOptions(baseUrl: ApiClient.baseUrl, validateStatus: (_) => true))
    ..httpClientAdapter = adapter,
);

void main() {
  test('GET 解析 JSON 并吸收 set-cookie，后续请求带上 cookie', () async {
    final adapter = _FakeAdapter((options) async {
      if (options.path == '/login/status') {
        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'account': {'id': 42},
            },
          }),
          200,
          headers: {
            'set-cookie': ['MUSIC_U=token42; Path=/; HttpOnly'],
          },
        );
      }
      return ResponseBody.fromString(jsonEncode({'ok': true}), 200);
    });

    final api = _clientWith(adapter);
    await api.get('/login/status');
    expect(api.cookies['MUSIC_U'], 'token42');

    await api.get('/banner', {'type': '2'});
    expect(adapter.requests.last.queryParameters['type'], '2');
    expect(adapter.requests.last.headers['cookie'], 'MUSIC_U=token42');
  });

  test('非 2xx 时优先抛后端的 neteasyHint', () async {
    final adapter = _FakeAdapter(
      (_) async => ResponseBody.fromString(
        jsonEncode({'neteasyHint': '触发风控，请稍后再试', 'msg': 'risk'}),
        500,
      ),
    );

    expect(
      () => _clientWith(adapter).get('/banner'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', '触发风控，请稍后再试'),
      ),
    );
  });

  test('没有 hint 时退回到 msg + 状态码', () async {
    final adapter = _FakeAdapter(
      (_) async => ResponseBody.fromString(jsonEncode({'msg': '参数错误'}), 400),
    );

    expect(
      () => _clientWith(adapter).get('/banner'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          '参数错误（HTTP 400）',
        ),
      ),
    );
  });
}
