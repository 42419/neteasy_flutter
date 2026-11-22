/// 一首歌的播放地址。
///
/// 地址有时效，只在播放前现取，不要存进歌曲列表或快照里。
class SongUrl {
  const SongUrl({required this.url, this.isTrial = false, this.bitrate = 0});

  final String url;

  /// 只能试听片段（VIP 歌曲，当前账号没有完整播放权限）
  final bool isTrial;

  /// 码率（bps），0 表示未知
  final int bitrate;
}
