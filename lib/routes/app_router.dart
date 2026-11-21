import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/ncm_repository.dart';
import '../pages/main_page.dart';
import '../stores/home_store.dart';
import '../stores/profile_store.dart';
import '../stores/session_store.dart';
import '../theme/app_theme.dart';
import '../utils/cookie_store.dart';
import '../utils/home_snapshot_store.dart';
import '../viewmodels/home_snapshot.dart';

/// 应用根 Widget：注入 Provider + 主题 + 根页面。
///
/// 启动顺序有讲究：先 `session.restore()` 恢复登录态，再 `home.load()` 拉首页。
/// 反过来的话首次 load 读到的 uid 还是 null，「我的歌单」会漏掉一次。
Widget getRootWidget({required SharedPreferences prefs, HomeSnapshot? cached}) {
  final ApiClient api = ApiClient(cookieStore: CookieStore(prefs));
  final NcmRepository repo = NcmRepository(api);
  final SessionStore session = SessionStore(repo, api);
  final HomeStore home = HomeStore(
    repo,
    uidProvider: () => session.uid,
    nicknameProvider: () => session.profile?.nickname,
    snapshotStore: HomeSnapshotStore(),
    loggedInProvider: () => api.loggedIn,
  );
  final ProfileStore profile = ProfileStore(
    repo,
    uidProvider: () => session.uid,
  );

  // 登录/登出后首页和「我的」页都要重拉：两者的数据都依赖登录态
  session.onLoginChanged = () {
    home.load();
    profile.load();
  };
  // 先把上次成功的结果铺到首屏（同步，不阻塞首帧），再恢复登录态并静默刷新。
  // 顺序不能反：restore 完成前 uid 还是 null，先 load 会漏掉「我的歌单」。
  home.hydrate(cached);
  session.restore().whenComplete(() {
    home.load();
    profile.load();
  });

  return MultiProvider(
    providers: [
      // 页面要自己拉数据时（如每日推荐）直接从 Provider 取仓库
      Provider<NcmRepository>.value(value: repo),
      ChangeNotifierProvider<SessionStore>.value(value: session),
      ChangeNotifierProvider<HomeStore>.value(value: home),
      ChangeNotifierProvider<ProfileStore>.value(value: profile),
    ],
    child: MaterialApp(
      title: 'neteasy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // 闪屏不在这里做：Android 12+ 的系统启动屏会盖到首帧绘制完成，
      // Dart 动画会在这段时间白跑，改由 MainActivity 的原生覆盖层接管。
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
