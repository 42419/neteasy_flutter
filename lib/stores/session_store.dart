import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/login_qr.dart';
import '../viewmodels/user_profile.dart';

/// 登录会话：扫码流程 + 登录态。
///
/// cookie 的读写由 [ApiClient] 负责（构造时从本地恢复，收到 Set-Cookie 就落盘），
/// 这里只维护「当前是谁」，以及二维码的轮询状态机。
class SessionStore extends ChangeNotifier {
  SessionStore(this._repo, this._api);

  /// 轮询间隔：官方页面也是 2 秒一次
  static const Duration pollInterval = Duration(seconds: 2);

  /// 连续失败多少次后停止轮询（网络抖动不该让二维码直接作废）
  static const int maxPollFailures = 3;

  final NcmRepository _repo;
  final ApiClient _api;

  UserProfile? _profile;
  bool _restoring = true;
  QrLoginState _qrState = QrLoginState.idle;
  Uint8List? _qrBytes;
  String? _qrError;

  /// 每次刷新 +1，旧的轮询协程靠它自杀，避免两个二维码互相覆盖
  int _generation = 0;
  bool _disposed = false;

  UserProfile? get profile => _profile;
  bool get restoring => _restoring;
  bool get loggedIn => _profile != null;
  int? get uid => _profile?.uid;

  QrLoginState get qrState => _qrState;

  /// 已解码的二维码位图；同一实例重复使用，页面 rebuild 不会闪
  Uint8List? get qrBytes => _qrBytes;
  String? get qrError => _qrError;

  /// 登录/登出后通知外部（首页要重新拉每日推荐）
  VoidCallback? onLoginChanged;

  /// 冷启动恢复登录态：cookie 已在 ApiClient 里加载好，这里只确认一次。
  Future<void> restore() async {
    final Result<UserProfile?> result = await _repo.loginProfile();
    if (_disposed) {
      return;
    }
    _profile = result is Ok<UserProfile?> ? result.value : null;
    _restoring = false;
    _safeNotify();
  }

  /// 生成二维码并开始轮询。重复调用会作废上一次的轮询。
  Future<void> startQrLogin() async {
    final int generation = ++_generation;
    _qrState = QrLoginState.loading;
    _qrBytes = null;
    _qrError = null;
    _safeNotify();

    final Result<String> keyResult = await _repo.qrKey();
    if (_disposed || generation != _generation) {
      return;
    }
    final String key = keyResult is Ok<String> ? keyResult.value : '';
    if (key.isEmpty) {
      _qrState = QrLoginState.failed;
      _qrError = keyResult is Err<String>
          ? keyResult.error.message
          : '获取二维码 key 失败';
      _safeNotify();
      return;
    }

    final Result<String> imageResult = await _repo.qrImage(key);
    if (_disposed || generation != _generation) {
      return;
    }
    final String dataUrl = imageResult is Ok<String> ? imageResult.value : '';
    final Uint8List? bytes = _decodeDataUrl(dataUrl);
    if (bytes == null) {
      _qrState = QrLoginState.failed;
      _qrError = imageResult is Err<String>
          ? imageResult.error.message
          : '二维码生成失败';
      _safeNotify();
      return;
    }

    _qrBytes = bytes;
    _qrState = QrLoginState.waiting;
    _safeNotify();
    _poll(generation, key);
  }

  /// 递归等待而不是 Timer.periodic：请求慢时不会堆叠出并发轮询
  Future<void> _poll(int generation, String key) async {
    int failures = 0;
    while (!_disposed && generation == _generation) {
      await Future<void>.delayed(pollInterval);
      if (_disposed || generation != _generation) {
        return;
      }

      final Result<int> result = await _repo.qrCheck(key);
      if (_disposed || generation != _generation) {
        return;
      }

      if (result is Err<int>) {
        failures++;
        if (failures >= maxPollFailures) {
          _qrState = QrLoginState.failed;
          _qrError = '网络不稳定，请点击刷新';
          _safeNotify();
          return;
        }
        continue;
      }
      failures = 0;

      switch ((result as Ok<int>).value) {
        case 801:
          _qrState = QrLoginState.waiting;
        case 802:
          _qrState = QrLoginState.scanned;
        case 800:
          // 过期：停止轮询，等用户点刷新
          _qrState = QrLoginState.expired;
          _safeNotify();
          return;
        case 803:
          _qrState = QrLoginState.success;
          _safeNotify();
          await _fetchProfile();
          return;
        default:
          // 未知状态码按「继续等」处理，避免一次异常响应就断掉流程
          break;
      }
      _safeNotify();
    }
  }

  Future<void> _fetchProfile() async {
    final Result<UserProfile?> result = await _repo.loginProfile();
    if (_disposed) {
      return;
    }
    _profile = result is Ok<UserProfile?> ? result.value : null;
    _safeNotify();
    if (_profile != null) {
      onLoginChanged?.call();
    }
  }

  /// 退出扫码页：停轮询、回到初始态
  void cancelQrLogin() {
    _generation++;
    _qrState = QrLoginState.idle;
    _qrBytes = null;
    _qrError = null;
    _safeNotify();
  }

  /// 登出：清本地 cookie（后端没有 /logout 路由）
  Future<void> logout() async {
    await _api.clearCookies();
    if (_disposed) {
      return;
    }
    _profile = null;
    _generation++;
    _qrState = QrLoginState.idle;
    _qrBytes = null;
    _qrError = null;
    _safeNotify();
    onLoginChanged?.call();
  }

  /// `data:image/png;base64,...` → 位图字节
  Uint8List? _decodeDataUrl(String dataUrl) {
    final int mark = dataUrl.indexOf('base64,');
    if (mark < 0) {
      return null;
    }
    try {
      return base64Decode(dataUrl.substring(mark + 7));
    } catch (_) {
      return null;
    }
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
