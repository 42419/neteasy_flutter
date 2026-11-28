import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/feed_event.dart';

/// 「关注」页数据：动态流 + 顶部头像条的人。
///
/// 两个接口并行发：动态流失败才算整页失败，头像条只是装饰，失败就空着；
/// 反过来头像条失败也不该把已经拿到的动态清掉。
///
/// 关注流的展示规则（官方行为）：
/// - 近 3 天的动态**全部显示**
/// - 近 3 天不足 3 条（含一条都没有）时，用更旧的动态往下补，补够 3 条
///
/// 规则实现见 [visibleOf]；[load] 负责在第一页本身就不够 3 条时多翻几页。
/// 注意空态文案里的「近 3 天没有新动态」只是提示语，不是「只保留 3 天」。
class FollowStore extends ChangeNotifier {
  FollowStore(this._repo, {this.loggedInProvider});

  /// 每页条数，和官方默认一致
  static const int pageSize = 20;

  /// 不足这个数就用更旧的动态补齐
  static const int minVisible = 3;

  /// 「近 3 天」的界线
  static const Duration window = Duration(days: 3);

  /// 一次 load 最多翻几页去凑那 3 条，防止服务端返回空页时死循环
  static const int _maxFillPages = 3;

  final NcmRepository _repo;

  /// 是否已登录。返回 false 时不发请求，页面显示登录引导
  final bool Function()? loggedInProvider;

  List<FeedEvent> _events = const <FeedEvent>[];
  List<FollowContact> _contacts = const <FollowContact>[];
  bool _loading = false;
  String? _error;
  bool _hasMore = false;
  int _lasttime = -1;

  /// 并发只认最后一次：登录态变化和下拉刷新可能先后触发
  int _generation = 0;
  bool _disposed = false;

  /// 已取到的动态（未裁剪，页面按标签过滤后再走 [visibleOf]）
  List<FeedEvent> get events => _events;

  List<FollowContact> get contacts => _contacts;

  /// 只有首次加载（还没有内容）才置 true，之后刷新保留旧内容
  bool get loading => _loading;

  /// 只在完全没有数据时才有值
  String? get error => _error;

  /// 有没有人带乐迷团：决定头像条首位要不要出现「乐迷团」
  bool get hasFansGroup => _contacts.any((FollowContact c) => c.hasFansGroup);

  /// 头像条要显示的人：好友 + 关注的歌手，官方号和单向关注的普通人不上条
  List<FollowContact> get stripContacts =>
      _contacts.where((FollowContact c) => c.fitsStrip).toList(growable: false);

  /// 关注流的展示规则：近 3 天全显示；不足 3 条时用更旧的补到 3 条。
  ///
  /// 输入必须已按时间倒序。补的是列表里紧随其后的旧动态，
  /// 所以「近 3 天 2 条 + 更旧的 1 条」正好和官方截图一致。
  static List<FeedEvent> visibleOf(List<FeedEvent> all, {DateTime? now}) {
    if (all.isEmpty) {
      return all;
    }
    final int cutoff = (now ?? DateTime.now())
        .subtract(window)
        .millisecondsSinceEpoch;
    int recent = 0;
    for (final FeedEvent event in all) {
      // 时间缺失的条目当「近期」处理，免得被无声丢掉
      if (event.timeMs <= 0 || event.timeMs >= cutoff) {
        recent++;
      }
    }
    final int take = recent >= minVisible ? recent : minVisible;
    if (all.length <= take) {
      return all;
    }
    return all.sublist(0, take);
  }

  /// 拉第一页。未登录时清空并返回。
  Future<void> load() async {
    final bool loggedIn = loggedInProvider?.call() ?? false;
    if (!loggedIn) {
      _generation++;
      _events = const <FeedEvent>[];
      _contacts = const <FollowContact>[];
      _hasMore = false;
      _lasttime = -1;
      _loading = false;
      _error = null;
      _safeNotify();
      return;
    }

    final int generation = ++_generation;
    if (_events.isEmpty) {
      _loading = true;
      _error = null;
      _safeNotify();
    }

    final Future<Result<FeedPage>> pageFuture = _repo.followEvents(
      pagesize: pageSize,
      // 刷新要拿最新的：带上时间戳绕过后端读缓存
      refresh: true,
    );
    final Future<Result<List<FollowContact>>> contactsFuture = _repo
        .followContacts();
    final Result<FeedPage> page = await pageFuture;
    final Result<List<FollowContact>> contacts = await contactsFuture;

    if (_disposed || generation != _generation) {
      return;
    }

    switch (page) {
      case Ok(:final FeedPage value):
        _events = value.events;
        _applyCursor(value);
        _error = null;
      case Err(:final AppError error):
        // 有旧内容就留着，只有第一次就失败才当整页错误
        if (_events.isEmpty) {
          _error = error.message;
        }
    }
    if (contacts is Ok<List<FollowContact>>) {
      _contacts = contacts.value;
    }

    // 第一页本身就不足 3 条（刚关注、或服务端 pagesize 很小时）再多翻几页
    await _fillToMinimum(generation);

    if (_disposed || generation != _generation) {
      return;
    }
    _loading = false;
    _safeNotify();
  }

  /// 用更旧的动态补到 [minVisible] 条；服务端说没有下一页就停
  Future<void> _fillToMinimum(int generation) async {
    for (int i = 0; i < _maxFillPages; i++) {
      if (_events.length >= minVisible || !_hasMore || _lasttime <= 0) {
        return;
      }
      final Result<FeedPage> next = await _repo.followEvents(
        pagesize: pageSize,
        lasttime: _lasttime,
      );
      if (_disposed || generation != _generation) {
        return;
      }
      if (next is! Ok<FeedPage>) {
        return;
      }
      final Set<int> seen = _events.map((FeedEvent e) => e.id).toSet();
      _events = <FeedEvent>[
        ..._events,
        ...next.value.events.where((FeedEvent e) => !seen.contains(e.id)),
      ];
      _applyCursor(next.value);
    }
  }

  void _applyCursor(FeedPage page) {
    _lasttime = page.lasttime;
    _hasMore = page.more && page.lasttime > 0;
  }

  /// 登出时清干净，别把上一个账号的关心流留给下一个人
  void reset() {
    _generation++;
    _events = const <FeedEvent>[];
    _contacts = const <FollowContact>[];
    _hasMore = false;
    _lasttime = -1;
    _loading = false;
    _error = null;
    _safeNotify();
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
