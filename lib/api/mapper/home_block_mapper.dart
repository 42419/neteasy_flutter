import '../../viewmodels/home_block.dart';
import 'json_utils.dart';

/// `/homepage/block/page` → 首页区块列表。
///
/// 服务端把官方首页所有板块塞在一个响应里。注意三种「数据不在 `resources` 里」的情况：
/// - 热门播客：`resources` 为空，名字在 creative 自己的 `uiElement`
/// - 有声书：`creatives` 为空，数据在 `dslData`
/// - 歌手、VIP 标记：在 `resourceExtInfo` 里，`subTitle` 只是收藏数之类的标签
List<HomeBlock> toHomeBlocks(Map<dynamic, dynamic> json) {
  final Object? data = json['data'];
  if (data is! Map) {
    return const <HomeBlock>[];
  }
  final Object? rawBlocks = data['blocks'];
  if (rawBlocks is! List) {
    return const <HomeBlock>[];
  }

  final List<HomeBlock> blocks = <HomeBlock>[];
  for (final Object? raw in rawBlocks) {
    if (raw is! Map) {
      continue;
    }
    final String blockCode = (raw['blockCode'] as String?) ?? '';
    if (blockCode.isEmpty) {
      continue;
    }
    final Map<dynamic, dynamic>? ui = asMap(raw['uiElement']);
    final List<HomeCreative> creatives = <HomeCreative>[];
    final Object? rawCreatives = raw['creatives'];
    if (rawCreatives is List) {
      for (final Object? rc in rawCreatives) {
        if (rc is Map) {
          creatives.add(_toCreative(rc));
        }
      }
    }

    String title = titleOf(ui, 'mainTitle');
    final String subtitle = titleOf(ui, 'subTitle');
    final Map<dynamic, dynamic>? button = asMap(ui?['button']);
    bool hasMore = _isJump(button?['action']);

    // 有声书：标题和「更多」都在 dsl 的 header 里
    final Map<dynamic, dynamic>? bookNode = _findBookNode(raw['dslData']);
    final List<HomeBook> books = bookNode == null
        ? const <HomeBook>[]
        : _toBooks(bookNode);
    if (bookNode != null) {
      final Map<dynamic, dynamic>? header = asMap(bookNode['header']);
      final String headerTitle = (header?['title'] as String?) ?? '';
      if (title.isEmpty && subtitle.isEmpty) {
        title = headerTitle.isNotEmpty
            ? headerTitle
            : (bookNode['blockName'] as String?) ?? '';
      }
      hasMore = header?['showMore'] == true;
    }

    blocks.add(
      HomeBlock(
        blockCode: blockCode,
        showType: (raw['showType'] as String?) ?? '',
        title: title,
        subtitle: subtitle,
        hasMore: hasMore,
        creatives: creatives,
        books: books,
      ),
    );
  }
  return blocks;
}

HomeCreative _toCreative(Map<dynamic, dynamic> rc) {
  final Map<dynamic, dynamic>? cui = asMap(rc['uiElement']);
  final List<HomeResource> resources = <HomeResource>[];
  final Object? rawResources = rc['resources'];
  if (rawResources is List) {
    for (final Object? rr in rawResources) {
      if (rr is Map) {
        resources.add(_toResource(rr));
      }
    }
  }
  return HomeCreative(
    creativeType: (rc['creativeType'] as String?) ?? '',
    action: (rc['action'] as String?) ?? '',
    title: titleOf(cui, 'mainTitle'),
    imageUrl: imageOf(cui),
    labelTexts: labelsOf(cui),
    resources: resources,
  );
}

