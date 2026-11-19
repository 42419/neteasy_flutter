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

  /// 请求网易云图片 CDN（p1/p2/p3/p4.music.126.net）时必须带的头。
  ///
  /// 它的 WAF 会拦 `Dart/3.x (dart:io)` 这类 UA 并直接回 403，同一个 URL 换成
  /// 浏览器 UA 就是 200（实测）。Referer 一并带上，避免以后策略收紧。
  static const Map<String, String> coverHeaders = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Referer': 'https://music.163.com/',
  };
}
