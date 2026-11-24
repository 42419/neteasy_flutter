import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player/netease_audio_handler.dart';
import 'routes/app_router.dart';
import 'utils/cookie_store.dart';
import 'utils/home_snapshot_store.dart';
import 'viewmodels/home_snapshot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 内容延伸到状态栏下方，由各页自己补安全区
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 首页快照必须在第一帧之前读出来，否则会先闪一下骨架屏。
  // 文件几十 KB，这点耗时可以忽略；读失败按「没有缓存」处理。
  final HomeSnapshot? cached = await HomeSnapshotStore().load();
  // 再读本地存储：登录 cookie 要在建 ApiClient 之前准备好
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // cookie 存在加密存储里：解 Keystore 是异步的，所以在这里读好再传给 ApiClient。
  // prefs 只剩一个用途——把旧版明文存的 cookie 迁过来（见 CookieStore.load）。
  final CookieStore cookieStore = CookieStore(legacy: prefs);
  final Map<String, String> cookies = await cookieStore.load();
  // 后台音频服务要在 runApp 之前起好：通知栏、锁屏控制和界面共用同一个 handler。
  // 暂停时保持前台服务不退出：Android 12+ 不允许后台再把它拉起来，
  // 退出后从通知栏点播放会抛 ForegroundServiceStartNotAllowedException。
  final NeteaseAudioHandler audioHandler =
      await AudioService.init<NeteaseAudioHandler>(
        builder: NeteaseAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'top.yunov.neteasy_flutter.audio',
          androidNotificationChannelName: '音乐播放',
          androidStopForegroundOnPause: false,
        ),
      );
  runApp(
    getRootWidget(
      cookieStore: cookieStore,
      cookies: cookies,
      cached: cached,
      audioHandler: audioHandler,
    ),
  );
}
