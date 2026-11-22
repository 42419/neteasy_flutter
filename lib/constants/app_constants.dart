/// 全局常量：不随运行期变化的值都放这里，页面里不要再写字面量。
class AppConstants {
  AppConstants._();

  /// 内嵌 Rust 后端的本地端口，必须与 `BackendService.kt` 的 `PORT` 一致。
  static const int backendPort = 19800;

  /// 后端地址（只监听本机回环）。
  static const String backendBaseUrl = 'http://127.0.0.1:$backendPort';

  /// 首页二级 tab
  /// 当前只有「推荐」有内容，其余仅保留选中态。
  static const List<String> homeTabs = <String>[
    '心动',
    '推荐',
    '音乐',
    '播客',
    '听书',
    '福利',
  ];

  /// 首页默认选中的 tab 下标（推荐）。
  static const int homeDefaultTab = 1;

  /// 底部导航：三个图标、没有文字标签，颜色运行时着色（见 `assets/icons/`）。
  static const List<String> bottomTabLabels = <String>['首页', '关注', '我的'];

  static const String tabIconHome = 'assets/icons/tab_home.png';
  static const String tabIconFollow = 'assets/icons/tab_follow.png';
  static const String tabIconMine = 'assets/icons/tab_mine.png';

  /// VIP / SVIP 徽章：横条状，viewBox 36×16 与 40×16，按高度 16 显示
  static const String vipBadge = 'assets/icons/vip/vip.svg';
  static const String svipBadge = 'assets/icons/vip/svip.svg';

  /// 以下三个是「黑 + alpha」位图，运行时用 srcIn 染色
  /// 多选：三横 + 勾
  static const String multiselectIcon = 'assets/icons/multiselect.png';

  /// 行内 MV 徽章：圆角方框 + 播放三角
  static const String mvIcon = 'assets/icons/mv.png';

  /// 行尾更多（⋮）
  static const String moreIcon = 'assets/icons/more.png';

  /// 迷你播放器：封面底下的黑胶唱片，以及右侧的播放列表图标
  static const String vinylDisc = 'assets/images/vinyl.webp';
  static const String queueIcon = 'assets/icons/mini_player/queue.svg';

  /// 请求网易云图片 CDN（music.126.net）时必须带的头。
  ///
  /// CDN 对不同图片来源的 UA 策略不一致：官方运营图任何 UA 都放行，
  /// 用户上传的封面会拦 `Dart/3.x (dart:io)` 并回 403（实测同一 URL
  /// 只换 UA 就通）。这里用官方 Android 客户端 UA，与后端
  /// `util/request.rs` 的 `UA_API_ANDROID` 保持一致。
  static const Map<String, String> coverHeaders = <String, String>{
    'User-Agent':
        'NeteaseMusic/9.5.61.260802021928(9005061);'
        'Dalvik/2.1.0 (Linux; U; Android 12; HBN-AL00 Build/cd737a2.0)',
    'Referer': 'https://music.163.com/',
  };
}
