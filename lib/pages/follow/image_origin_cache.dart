import 'package:flutter/foundation.dart';

/// 记住哪些图已经加载过原图。
///
/// 用户在大图页点过一次「原图」之后，再从列表点开同一张就不该再让他点一次：
/// 直接按原图显示，按钮也不再出现。
///
/// 只存本次进程内的结果（key 是原图 URL）。图片本身由
/// `cached_network_image` 落磁盘，所以重启后重新点一次「原图」也是命中缓存、
/// 不会真的重新下载。
@immutable
class ImageOriginCache {
  const ImageOriginCache._();

  static final Set<String> _loaded = <String>{};

  static bool isLoaded(String originUrl) =>
      originUrl.isNotEmpty && _loaded.contains(originUrl);

  static void markLoaded(String originUrl) {
    if (originUrl.isNotEmpty) {
      _loaded.add(originUrl);
    }
  }

  static void forget(String originUrl) {
    _loaded.remove(originUrl);
  }

  @visibleForTesting
  static void clear() => _loaded.clear();
}
