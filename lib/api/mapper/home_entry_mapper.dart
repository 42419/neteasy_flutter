import '../../viewmodels/home_entry.dart';
import 'json_utils.dart';

/// `/homepage/dragon/ball` → 首页入口卡列表。
///
/// 登录态才有数据（实测游客和登录态都返回 `data: []`，字段名按公开实现推断），
/// 多个候选字段一起试：标题 `name`/`title`，图 `bannerUrl`/`iconUrl`/`imageUrl`/`picUrl`。
/// 解析不出来就返回空，页面回落到内置的写死配置。
List<HomeEntry> toHomeEntries(Map<dynamic, dynamic> json) {
  final Object? data = json['data'];
  if (data is! List) {
    return const <HomeEntry>[];
  }
  final List<HomeEntry> entries = <HomeEntry>[];
  for (final Object? raw in data) {
    if (raw is! Map) {
      continue;
    }
    final String title = firstText(<Object?>[raw['name'], raw['title']]);
    if (title.isEmpty) {
      continue;
    }
    entries.add(
      HomeEntry(
        id: '${raw['id'] ?? raw['ballId'] ?? entries.length}',
        title: title,
        subtitle: firstText(<Object?>[
          raw['subTitle'],
          raw['subtitle'],
          raw['desc'],
        ]),
        imageUrl: _firstImage(raw),
        action: firstText(<Object?>[raw['url'], raw['action']]),
      ),
    );
  }
  return entries;
}

/// 入口卡的背景图可能在多个字段里，按优先级试
String _firstImage(Map<dynamic, dynamic> raw) {
  for (final String key in <String>[
    'bannerUrl',
    'iconUrl',
    'imageUrl',
    'picUrl',
    'coverUrl',
    'coverImgUrl',
  ]) {
    final Object? value = raw[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  final Object? image = raw['image'];
  if (image is Map) {
    final Object? url = image['imageUrl'];
    if (url is String && url.isNotEmpty) {
      return url;
    }
  }
  return '';
}
