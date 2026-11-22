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
    this.sharedAvatarUrl = '',
    this.sharedUserIds = const <int>[],
    this.creatorAvatarUrl = '',
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

  /// 共享歌单里**另一个用户**的头像（封面右下角要叠的那个圆头像）。
  ///
  /// 由 `ProfileStore` 选好并回填，不直接从接口取——接口给的信息不够：
  /// `sharedUsers` 里**包含自己**，要按当前 uid 排除；别人建好共享给我的
  /// 歌单，真正的「对方」是创建者而不是共享者列表里的人。
  ///
  /// 空串表示这条歌单不画角标。
  final String sharedAvatarUrl;

  /// 共享者 uid 列表（`sharedUsers[].userId`），**可能包含自己**
  final List<int> sharedUserIds;

  /// 创建者头像：别人建好共享给我的歌单，角标用的就是它（列表接口直接带）
  final String creatorAvatarUrl;

  /// `specialType` 为 300 表示共享歌单
  static const int sharedType = 300;

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

  /// 封面角标该显示谁的头像。
  ///
  /// 优先取「共享者里不是我的那个」；如果共享者只有我自己（别人建好共享给我的歌单），
  /// 就用创建者。返回 0 表示没有对方——我自己的歌单，没共享给任何人。
  int sharedBadgeUid(int selfUid) {
    final int sharer = sharedUserIds.firstWhere(
      (int id) => id != selfUid,
      orElse: () => 0,
    );
    if (sharer != 0) {
      return sharer;
    }
    if (creatorId != 0 && creatorId != selfUid) {
      return creatorId;
    }
    return 0;
  }

  /// 只用来回填共享者头像：列表接口不给头像，其余字段不变
  Playlist withSharedAvatar(String avatarUrl) {
    return Playlist(
      id: id,
      name: name,
      coverUrl: coverUrl,
      playCount: playCount,
      trackCount: trackCount,
      cloudTrackCount: cloudTrackCount,
      copywriter: copywriter,
      specialType: specialType,
      creatorName: creatorName,
      creatorId: creatorId,
      subscribed: subscribed,
      updateTime: updateTime,
      sharedAvatarUrl: avatarUrl,
      sharedUserIds: sharedUserIds,
      creatorAvatarUrl: creatorAvatarUrl,
    );
  }
}