HomeResource _toResource(Map<dynamic, dynamic> rr) {
  final Map<dynamic, dynamic>? rui = asMap(rr['uiElement']);
  final Map<dynamic, dynamic>? ext = asMap(rr['resourceExtInfo']);
  final Map<dynamic, dynamic>? privilege = asMap(ext?['songPrivilege']);
  final Map<dynamic, dynamic>? dj = asMap(ext?['djProgram']);
  return HomeResource(
    resourceType: (rr['resourceType'] as String?) ?? '',
    resourceId: asId(rr['resourceId']),
    name: (rr['name'] as String?) ?? '',
    title: titleOf(rui, 'mainTitle'),
    subtitle: titleOf(rui, 'subTitle'),
    imageUrl: imageOf(rui),
    labelTexts: labelsOf(rui),
    desc: _podcastDesc(dj?['description']),
    artists: _artistNames(ext?['artists']),
    isVip: asInt(privilege?['fee']) == 1,
    playCount: asInt(ext?['playCount']),
  );
}

/// 播客简介：只取第一行，并去掉开头的 `#话题#`。
///
/// 实测 `djProgram.description` 形如 `#音乐百科全说#8090经典老歌…\nThe brightest…`，
/// 官方列表显示的是去掉话题标签和换行后的正文。
String _podcastDesc(Object? raw) {
  if (raw is! String) {
    return '';
  }
  String text = raw.split('\n').first.trim();
  while (text.startsWith('#')) {
    final int end = text.indexOf('#', 1);
    if (end < 0) {
      break;
    }
    text = text.substring(end + 1).trim();
  }
  return text;
}

List<String> _artistNames(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .whereType<Map>()
      .map((Map item) => (item['name'] as String?) ?? '')
      .where((String name) => name.isNotEmpty)
      .toList(growable: false);
}

/// 是不是「点开去别处」的跳转；`play_all_song` 这种播放指令不算
bool _isJump(Object? action) {
  return action is String && action.startsWith('orpheus://');
}

/// 在 `dslData` 里找有声书那一段：有 `blockName` 且带 `items` 的对象。
/// 外层的 key 是模板生成的（形如 `home_podcast_book_rcmd_list_xxxx`），不能写死。
Map<dynamic, dynamic>? _findBookNode(Object? node, [int depth = 0]) {
  if (depth > 6) {
    return null;
  }
  if (node is Map) {
    if (node['blockName'] is String && node['items'] is List) {
      return node;
    }
    for (final Object? child in node.values) {
      final Map<dynamic, dynamic>? found = _findBookNode(child, depth + 1);
      if (found != null) {
        return found;
      }
    }
  } else if (node is List) {
    for (final Object? child in node) {
      final Map<dynamic, dynamic>? found = _findBookNode(child, depth + 1);
      if (found != null) {
        return found;
      }
    }
  }
  return null;
}

/// `items` 是分组（每组 3 本），拍平成一维
List<HomeBook> _toBooks(Map<dynamic, dynamic> node) {
  final List<HomeBook> books = <HomeBook>[];
  final Object? groups = node['items'];
  if (groups is! List) {
    return books;
  }
  for (final Object? group in groups) {
    if (group is! Map) {
      continue;
    }
    final Object? inner = group['items'];
    if (inner is List) {
      for (final Object? item in inner) {
        if (item is Map) {
          final HomeBook? book = _toBook(item);
          if (book != null) {
            books.add(book);
          }
        }
      }
    } else {
      final HomeBook? book = _toBook(group);
      if (book != null) {
        books.add(book);
      }
    }
  }
  return books;
}

HomeBook? _toBook(Map<dynamic, dynamic> item) {
  final String id = asId(item['resourceId']);
  final String title = (item['title'] as String?) ?? '';
  if (id.isEmpty || title.isEmpty) {
    return null;
  }
  final Map<dynamic, dynamic>? label = asMap(item['label']);
  return HomeBook(
    id: id,
    title: title,
    coverUrl: (item['coverUrl'] as String?) ?? '',
    category: (label?['text'] as String?) ?? '',
    // 官方三行里的灰色简介；实测 12 条都有，仍按容错处理
    desc: (item['desc'] as String?) ?? '',
    playCount: asId(item['playCount']),
    score: asId(item['score']),
  );
}
