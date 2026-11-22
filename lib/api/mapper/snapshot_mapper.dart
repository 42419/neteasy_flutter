/// 首页快照的 JSON 编解码。
///
/// 与 `ncm_mapper` 分开：那边是「上游接口 → 模型」，字段名跟着网易云走；
/// 这边是「模型 → 本地缓存」，字段名自己定。上游改版不会污染已落盘的快照，
/// 反过来快照结构变动也只需抬 `HomeSnapshot.version`。
library;

import '../../viewmodels/home_block.dart';
import '../../viewmodels/home_entry.dart';
import '../../viewmodels/home_snapshot.dart';
import '../../viewmodels/playlist.dart';
import '../../viewmodels/rank.dart';
import 'json_utils.dart';

/// 模型 → 可 `jsonEncode` 的 Map
Map<String, dynamic> snapshotToJson(HomeSnapshot snapshot) {
  return <String, dynamic>{
    'version': HomeSnapshot.version,
    'savedAt': snapshot.savedAt?.millisecondsSinceEpoch,
    'loggedIn': snapshot.loggedIn,
    'uid': snapshot.uid,
    'nickname': snapshot.nickname,
    'dailyCover': snapshot.dailyCover,
    'entries': snapshot.entries.map(_entryToJson).toList(growable: false),
    'blocks': snapshot.blocks.map(_blockToJson).toList(growable: false),
    'ranks': snapshot.ranks.map(_rankToJson).toList(growable: false),
    'myPlaylists': snapshot.myPlaylists
        .map(_playlistToJson)
        .toList(growable: false),
  };
}

