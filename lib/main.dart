import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes/app_router.dart';
import 'utils/home_snapshot_store.dart';
import 'viewmodels/home_snapshot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 复刻官方：内容延伸到状态栏下方，由各页自己补安全区
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 首页快照必须在第一帧之前读出来，否则会先闪一下骨架屏。
  // 文件几十 KB，这点耗时可以忽略；读失败按「没有缓存」处理。
  final HomeSnapshot? cached = await HomeSnapshotStore().load();
  // 再读本地存储：登录 cookie 要在建 ApiClient 之前准备好
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(getRootWidget(prefs: prefs, cached: cached));
}
