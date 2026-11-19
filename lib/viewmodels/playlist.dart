/// 歌单（推荐歌单、我的歌单、歌单详情共用）。
///
/// 只有数据与派生 getter；JSON 映射在 `api/ncm_mapper.dart`。
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.playCount = 0,
    this.trackCount = 0,
    this.copywriter,
    this.specialType = 0,
  });

  final int id;
  final String name;
  final String coverUrl;
  final int playCount;
  final int trackCount;

  /// 官方推荐语（「推荐歌单」里偶尔带）
  final String? copywriter;

  /// 歌单类型：5 = 我喜欢的音乐（官方 App 里统一显示成「我喜欢的音乐」）
  final int specialType;

  bool get isLikedMusic => specialType == 5;

  /// 是否算「热门」：播放量过百万。列表里用来决定要不要显示角标。
  bool get isPopular => playCount >= 1000000;
}
