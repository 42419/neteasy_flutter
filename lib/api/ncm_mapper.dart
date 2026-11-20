/// 网易云原始 JSON → viewmodels 的统一入口。
///
/// 具体实现按领域拆在 `mapper/` 下：
/// - `json_utils.dart`    类型容错工具（asInt / asMap / titleOf …）
/// - `library_mapper.dart` 歌单、榜单、歌曲、登录用户
/// - `home_block_mapper.dart` 首页区块（含播客、有声书的特殊结构）
/// - `home_entry_mapper.dart` 首页入口卡
/// - `track_mapper.dart`  榜单前三首歌名
///
/// 所有容错都收敛在这层：关键字段缺失返回 null 让上层过滤，页面里不做 `as` 强转。
library;

export 'mapper/home_block_mapper.dart';
export 'mapper/home_entry_mapper.dart';
export 'mapper/json_utils.dart';
export 'mapper/library_mapper.dart';
export 'mapper/track_mapper.dart';
