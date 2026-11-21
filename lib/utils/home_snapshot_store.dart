import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../api/mapper/snapshot_mapper.dart';
import '../viewmodels/home_snapshot.dart';

/// 首页首屏快照的本地持久化。
///
/// 落文件而不是 SharedPreferences：这份东西是「一个几十 KB 的 JSON 文档」，
/// 每次冷启动读一次、成功加载后整体重写一次，文件语义比键值存储更贴切，
/// 也不会把整个 XML 常驻内存。
class HomeSnapshotStore {
  HomeSnapshotStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  /// 文件名。目录由 [getApplicationSupportDirectory] 给出（Android 上是应用私有 files 目录）
  static const String fileName = 'home_snapshot.json';

  /// 测试里换成临时目录；生产走 path_provider
  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final Directory dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  /// 读快照。文件不存在、损坏、版本不符都按「没有缓存」处理，顺手删掉脏数据
  Future<HomeSnapshot?> load() async {
    HomeSnapshot? snapshot;
    File? file;
    try {
      file = await _file();
      if (!await file.exists()) {
        return null;
      }
      snapshot = snapshotFromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      snapshot = null;
    }
    if (snapshot == null && file != null) {
      // 版本升级或数据损坏：留着也只会每次启动白解析一遍
      await _deleteQuietly(file);
    }
    return snapshot;
  }

  /// 写快照。先写临时文件再 rename，避免进程被杀时留下半个 JSON
  Future<void> save(HomeSnapshot snapshot) async {
    if (snapshot.isEmpty) {
      return;
    }
    try {
      final File file = await _file();
      final File temp = File('${file.path}.tmp');
      await temp.writeAsString(
        jsonEncode(snapshotToJson(snapshot)),
        flush: true,
      );
      await temp.rename(file.path);
    } catch (_) {
      // 缓存失败不该影响页面：这次不落盘，下次加载成功还会再写
    }
  }

  Future<void> clear() async {
    try {
      await _deleteQuietly(await _file());
    } catch (_) {
      // 目录都拿不到就没什么可删的
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 删不掉也没关系，下一次 load 仍会当没有缓存
    }
  }
}
