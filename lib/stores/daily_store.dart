import 'package:flutter/foundation.dart';

import '../api/ncm_repository.dart';
import '../utils/result.dart';
import '../viewmodels/song.dart';

/// 每日推荐页状态。
///
/// 「换一批」不清空列表，只在顶部显示转圈，换完直接替换内容；
/// 首次进入才占整页 loading，失败时给重试。
class DailyStore extends ChangeNotifier {
  DailyStore(this._repo);

  final NcmRepository _repo;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<Song> _songs = const <Song>[];
  bool _disposed = false;

  bool get loading => _loading;

  /// 「换一批」进行中
  bool get refreshing => _refreshing;
  String? get error => _error;
  List<Song> get songs => _songs;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
      _safeNotify();
    } else {
      _loading = true;
      _error = null;
      _safeNotify();
    }

    final Result<List<Song>> result = await _repo.dailySongs(refresh: refresh);
    if (_disposed) {
      return;
    }

    if (result is Ok<List<Song>>) {
      _songs = result.value;
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
