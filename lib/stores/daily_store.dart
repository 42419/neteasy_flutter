import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/song.dart';

/// 每日推荐页状态。
///
/// 「换一批」不清空列表，只在顶部显示转圈，换完直接替换内容；
/// 首次进入才占整页 loading，失败时给重试。
///
/// 数据按天失效：官方每日 6:00 换一批，跨天后旧列表不再对外暴露——
/// 页面据此画骨架等新数据，而不是把昨天的推荐当成今天的。
class DailyStore extends ChangeNotifier {
  DailyStore(this._repo, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final NcmRepository _repo;

  /// 取当前时间。测试里注入固定值来模拟跨天
  final DateTime Function() _clock;

  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  List<Song> _songs = const <Song>[];

  /// 手里这批数据属于哪个「推荐日」，见 [dayKeyOf]
  int _dayKey = 0;

  /// 今天是否已经发过请求（成功或失败都算）。用来区分「还在加载」和
  /// 「加载完就是空」——未登录时接口返回空，不能一直画骨架。
  bool _attempted = false;

  /// 正在飞的那次请求：首页和每日推荐页都会调 [ensureLoaded]，
  /// 复用同一个 future 才不会打两枪
  Future<void>? _inFlight;

  /// 登出/换账号时 +1，回来的旧响应直接丢弃
  int _epoch = 0;

  bool _disposed = false;

  /// 每日推荐换批的时刻
  static const int _switchHour = 6;

  /// 某一时刻属于哪个「推荐日」（yyyyMMdd）。
  ///
  /// 6:00 之前算前一天：凌晨打开拿到的还是昨天那批，不能当成今天的新数据；
  /// 早上 6 点一过，前一天的列表就该作废。
  static int dayKeyOf(DateTime time) {
    final DateTime anchor = time.hour < _switchHour
        ? time.subtract(const Duration(days: 1))
        : time;
    return anchor.year * 10000 + anchor.month * 100 + anchor.day;
  }

  bool get loading => _loading;

  /// 「换一批」进行中
  bool get refreshing => _refreshing;
  String? get error => _error;

  /// 手里这批数据是不是今天的。跨天后为 false，旧列表不再展示
  bool get isFresh => _songs.isNotEmpty && _dayKey == dayKeyOf(_clock());

  /// 可显示的歌曲。跨天后返回空列表，页面据此画骨架
  List<Song> get songs => isFresh ? _songs : const <Song>[];

  /// 今天已经问过接口了（空结果也算，别把「没有推荐」当成「还在加载」）
  bool get _askedToday => _attempted && _dayKey == dayKeyOf(_clock());

  /// 该画骨架：列表空，而且今天还没问过或正在问
  bool get waiting => songs.isEmpty && (_loading || !_askedToday);

  /// 进页面时调用：今天的数据已经在了、或者今天已经问过且没数据，都不再请求。
  ///
  /// 首页也会调它来取首张入口卡的封面，所以两次调用必须共用同一个请求——
  /// 冷启动后立刻点进每日推荐，不能因为首页还没回来就再打一枪。
  Future<void> ensureLoaded() {
    final Future<void>? flying = _inFlight;
    if (flying != null) {
      return flying;
    }
    if (isFresh || _askedToday || _loading) {
      return Future<void>.value();
    }
    return load();
  }

  /// 登出/换账号时清空：每日推荐是按账号生成的，不能留给下一个人
  void clear() {
    _epoch++;
    _inFlight = null;
    _songs = const <Song>[];
    _dayKey = 0;
    _attempted = false;
    _error = null;
    _loading = false;
    _refreshing = false;
    _safeNotify();
  }

  /// 拉数据。非 refresh 的调用会复用正在飞的那次，避免重复请求
  Future<void> load({bool refresh = false}) {
    if (!refresh) {
      final Future<void>? flying = _inFlight;
      if (flying != null) {
        return flying;
      }
    }
    final Future<void> future = _load(refresh: refresh);
    if (!refresh) {
      _inFlight = future;
      // 成败都要放开，否则失败之后页面再也发不出请求
      future.whenComplete(() {
        if (identical(_inFlight, future)) {
          _inFlight = null;
        }
      });
    }
    return future;
  }

  Future<void> _load({required bool refresh}) async {
    final int epoch = _epoch;
    if (refresh) {
      _refreshing = true;
      _safeNotify();
    } else {
      _loading = true;
      _error = null;
      _safeNotify();
    }

    final Result<List<Song>> result = await _repo.dailySongs(refresh: refresh);
    // 等回来的可能是「上一个账号」的响应，登出后一律丢弃
    if (_disposed || epoch != _epoch) {
      return;
    }

    _attempted = true;
    if (result is Ok<List<Song>>) {
      _songs = result.value;
      _dayKey = dayKeyOf(_clock());
      _error = null;
    } else if (result is Err<List<Song>> && _songs.isEmpty) {
      // 已经有内容时不要用错误页盖掉，保留旧列表
      _error = result.error.message;
    }

    _loading = false;
    _refreshing = false;
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
    super.dispose();
  }
}
