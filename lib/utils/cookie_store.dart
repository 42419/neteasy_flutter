import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 登录态 cookie 的本地持久化。
///
/// 后端通过 `Set-Cookie` 下发 MUSIC_U 等字段，重启 App 后仍要带着它们，
/// 否则每次冷启动都会被判成未登录。
///
/// 这份东西等价于账号凭据（拿到就能顶号），所以落 `flutter_secure_storage`：
/// Android 侧由 Keystore 包着的密钥做 AES-GCM 加密，不再明文躺在
/// SharedPreferences 里。旧版本存过的 `ncm_cookies` 会在首次读取时迁移过来。
class CookieStore {
  /// [storage] 只给测试换实现；[legacy] 是旧版存明文的 SharedPreferences，
  /// 仅用于迁移，新装用户不传。
  CookieStore({FlutterSecureStorage? storage, SharedPreferences? legacy})
    : _storage = storage ?? const FlutterSecureStorage(),
      _legacyPrefs = legacy;

  /// 加密存储里的键名。沿用旧版 SharedPreferences 的键名，迁移时能直接对上。
  static const String _key = 'ncm_cookies';

  /// 网易云的登录态 cookie 名，存在即视为已登录
  static const String loginCookieName = 'MUSIC_U';

  final FlutterSecureStorage _storage;

  /// 旧版明文存储，只在迁移时读一次；新装用户为 null
  final SharedPreferences? _legacyPrefs;

  /// 读出本地 cookie。
  ///
  /// 必须在发出第一个请求之前 await 完：cookie 是建 `ApiClient` 时一次性读走的，
  /// 晚到的话首个请求不带 MUSIC_U，会被判成未登录。
  ///
  /// 解不开（换机、恢复备份后 Keystore 密钥没了）按「没有缓存」处理，
  /// 不能让启动直接失败。
  Future<Map<String, String>> load() async {
    String? raw;
    try {
      raw = await _storage.read(key: _key);
    } on Object {
      raw = null;
    }
    if (raw == null || raw.isEmpty) {
      raw = await _migrateLegacy();
    }
    return _decode(raw);
  }

  /// 把旧版明文存储里的 cookie 搬到加密存储，成功后删掉旧键。
  Future<String?> _migrateLegacy() async {
    final SharedPreferences? prefs = _legacyPrefs;
    if (prefs == null) {
      return null;
    }
    final String? legacy = prefs.getString(_key);
    if (legacy == null || legacy.isEmpty) {
      return null;
    }
    try {
      await _storage.write(key: _key, value: legacy);
    } on Object {
      // 写不进加密存储就先接着用旧数据，下次启动再试
      return legacy;
    }
    await prefs.remove(_key);
    return legacy;
  }

  Future<void> save(Map<String, String> cookies) async {
    if (cookies.isEmpty) {
      await clear();
      return;
    }
    try {
      await _storage.write(key: _key, value: jsonEncode(cookies));
    } on Object {
      // 落盘失败不影响本次会话：cookie 还在 ApiClient 的内存里
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // 删不掉也别让登出流程炸；内存里的 cookie 已被调用方清掉
    }
    await _legacyPrefs?.remove(_key);
  }

  Map<String, String> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, String>{};
      }
      return decoded.map(
        (Object? k, Object? v) => MapEntry<String, String>('$k', '$v'),
      );
    } on Object {
      return <String, String>{};
    }
  }
}
