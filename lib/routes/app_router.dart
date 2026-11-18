import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/ncm_repository.dart';
import '../pages/main_page.dart';
import '../stores/home_store.dart';
import '../stores/session_store.dart';
import '../theme/app_theme.dart';
import '../utils/cookie_store.dart';

/// 应用根 Widget：注入 Provider + 主题 + 根页面。
///
/// 启动顺序有讲究：先 `session.restore()` 恢复登录态，再 `home.load()` 拉首页。
/// 反过来的话首次 load 读到的 uid 还是 null，每日推荐会漏掉一次。
Widget getRootWidget({required SharedPreferences prefs}) {
  final ApiClient api = ApiClient(cookieStore: CookieStore(prefs));
  final NcmRepository repo = NcmRepository(api);
  final SessionStore session = SessionStore(repo, api);
  final HomeStore home = HomeStore(repo, uidProvider: () => session.uid);

  // 登录/登出后首页要重拉：每日推荐依赖登录态
  session.onLoginChanged = home.load;
  session.restore().whenComplete(home.load);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionStore>.value(value: session),
      ChangeNotifierProvider<HomeStore>.value(value: home),
    ],
    child: MaterialApp(
      title: 'neteasy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // 根页走 home，命名路由只登记其余页面
      home: const MainPage(),
      routes: getRootRoute(),
    ),
  );
}

/// 命名路由表。根页在 MaterialApp.home，这里不登记 '/'。
Map<String, WidgetBuilder> getRootRoute() {
  return <String, WidgetBuilder>{};
}
