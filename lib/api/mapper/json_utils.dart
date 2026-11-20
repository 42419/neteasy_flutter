/// JSON 解析的公共工具，所有 mapper 共用。
///
/// 容错集中在两层：这一层做「类型不对就退回中性值」，各 mapper 再做
/// 「关键字段缺失就返回 null」。页面里一律不写 `as` 强转。
library;

/// JSON 里的数字可能是 int / double / 字符串，统一取 int。
int asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// 把列表字段映射成模型列表，丢弃解析失败的条目。
List<T> mapList<T>(Object? raw, T? Function(Map<dynamic, dynamic>) parse) {
  if (raw is! List) {
    return const <Never>[];
  }
  return raw
      .whereType<Map<dynamic, dynamic>>()
      .map(parse)
      .whereType<T>()
      .toList(growable: false);
}

/// 不是 Map 就返回 null，省掉每处都写类型判断
Map<dynamic, dynamic>? asMap(Object? value) => value is Map ? value : null;

/// 读 `uiElement.<key>.title`
String titleOf(Map<dynamic, dynamic>? ui, String key) {
  final Map<dynamic, dynamic>? node = asMap(ui?[key]);
  return (node?['title'] as String?) ?? '';
}

/// 读 `uiElement.image.imageUrl`
String imageOf(Map<dynamic, dynamic>? ui) {
  final Map<dynamic, dynamic>? image = asMap(ui?['image']);
  return (image?['imageUrl'] as String?) ?? '';
}

/// 标签文字；播客节目常见 `[""]`，空串要滤掉
List<String> labelsOf(Map<dynamic, dynamic>? ui) {
  final Object? raw = ui?['labelTexts'];
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .whereType<String>()
      .where((String text) => text.isNotEmpty)
      .toList(growable: false);
}

/// resourceId 有时是数字有时是字符串，统一成字符串
String asId(Object? value) {
  if (value == null) {
    return '';
  }
  return '$value';
}

/// 候选值里第一个去掉首尾空白后非空的字符串，都没有返回空串
///
/// 用于「同一含义有多个字段名」的场景：不能用 `??`，因为空串不是 null。
String firstText(Iterable<Object?> candidates) {
  for (final Object? value in candidates) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}
