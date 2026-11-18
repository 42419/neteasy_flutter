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
/// 服务端把官方首页所有板块塞在一个响应里，标题多数落在 `subTitle`
/// （`mainTitle` 在游客态是空串），所以两者都读、由 [HomeBlock.displayTitle] 兜底。
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
        if (rc is! Map) {
          continue;
        }
        final Map<dynamic, dynamic>? cui = _asMap(rc['uiElement']);
        final List<HomeResource> resources = <HomeResource>[];
        final Object? rawResources = rc['resources'];
        if (rawResources is List) {
          for (final Object? rr in rawResources) {
            if (rr is! Map) {
              continue;
            }
            final Map<dynamic, dynamic>? rui = _asMap(rr['uiElement']);
            resources.add(
              HomeResource(
                resourceType: (rr['resourceType'] as String?) ?? '',
                resourceId: _asId(rr['resourceId']),
                name: (rr['name'] as String?) ?? '',
                title: _titleOf(rui, 'mainTitle'),
                subtitle: _titleOf(rui, 'subTitle'),
                imageUrl: _imageOf(rui),
                labelTexts: _labelsOf(rui),
              ),
            );
          }
        }
        creatives.add(
          HomeCreative(
            creativeType: (rc['creativeType'] as String?) ?? '',
            action: (rc['action'] as String?) ?? '',
            imageUrl: _imageOf(cui),
            labelTexts: _labelsOf(cui),
            resources: resources,
          ),
        );
      }
    }
    blocks.add(
      HomeBlock(
        blockCode: blockCode,
        showType: (raw['showType'] as String?) ?? '',
        title: _titleOf(ui, 'mainTitle'),
        subtitle: _titleOf(ui, 'subTitle'),
        creatives: creatives,
      ),
    );
  }
  return blocks;
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

List<String> _labelsOf(Map<dynamic, dynamic>? ui) {
  final Object? raw = ui?['labelTexts'];
  if (raw is! List) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
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
