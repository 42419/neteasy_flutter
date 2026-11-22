import 'home_block.dart';
import 'home_entry.dart';
import 'playlist.dart';
import 'rank.dart';

/// 首页首屏快照：上一次成功加载的结果，冷启动时先用它把页面铺出来。
///
/// 先读上一份结果、等网络回来再原地替换，是这类首页的常规做法：
/// 首帧不等网络，列表和滚动位置也不会被刷新打断。
///
/// 快照只存「已经画过一次的真实数据」，不含任何占位或编造内容；
/// 判断新旧、是否属于当前账号，由 `HomeStore` 负责。
class HomeSnapshot {
  const HomeSnapshot({
    required this.loggedIn,
    required this.uid,
    required this.nickname,
    required this.dailyCover,
    required this.entries,
    required this.blocks,
    required this.ranks,
    required this.myPlaylists,
    this.savedAt,
  });

  /// 快照结构版本：模型字段变动时 +1，旧快照直接丢弃，不做兼容。
  ///
  /// 2：歌单加了共享者字段（`sharedUserIds` / `creatorAvatarUrl`）。
  /// 缺这两个字段解析不会崩（退空值），但首屏的共享歌单会少一枚角标；
  /// 按「模型变动就作废」的约定抬版本，不做兼容。
  static const int version = 2;

  /// 落盘时的登录态。与当前 cookie 状态不一致时，只复用公共区块
  final bool loggedIn;

  final int? uid;
  final String nickname;

  /// 每日推荐第一首的封面，首张入口卡的底图
  final String dailyCover;

  /// 顶部入口卡（登录态才有）
  final List<HomeEntry> entries;

  final List<HomeBlock> blocks;
  final List<Rank> ranks;
  final List<Playlist> myPlaylists;
  final DateTime? savedAt;

  /// 没有任何能画的内容，不值得落盘，也不值得用来铺首屏
  bool get isEmpty => blocks.isEmpty && ranks.isEmpty;
}
