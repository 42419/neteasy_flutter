import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../utils/cookie_store.dart';
import '../utils/result.dart';

/// 访问内嵌 Rust 后端（`127.0.0.1:19800`）的客户端。
///
/// 三条约定：
/// - 自动携带/回传 cookie，并持久化到 [CookieStore]，登录态跨重启不丢
/// - **只对「连接建立失败」重试**：后端在前台服务里异步拉起，冷启动时第一批请求可能
///   比端口绑定更早，此时是 connection refused 而不是超时。放宽成「任何错误都重试」
///   会吞掉真正的 HTTP 错误，还可能重复提交。
/// - 错误信息优先用后端的 `neteasyHint`（例如触发风控），其次 `msg`，最后才是状态码
///
/// 本地 cookie 由调用方在启动时读好（[CookieStore.load] 要解 Keystore，
/// 没法在同步构造器里完成），通过 `initialCookies` 传进来。
class ApiClient {
  ApiClient({
    Dio? dio,
    CookieStore? cookieStore,
    Map<String, String> initialCookies = const <String, String>{},
  }) : _cookieStorage = cookieStore,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConstants.backendBaseUrl,
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 15),
               // 状态码由后端决定，不让 Dio 自己抛
               validateStatus: (int? status) => status != null,
             ),
           ) {
    if (initialCookies.isNotEmpty) {
      _cookies.addAll(initialCookies);
      _applyCookieHeader();
    }
  }

  /// 冷启动等待后端 listen 的重试次数 × 间隔（合计约 3 秒）
  static const int _maxConnectRetries = 15;
  static const Duration _connectRetryDelay = Duration(milliseconds: 200);

  final Dio _dio;
  final CookieStore? _cookieStorage;

  final Map<String, String> _cookies = <String, String>{};

  Map<String, String> get cookies => Map<String, String>.unmodifiable(_cookies);

  bool get loggedIn => _cookies.containsKey(CookieStore.loginCookieName);

  Future<Result<Map<String, dynamic>>> get(
    String path, [
    Map<String, String>? query,
  ]) {
    return _execute(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Result<Map<String, dynamic>>> post(
    String path, [
    Map<String, String>? form,
  ]) {
    return _execute(() => _dio.post<dynamic>(path, data: form));
  }

  /// 清空登录态（登出用）
  Future<void> clearCookies() async {
    _cookies.clear();
    _dio.options.headers.remove('cookie');
    await _cookieStorage?.clear();
  }

  Future<Result<Map<String, dynamic>>> _execute(
    Future<Response<dynamic>> Function() send,
  ) async {
    DioException? lastConnectError;
    for (int attempt = 0; attempt < _maxConnectRetries; attempt++) {
      try {
        final Response<dynamic> response = await send();
        _absorbCookies(response);

        final int status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          return Err(AppError(_describeHttpError(status, response.data)));
        }

        final Object? data = response.data;
        if (data is Map<String, dynamic>) {
          return Ok(data);
        }
        if (data is String && data.isNotEmpty) {
          final Map<String, dynamic>? decoded = _tryDecode(data);
          if (decoded != null) {
            return Ok(decoded);
          }
        }
        return const Err(AppError('后端返回了空响应'));
      } on DioException catch (e) {
        if (e.type != DioExceptionType.connectionError) {
          return Err(AppError('网络错误：${e.message ?? e.type.name}', cause: e));
        }
        lastConnectError = e;
        if (attempt < _maxConnectRetries - 1) {
          await Future<void>.delayed(_connectRetryDelay);
        }
      } catch (e) {
        return Err(AppError('请求失败：$e', cause: e));
      }
    }
    return Err(
      AppError(
        '连接本地服务失败：${lastConnectError?.message ?? '未知原因'}',
        cause: lastConnectError,
      ),
    );
  }

  /// 解析 Set-Cookie（Dio 给的是原始头，自己拆 name=value）
  void _absorbCookies(Response<dynamic> response) {
    final List<String>? raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) {
      return;
    }
    for (final String line in raw) {
      final String first = line.split(';').first;
      final int eq = first.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final String name = first.substring(0, eq).trim();
      final String value = first.substring(eq + 1).trim();
      if (value.isEmpty || value == 'deleted') {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
    _applyCookieHeader();
    // 落盘不阻塞请求；写失败也不影响本次会话
    unawaited(_cookieStorage?.save(_cookies) ?? Future<void>.value());
  }

  void _applyCookieHeader() {
    if (_cookies.isEmpty) {
      _dio.options.headers.remove('cookie');
      return;
    }
    _dio.options.headers['cookie'] = _cookies.entries
        .map((MapEntry<String, String> e) => '${e.key}=${e.value}')
        .join('; ');
  }

  String _describeHttpError(int status, Object? body) {
    final Map<String, dynamic>? json = body is Map<String, dynamic>
        ? body
        : (body is String ? _tryDecode(body) : null);
    final Object? hint = json?['neteasyHint'];
    if (hint is String && hint.isNotEmpty) {
      return hint;
    }
    final Object? msg = json?['msg'];
    if (msg is String && msg.isNotEmpty && msg != 'null') {
      return '$msg（HTTP $status）';
    }
    return 'HTTP $status';
  }

  Map<String, dynamic>? _tryDecode(String text) {
    try {
      final Object? decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
