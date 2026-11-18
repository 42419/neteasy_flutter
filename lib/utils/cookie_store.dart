import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 登录态 cookie 的本地持久化。
///
/// 后端通过 `Set-Cookie` 下发 MUSIC_U 等字段，重启 App 后仍要带着它们，
/// 否则每次冷启动都会被判成未登录。
class CookieStore {
  CookieStore(this._prefs);

  static const String _key = 'ncm_cookies';

  /// 网易云的登录态 cookie 名，存在即视为已登录
  static const String loginCookieName = 'MUSIC_U';

  final SharedPreferences _prefs;

  Map<String, String> load() {
    final String? raw = _prefs.getString(_key);
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
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> save(Map<String, String> cookies) async {
    if (cookies.isEmpty) {
      await _prefs.remove(_key);
      return;
    }
    await _prefs.setString(_key, jsonEncode(cookies));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  bool get hasLogin => load().containsKey(loginCookieName);
}
