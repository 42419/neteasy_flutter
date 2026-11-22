import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/profile_summary.dart';
import '../viewmodels/song.dart';
import '../viewmodels/user_profile.dart';

/// 「我的」页数据。
///
/// 一屏要七个接口：用户详情、会员、徽章、听歌时长、歌单数、歌单列表、听歌周榜
/// （排行那一行的封面）。全部并行发出，任一失败只降级对应区块，
/// 不让整页变错误页——这些统计本来就是锦上添花。
/// 降级的办法是保留上一次的值；第一次就失败的统计保持为 null，页面不显示。
class ProfileStore extends ChangeNotifier {
  ProfileStore(this._repo, {this.uidProvider});

  final NcmRepository _repo;

  /// 当前登录 uid；返回 null 表示未登录
  final int? Function()? uidProvider;

  /// 歌单一次取全。服务端默认只给 30 个，而「近期」排序、「创建 / 收藏」过滤
  /// 都在客户端做，取不全的话列表和标签上的数字会对不上。
  static const int _playlistLimit = 1000;

  ProfileSummary? _data;
  bool _loading = false;
  String? _error;

  /// 并发只认最后一次：登录态变化和下拉刷新可能先后触发
  int _generation = 0;
  bool _disposed = false;

  /// 共享者 uid → 头像。列表接口每次刷新都不带头像，
  /// 缓存住就只在首次（或没命中）时多打一次用户详情。
  final Map<int, String> _sharedAvatarCache = <int, String>{};

  ProfileSummary? get data => _data;

  /// 只有首次加载才置 true；之后刷新保留旧内容，避免列表闪一下
  bool get loading => _loading;

  /// 只在完全没有数据时才有值
  String? get error => _error;

  /// 拉取整页数据。未登录时清空，页面会显示登录入口。
  Future<void> load() async {
    final int? uid = uidProvider?.call();
    if (uid == null) {
      _generation++;
      _data = null;
      _loading = false;
      _error = null;
      _safeNotify();
      return;
    }

    final int generation = ++_generation;
    if (_data == null) {
      _loading = true;
      _error = null;
      _safeNotify();
    }

    // 先全部发出去，再依次取结果：六个接口串行等待会明显拖慢首屏
    final Future<Result<UserProfile>> detailFuture = _repo.userDetailNew(uid);
    final Future<Result<({int level, bool svipActive})>> vipFuture = _repo
        .vipStatus();
    final Future<Result<int>> badgeFuture = _repo.badgeCount(uid);
    final Future<Result<int>> hoursFuture = _repo.listenHours();
    final Future<Result<({int created, int collected})>> subFuture = _repo
        .subcount();
    final Future<Result<List<Playlist>>> listFuture = _repo.userPlaylists(
      uid,
      limit: _playlistLimit,
    );
    final Future<Result<Song?>> topSongFuture = _repo.weeklyTopSong(uid);

    final Result<UserProfile> detail = await detailFuture;
    final Result<({int level, bool svipActive})> vip = await vipFuture;
    final Result<int> badge = await badgeFuture;
    final Result<int> hours = await hoursFuture;
    final Result<({int created, int collected})> sub = await subFuture;
    final Result<List<Playlist>> lists = await listFuture;
    final Result<Song?> topSong = await topSongFuture;

    if (_disposed || generation != _generation) {
      return;
    }

    if (detail is Err<UserProfile>) {
      // 详情都拿不到时保留旧数据；没有旧数据才当整页失败
      if (_data == null) {
        _error = detail.error.message;
      }
      _loading = false;
      _safeNotify();
      return;
    }

    final UserProfile user = (detail as Ok<UserProfile>).value;
    // 其余接口失败时沿用上一次的值，不要用 0 / 空列表把好数据盖掉
    final ProfileSummary? previous = _data;
    _data = ProfileSummary(
      user: user,
      vipLevel: vip is Ok<({int level, bool svipActive})>
          ? vip.value.level
          : (previous?.vipLevel ?? 0),
      svipActive: vip is Ok<({int level, bool svipActive})>
          ? vip.value.svipActive
          : (previous?.svipActive ?? false),
      badgeCount: badge is Ok<int> ? badge.value : previous?.badgeCount,
      listenHours: hours is Ok<int> ? hours.value : previous?.listenHours,
      createdPlaylists: sub is Ok<({int created, int collected})>
          ? sub.value.created
          : previous?.createdPlaylists,
      collectedPlaylists: sub is Ok<({int created, int collected})>
          ? sub.value.collected
          : previous?.collectedPlaylists,
      topSongCover: topSong is Ok<Song?>
          ? (topSong.value?.coverUrl ?? '')
          : (previous?.topSongCover ?? ''),
      playlists: lists is Ok<List<Playlist>>
          ? _sortPlaylists(lists.value)
          : (previous?.playlists ?? const <Playlist>[]),
    );
    _error = null;
    _loading = false;
    _safeNotify();

    // 共享歌单的对方头像不在列表接口里（只给 userId），补一轮再通知
    unawaited(_fillSharedAvatars(generation));
  }

