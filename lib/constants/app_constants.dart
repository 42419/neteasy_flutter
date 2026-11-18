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

  /// 首页缺失模块的占位提示文案。
  /// 后端补齐路由后删掉对应条目，页面里直接替换成真实区块。
  static const String pendingCloudVillage = '待接入 /program/recommend';
  static const String pendingHotGenre = '待接入 /personalized/newsong 或标签歌单';
  static const String pendingArtist = '待接入 /personalized/artist（艺人偏好）';
  static const String pendingRadar = '待接入 /personalized/radar';
  static const String pendingProgram = '待接入 /dj/program/recommend';
  static const String pendingVoiceList = '待接入 /voicelist/recommend';
}
