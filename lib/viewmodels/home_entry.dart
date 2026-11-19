/// 首页顶部入口卡（每日推荐 / 榜单推荐 / 心动模式…）。
///
/// 数据来自 `/homepage/dragon/ball`：需要登录态，游客返回空数组。
/// 拿不到时页面用内置的默认配置兜底，所以这里的字段都允许为空。
class HomeEntry {
  const HomeEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.action,
  });

  final String id;
  final String title;
  final String subtitle;

  /// 卡片背景图；空表示用内置渐变
  final String imageUrl;

  /// 跳转协议，如 `orpheus://...`
  final String action;

  /// 能用真实数据渲染：至少要有标题
  bool get usable => title.isNotEmpty;
}