/// JSON → 快照。版本不符、结构不对、内容为空都返回 null（当没有缓存处理）。
HomeSnapshot? snapshotFromJson(Object? raw) {
  final Map<dynamic, dynamic>? json = asMap(raw);
  if (json == null || asInt(json['version']) != HomeSnapshot.version) {
    return null;
  }
  final List<HomeBlock> blocks = mapList<HomeBlock>(
    json['blocks'],
    _blockFromJson,
  );
  final List<Rank> ranks = mapList<Rank>(json['ranks'], _rankFromJson);
  final HomeSnapshot snapshot = HomeSnapshot(
    loggedIn: json['loggedIn'] == true,
    uid: json['uid'] == null ? null : asInt(json['uid']),
    nickname: _text(json['nickname']),
    dailyCover: _text(json['dailyCover']),
    entries: mapList<HomeEntry>(json['entries'], _entryFromJson),
    blocks: blocks,
    ranks: ranks,
    myPlaylists: mapList<Playlist>(json['myPlaylists'], _playlistFromJson),
    savedAt: json['savedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(asInt(json['savedAt'])),
  );
  return snapshot.isEmpty ? null : snapshot;
}

// ---------- 编码 ----------

Map<String, dynamic> _entryToJson(HomeEntry entry) {
  return <String, dynamic>{
    'id': entry.id,
    'title': entry.title,
    'subtitle': entry.subtitle,
    'imageUrl': entry.imageUrl,
    'action': entry.action,
  };
}

Map<String, dynamic> _blockToJson(HomeBlock block) {
  return <String, dynamic>{
    'blockCode': block.blockCode,
    'showType': block.showType,
    'title': block.title,
    'subtitle': block.subtitle,
    'hasMore': block.hasMore,
    'creatives': block.creatives.map(_creativeToJson).toList(growable: false),
    'books': block.books.map(_bookToJson).toList(growable: false),
  };
}

Map<String, dynamic> _creativeToJson(HomeCreative creative) {
  return <String, dynamic>{
    'creativeType': creative.creativeType,
    'action': creative.action,
    'title': creative.title,
    'imageUrl': creative.imageUrl,
    'labelTexts': creative.labelTexts,
    'resources': creative.resources
        .map(_resourceToJson)
        .toList(growable: false),
  };
}

Map<String, dynamic> _resourceToJson(HomeResource resource) {
  return <String, dynamic>{
    'resourceType': resource.resourceType,
    'resourceId': resource.resourceId,
    'name': resource.name,
    'title': resource.title,
    'subtitle': resource.subtitle,
    'imageUrl': resource.imageUrl,
    'labelTexts': resource.labelTexts,
    'desc': resource.desc,
    'artists': resource.artists,
    'isVip': resource.isVip,
    'playCount': resource.playCount,
  };
}

Map<String, dynamic> _bookToJson(HomeBook book) {
  return <String, dynamic>{
    'id': book.id,
    'title': book.title,
    'coverUrl': book.coverUrl,
    'category': book.category,
    'desc': book.desc,
    'playCount': book.playCount,
    'score': book.score,
  };
}

Map<String, dynamic> _rankToJson(Rank rank) {
  return <String, dynamic>{
    'id': rank.id,
    'name': rank.name,
    'coverUrl': rank.coverUrl,
    'playCount': rank.playCount,
    'updateFrequency': rank.updateFrequency,
    'toplistType': rank.toplistType,
    'tracks': rank.tracks,
  };
}

Map<String, dynamic> _playlistToJson(Playlist playlist) {
  return <String, dynamic>{
    'id': playlist.id,
    'name': playlist.name,
    'coverUrl': playlist.coverUrl,
    'playCount': playlist.playCount,
    'trackCount': playlist.trackCount,
    'copywriter': playlist.copywriter,
    'specialType': playlist.specialType,
    // 只存原始数据：角标头像由 ProfileStore 按当前登录 uid 现算，
    // 存进快照会把「当时算错/对方换头像」的结果固化下来
    'sharedUserIds': playlist.sharedUserIds,
    'creatorAvatarUrl': playlist.creatorAvatarUrl,
  };
}

// ---------- 解码 ----------

HomeEntry? _entryFromJson(Map<dynamic, dynamic> json) {
  return HomeEntry(
    id: asId(json['id']),
    title: _text(json['title']),
    subtitle: _text(json['subtitle']),
    imageUrl: _text(json['imageUrl']),
    action: _text(json['action']),
  );
}

HomeBlock? _blockFromJson(Map<dynamic, dynamic> json) {
  final String blockCode = _text(json['blockCode']);
  if (blockCode.isEmpty) {
    return null;
  }
  return HomeBlock(
    blockCode: blockCode,
    showType: _text(json['showType']),
    title: _text(json['title']),
    subtitle: _text(json['subtitle']),
    hasMore: json['hasMore'] == true,
    creatives: mapList<HomeCreative>(json['creatives'], _creativeFromJson),
    books: mapList<HomeBook>(json['books'], _bookFromJson),
  );
}

HomeCreative? _creativeFromJson(Map<dynamic, dynamic> json) {
  return HomeCreative(
    creativeType: _text(json['creativeType']),
    action: _text(json['action']),
    title: _text(json['title']),
    imageUrl: _text(json['imageUrl']),
    labelTexts: _textList(json['labelTexts']),
    resources: mapList<HomeResource>(json['resources'], _resourceFromJson),
  );
}

HomeResource? _resourceFromJson(Map<dynamic, dynamic> json) {
  return HomeResource(
    resourceType: _text(json['resourceType']),
    resourceId: asId(json['resourceId']),
    name: _text(json['name']),
    title: _text(json['title']),
    subtitle: _text(json['subtitle']),
    imageUrl: _text(json['imageUrl']),
    labelTexts: _textList(json['labelTexts']),
    desc: _text(json['desc']),
    artists: _textList(json['artists']),
    isVip: json['isVip'] == true,
    playCount: asInt(json['playCount']),
  );
}

HomeBook? _bookFromJson(Map<dynamic, dynamic> json) {
  return HomeBook(
    id: asId(json['id']),
    title: _text(json['title']),
    coverUrl: _text(json['coverUrl']),
    category: _text(json['category']),
    desc: _text(json['desc']),
    playCount: _text(json['playCount']),
    score: _text(json['score']),
  );
}

Rank? _rankFromJson(Map<dynamic, dynamic> json) {
  final int id = asInt(json['id']);
  if (id == 0) {
    return null;
  }
  return Rank(
    id: id,
    name: _text(json['name']),
    coverUrl: _text(json['coverUrl']),
    playCount: asInt(json['playCount']),
    updateFrequency: _text(json['updateFrequency']),
    toplistType: _text(json['toplistType']),
  )..tracks = _textList(json['tracks']);
}

Playlist? _playlistFromJson(Map<dynamic, dynamic> json) {
  return Playlist(
    id: asInt(json['id']),
    name: _text(json['name']),
    coverUrl: _text(json['coverUrl']),
    playCount: asInt(json['playCount']),
    trackCount: asInt(json['trackCount']),
    copywriter: json['copywriter'] == null ? null : _text(json['copywriter']),
    specialType: asInt(json['specialType']),
    sharedUserIds: _intList(json['sharedUserIds']),
    creatorAvatarUrl: _text(json['creatorAvatarUrl']),
  );
}

/// 缓存里的字段一律当不可信输入，类型不对退回空串
String _text(Object? value) => value is String ? value : '';

List<String> _textList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw.whereType<String>().toList(growable: false);
}

List<int> _intList(Object? raw) {
  if (raw is! List) {
    return const <int>[];
  }
  return raw
      .whereType<num>()
      .map((num value) => value.toInt())
      .toList(growable: false);
}
