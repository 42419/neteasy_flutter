import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/ncm_repository.dart';
import '../pages/main_page.dart';
import '../stores/home_store.dart';
import '../theme/app_theme.dart';

/// 应用根 Widget：注入 Provider + 主题 + 根页面。
///
/// `HomeStore.load()` 不 await：首帧先出骨架，数据到了再 notify。
Widget getRootWidget() {
  final ApiClient api = ApiClient();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeStore>(
        create: (_) => HomeStore(NcmRepository(api))..load(),
      ),
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