  /// 给共享歌单挑出「对方」并补头像。
  ///
  /// 两个坑：
  /// - `sharedUsers` 里**包含自己**，直接取第一个会把我的头像画到封面角上
  /// - 别人建好共享给我的歌单，共享者列表里只有我自己，真正的「对方」是创建者
  ///
  /// 所以顺序是：先找共享者里不是我的那个，找不到就用创建者（且创建者不是我）。
  /// 创建者头像列表接口直接带，不必再请求；共享者才要去查用户详情。
  /// 整个补查不阻塞首屏——列表先渲染，头像回来再通知。
  Future<void> _fillSharedAvatars(int generation) async {
    final ProfileSummary? data = _data;
    if (data == null) {
      return;
    }
    final int selfUid = data.user.uid;
    if (selfUid == 0) {
      return;
    }

    // 歌单 id → 角标该显示谁的 uid
    final Map<int, int> targetOf = <int, int>{};
    for (final Playlist p in data.playlists) {
      if (p.specialType != Playlist.sharedType ||
          p.sharedAvatarUrl.isNotEmpty) {
        continue;
      }
      final int target = p.sharedBadgeUid(selfUid);
      if (target != 0) {
        targetOf[p.id] = target;
      }
    }
    if (targetOf.isEmpty) {
      return;
    }

    final Map<int, String> avatars = <int, String>{};
    // 创建者头像接口里就有，省一次请求
    for (final Playlist p in data.playlists) {
      final int? target = targetOf[p.id];
      if (target != null &&
          target == p.creatorId &&
          p.creatorAvatarUrl.isNotEmpty) {
        avatars[target] = p.creatorAvatarUrl;
      }
    }

    final List<int> missing = <int>[];
    for (final int uid in targetOf.values.toSet()) {
      if (avatars.containsKey(uid)) {
        continue;
      }
      final String? cached = _sharedAvatarCache[uid];
      if (cached != null) {
        avatars[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isNotEmpty) {
      await Future.wait(
        missing.map((int uid) async {
          final Result<UserProfile> result = await _repo.userDetailNew(uid);
          if (result is Ok<UserProfile> && result.value.avatarUrl.isNotEmpty) {
            avatars[uid] = result.value.avatarUrl;
          }
        }),
      );
      _sharedAvatarCache.addAll(avatars);
    }
    if (_disposed || generation != _generation || avatars.isEmpty) {
      return;
    }
    // 用最新的 _data：等待期间可能又有一次 load 把列表换掉了
    final ProfileSummary? latest = _data;
    if (latest == null) {
      return;
    }

    _data = latest.withPlaylists(<Playlist>[
      for (final Playlist p in latest.playlists)
        switch (avatars[targetOf[p.id]]) {
          final String avatar => p.withSharedAvatar(avatar),
          null => p,
        },
    ]);
    _safeNotify();
  }

  /// 「我喜欢的音乐」固定第一，其余按更新时间从新到旧
  List<Playlist> _sortPlaylists(List<Playlist> input) {
    final List<Playlist> sorted = List<Playlist>.of(input);
    sorted.sort((Playlist a, Playlist b) {
      if (a.isLikedMusic != b.isLikedMusic) {
        return a.isLikedMusic ? -1 : 1;
      }
      return b.updateTime.compareTo(a.updateTime);
    });
    return sorted;
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
