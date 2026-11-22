import '../../viewmodels/song_url.dart';
import 'json_utils.dart';

/// `/song/url/v1` → 播放地址。
///
/// 没有 `url`（无版权、下架、VIP 且不能试听）返回 null；
/// `freeTrialInfo` 非空说明拿到的只是试听片段。
SongUrl? toSongUrl(Map<dynamic, dynamic> json) {
  final Object? data = json['data'];
  if (data is! List || data.isEmpty) {
    return null;
  }
  final Object? first = data.first;
  if (first is! Map) {
    return null;
  }
  final Object? url = first['url'];
  if (url is! String || url.trim().isEmpty) {
    return null;
  }
  return SongUrl(
    url: url.trim(),
    isTrial: first['freeTrialInfo'] is Map,
    bitrate: asInt(first['br']),
  );
}
