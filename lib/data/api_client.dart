import 'dart:convert';

import 'package:dio/dio.dart';

/// 访问内嵌 Rust 后端（http://127.0.0.1:19800）的客户端。
///
/// 语义照搬 Kotlin 版 `data/ApiClient.kt`：
/// - 自动携带/保存 cookie（登录后由服务端 Set-Cookie 更新）
/// - **只对"连接建立失败"重试**：内嵌后端在前台服务里异步拉起，冷启动时第一批请求
///   可能比端口绑定更早，此时是 connection refused 而不是超时。放宽成"任何错误都重试"
///   会让真正的 HTTP 错误被吞掉，且可能重复提交。
/// - 错误信息优先用后端的 `neteasyHint`（例如触发风控），其次 `msg`，最后才是状态码。
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 15),
              // 后端自己决定状态码，不要让 Dio 抛 4xx/5xx
              validateStatus: (_) => true,
            ),
          );

  static const String baseUrl = 'http://127.0.0.1:19800';

  /// 冷启动等待后端 listen(19800) 的重试次数 × 间隔（合计约 3 秒）
  static const int _maxConnectRetries = 15;
  static const Duration _connectRetryDelay = Duration(milliseconds: 200);

  final Dio _dio;

  /// 后端下发的 cookie（MUSIC_U 等），按 name=value 原样保存
  final Map<String, String> _cookies = {};

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) =>
      _execute(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, [Map<String, String>? form]) =>
      _execute(() => _dio.post<dynamic>(path, data: form));

  Future<Map<String, dynamic>> _execute(
    Future<Response<dynamic>> Function() send,
  ) async {
    DioException? lastConnectError;
    for (var attempt = 0; attempt < _maxConnectRetries; attempt++) {
      try {
        final response = await send();
        _absorbCookies(response);
        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw ApiException(_describeHttpError(status, response.data));
        }
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        if (data is String && data.isNotEmpty) {
          final decoded = _tryDecode(data);
          if (decoded != null) return decoded;
        }
        throw ApiException('空响应');
      } on DioException catch (e) {
        if (e.type != DioExceptionType.connectionError) {
          throw ApiException('网络错误：${e.message ?? e.type.name}');
        }
        lastConnectError = e;
        if (attempt < _maxConnectRetries - 1) {
          await Future<void>.delayed(_connectRetryDelay);
        }
      }
    }
    throw ApiException('连接本地服务失败：${lastConnectError?.message ?? '未知原因'}');
  }

  /// 解析 Set-Cookie（Dio 直接给原始头，自己拆 name=value）
  void _absorbCookies(Response<dynamic> response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;
    for (final line in raw) {
      final first = line.split(';').first;
      final eq = first.indexOf('=');
      if (eq <= 0) continue;
      final name = first.substring(0, eq).trim();
      final value = first.substring(eq + 1).trim();
      if (value.isEmpty || value == 'deleted') {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
    // 后端按 Cookie 头识别登录身份，必须回传
    if (_cookies.isNotEmpty) {
      _dio.options.headers['cookie'] = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
    }
  }

  String _describeHttpError(int status, dynamic body) {
    final json = body is Map<String, dynamic>
        ? body
        : (body is String ? _tryDecode(body) : null);
    final hint = json?['neteasyHint'];
    if (hint is String && hint.isNotEmpty) return hint;
    final msg = json?['msg'];
    if (msg is String && msg.isNotEmpty && msg != 'null') {
      return '$msg（HTTP $status）';
    }
    return 'HTTP $status';
  }

  Map<String, dynamic>? _tryDecode(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
