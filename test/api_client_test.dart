import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/api_client.dart';
import 'package:neteasy_flutter/constants/app_constants.dart';
import 'package:neteasy_flutter/utils/result.dart';

/// 用假 adapter 顶掉真实网络，验证 ApiClient 的契约：
/// cookie 吸收、JSON 解析、错误落到 `Err` 且优先用后端的 neteasyHint。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  final List<RequestOptions> requests = <RequestOptions>[];

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

ApiClient _clientWith(_FakeAdapter adapter) {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: AppConstants.backendBaseUrl,
        validateStatus: (int? status) => status != null,
      ),
    )..httpClientAdapter = adapter,
  );
}

void main() {
  test('GET 解析 JSON 并吸收 set-cookie，后续请求带上 cookie', () async {
    final _FakeAdapter adapter = _FakeAdapter((RequestOptions options) async {
      if (options.path == '/login/status') {
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'account': <String, dynamic>{'id': 42},
            },
          }),
          200,
          headers: <String, List<String>>{
            'set-cookie': <String>['MUSIC_U=token42; Path=/; HttpOnly'],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'ok': true}),
        200,
      );
    });

    final ApiClient api = _clientWith(adapter);
    final Result<Map<String, dynamic>> login = await api.get('/login/status');
    expect(login, isA<Ok<Map<String, dynamic>>>());
    expect(api.cookies['MUSIC_U'], 'token42');

    await api.get('/banner', <String, String>{'type': '2'});
    expect(adapter.requests.last.queryParameters['type'], '2');
    expect(adapter.requests.last.headers['cookie'], 'MUSIC_U=token42');
  });

  test('非 2xx 返回 Err，且优先用后端的 neteasyHint', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (RequestOptions options) async => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'neteasyHint': '触发风控，请稍后再试',
          'msg': 'risk',
        }),
        500,
      ),
    );

    final Result<Map<String, dynamic>> result = await _clientWith(adapter)
        .get('/banner');
    expect(result, isA<Err<Map<String, dynamic>>>());
    expect((result as Err<Map<String, dynamic>>).error.message, '触发风控，请稍后再试');
  });

  test('没有 hint 时退回到 msg + 状态码', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (RequestOptions options) async => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'msg': '参数错误'}),
        400,
      ),
    );

    final Result<Map<String, dynamic>> result = await _clientWith(adapter)
        .get('/banner');
    expect(
      (result as Err<Map<String, dynamic>>).error.message,
      '参数错误（HTTP 400）',
    );
  });

  test('启动时读到的 cookie 首个请求就带上（登录态冷启动）', () async {
    final _FakeAdapter adapter = _FakeAdapter(
      (RequestOptions options) async => ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'ok': true}),
        200,
      ),
    );

    final ApiClient api = ApiClient(
      dio: Dio(
        BaseOptions(
          baseUrl: AppConstants.backendBaseUrl,
          validateStatus: (int? status) => status != null,
        ),
      )..httpClientAdapter = adapter,
      initialCookies: <String, String>{'MUSIC_U': 'saved42'},
    );

    expect(api.loggedIn, isTrue);
    await api.get('/homepage/block/page');
    expect(adapter.requests.first.headers['cookie'], 'MUSIC_U=saved42');
  });
}
