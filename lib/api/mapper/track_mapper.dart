/// `/playlist/track/all?limit=n` → 前 N 首歌名（榜单卡下方展示用）。
///
/// `/toplist` 自带的 `tracks` 是空数组，榜名单只能单独取。
List<String> toTrackNames(Map<dynamic, dynamic> json, {int limit = 3}) {
  final Object? songs = json['songs'];
  if (songs is! List) {
    return const <String>[];
  }
  final List<String> names = <String>[];
  for (final Object? raw in songs) {
    if (raw is! Map) {
      continue;
    }
    final String name = (raw['name'] as String?) ?? '';
    if (name.isNotEmpty) {
      names.add(name);
    }
    if (names.length >= limit) {
      break;
    }
  }
  return names;
}
