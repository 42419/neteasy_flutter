import '../viewmodels/home_block.dart';
import '../viewmodels/playlist.dart';
import '../viewmodels/rank.dart';
import '../viewmodels/song.dart';
import '../viewmodels/user_profile.dart';

/// 网易云原始 JSON → viewmodels。
///
/// 所有容错都收敛在这里：字段缺失返回 null 让上层过滤，不在页面里做 `as` 强转。
Playlist? toPlaylist(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }
  return Playlist(
    id: id,
    name: name,
    coverUrl:
        (json['picUrl'] as String?) ?? (json['coverImgUrl'] as String?) ?? '',
    playCount: asInt(json['playCount']),
    trackCount: asInt(json['trackCount']),
    copywriter: json['copywriter'] as String?,
    specialType: asInt(json['specialType']),
  );
}

Rank? toRank(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }
  return Rank(
    id: id,
    name: name,
    coverUrl: (json['coverImgUrl'] as String?) ?? '',
    playCount: asInt(json['playCount']),
    updateFrequency: (json['updateFrequency'] as String?) ?? '',
    toplistType: (json['ToplistType'] as String?) ?? '',
  );
}

Song? toSong(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  final String name = (json['name'] as String?) ?? '';
  if (id == 0 || name.isEmpty) {
    return null;
  }

  // 专辑封面：`al.picUrl` / 平铺 `picUrl`
  String cover = '';
  String albumName = '';
  final Object? album = json['al'] ?? json['album'];
  if (album is Map) {
    cover = (album['picUrl'] as String?) ?? '';
    albumName = (album['name'] as String?) ?? '';
  }
  if (cover.isEmpty) {
    cover = (json['picUrl'] as String?) ?? '';
  }

  // 歌手：`ar[]` / `artists[]` / 平铺字符串
  String artist = '';
  final Object? artists = json['ar'] ?? json['artists'];
  if (artists is List) {
    artist = artists
        .whereType<Map>()
        .map((Map item) => (item['name'] as String?) ?? '')
        .where((String part) => part.isNotEmpty)
        .join('/');
  } else if (artists is String) {
    artist = artists;
  }

  return Song(
    id: id,
    name: name,
    artist: artist,
    coverUrl: cover,
    albumName: albumName,
    durationMs: asInt(json['dt'] ?? json['duration']),
  );
}

/// 登录态响应 → 用户资料；未登录返回 null。
///
/// 结构是 `{ data: { code, account, profile } }`——外层没有 code，**code 在 data 里**，
/// 且 `account` 只有 id，昵称头像在 `profile`。
UserProfile? toLoginProfile(Map<dynamic, dynamic> json) {
  final Object? data = json['data'];
  if (data is! Map) {
    return null;
  }
  if (asInt(data['code']) != 200) {
    return null;
  }
  final Object? account = data['account'];
  final int uid = account is Map ? asInt(account['id']) : 0;
  if (uid == 0) {
    return null;
  }
  final Object? profile = data['profile'] ?? account;
  return UserProfile(
    uid: uid,
    nickname: profile is Map ? (profile['nickname'] as String?) ?? '' : '',
    avatarUrl: profile is Map ? (profile['avatarUrl'] as String?) ?? '' : '',
    vipType: profile is Map ? asInt(profile['vipType']) : 0,
  );
}

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
    final Map<dynamic, dynamic>? ui = _asMap(raw['uiElement']);
    final List<HomeCreative> creatives = <HomeCreative>[];
    final Object? rawCreatives = raw['creatives'];
    if (rawCreatives is List) {
      for (final Object? rc in rawCreatives) {
        if (rc is Map) {
          creatives.add(_toCreative(rc));
        }
      }
    }

    String title = _titleOf(ui, 'mainTitle');
    final String subtitle = _titleOf(ui, 'subTitle');
    final Map<dynamic, dynamic>? button = _asMap(ui?['button']);
    bool hasMore = _isJump(button?['action']);

    // 有声书：标题和「更多」都在 dsl 的 header 里
    final Map<dynamic, dynamic>? bookNode = _findBookNode(raw['dslData']);
    final List<HomeBook> books = bookNode == null
        ? const <HomeBook>[]
        : _toBooks(bookNode);
    if (bookNode != null) {
      final Map<dynamic, dynamic>? header = _asMap(bookNode['header']);
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
  final Map<dynamic, dynamic>? cui = _asMap(rc['uiElement']);
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
    title: _titleOf(cui, 'mainTitle'),
    imageUrl: _imageOf(cui),
    labelTexts: _labelsOf(cui),
    resources: resources,
  );
}

HomeResource _toResource(Map<dynamic, dynamic> rr) {
  final Map<dynamic, dynamic>? rui = _asMap(rr['uiElement']);
  final Map<dynamic, dynamic>? ext = _asMap(rr['resourceExtInfo']);
  final Map<dynamic, dynamic>? privilege = _asMap(ext?['songPrivilege']);
  final Map<dynamic, dynamic>? dj = _asMap(ext?['djProgram']);
  return HomeResource(
    resourceType: (rr['resourceType'] as String?) ?? '',
    resourceId: _asId(rr['resourceId']),
    name: (rr['name'] as String?) ?? '',
    title: _titleOf(rui, 'mainTitle'),
    subtitle: _titleOf(rui, 'subTitle'),
    imageUrl: _imageOf(rui),
    labelTexts: _labelsOf(rui),
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
  final String id = _asId(item['resourceId']);
  final String title = (item['title'] as String?) ?? '';
  if (id.isEmpty || title.isEmpty) {
    return null;
  }
  final Map<dynamic, dynamic>? label = _asMap(item['label']);
  return HomeBook(
    id: id,
    title: title,
    coverUrl: (item['coverUrl'] as String?) ?? '',
    category: (label?['text'] as String?) ?? '',
    // 官方三行里的灰色简介；实测 12 条都有，仍按容错处理
    desc: (item['desc'] as String?) ?? '',
    playCount: _asId(item['playCount']),
    score: _asId(item['score']),
  );
}

Map<dynamic, dynamic>? _asMap(Object? value) => value is Map ? value : null;

String _titleOf(Map<dynamic, dynamic>? ui, String key) {
  final Map<dynamic, dynamic>? node = _asMap(ui?[key]);
  return (node?['title'] as String?) ?? '';
}

String _imageOf(Map<dynamic, dynamic>? ui) {
  final Map<dynamic, dynamic>? image = _asMap(ui?['image']);
  return (image?['imageUrl'] as String?) ?? '';
}

/// 标签文字；播客节目常见 `[""]`，空串要滤掉
List<String> _labelsOf(Map<dynamic, dynamic>? ui) {
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
String _asId(Object? value) {
  if (value == null) {
    return '';
  }
  return '$value';
}

/// `/playlist/track/all?limit=n` → 前 N 首歌名（榜单卡下方展示用）。
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
