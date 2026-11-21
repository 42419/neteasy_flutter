/// 歌单（推荐歌单、我的歌单、歌单详情共用）。
///
/// 只有数据与派生 getter；JSON 映射在 `api/mapper/`。
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.playCount = 0,
    this.trackCount = 0,
    this.cloudTrackCount = 0,
    this.copywriter,
    this.specialType = 0,
    this.creatorName = '',
    this.creatorId = 0,
    this.subscribed = false,
    this.updateTime = 0,
  });

  final int id;
  final String name;
  final String coverUrl;
  final int playCount;
  final int trackCount;

  /// 云盘里的歌单独计数，「我的」页显示的总数要把它加上
  final int cloudTrackCount;

  /// 官方推荐语（「推荐歌单」里偶尔带）
  final String? copywriter;

  /// 歌单类型：5 = 我喜欢的音乐（界面统一显示成「我喜欢的音乐」）
  final int specialType;

  /// 创建者昵称，歌单行副标题里要显示
  final String creatorName;

  /// 创建者 uid，用来判断是「创建」还是「收藏」
  final int creatorId;

  /// true = 收藏的，false = 自己建的
  final bool subscribed;

  /// 更新时间（毫秒），「我的」页按它倒序排
  final int updateTime;

  bool get isLikedMusic => specialType == 5;

  /// 是否算「热门」：播放量过百万。列表里用来决定要不要显示角标。
  bool get isPopular => playCount >= 1000000;

  /// 歌曲总数：云盘里的歌也要算
  int get totalTracks => trackCount + cloudTrackCount;

  /// 副标题：「我喜欢的音乐」显示播放次数，其余显示「歌单 · N首 · 创建者」
  String get subtitle {
    if (isLikedMusic) {
      return '$totalTracks首 · $playCount次播放';
    }
    final String owner = creatorName.isEmpty ? '' : ' · $creatorName';
    return '歌单 · $totalTracks首$owner';
  }
}
