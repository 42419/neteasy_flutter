import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 复刻官方：内容延伸到状态栏下方，由各页自己补安全区
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 先读本地存储：登录 cookie 要在建 ApiClient 之前准备好
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(getRootWidget(prefs: prefs));
}
