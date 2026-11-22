import 'dart:math';

/// 循环方式。和 audio_service 的 `AudioServiceRepeatMode` 一一对应，
/// 单独定义一份是为了让「下一首怎么选」不依赖插件，能直接单元测试。
enum RepeatKind {
  /// 放到队尾就停
  none,

  /// 单曲循环
  one,

  /// 列表循环
  all,
}

/// 下一首的下标；返回 null 表示播完了，应该停。
///
/// [manual] 为 true 表示用户点了「下一首」：单曲循环下也要真的切歌，
/// 到队尾总是回到开头，不会因为「不循环」而没反应。
int? nextIndex({
  required int current,
  required int length,
  required RepeatKind repeat,
  required bool shuffle,
  required bool manual,
  Random? random,
}) {
  if (length <= 0) {
    return null;
  }
  // 自然播完 + 单曲循环：原地重放
  if (!manual && repeat == RepeatKind.one) {
    return current;
  }
  if (length == 1) {
    return (manual || repeat != RepeatKind.none) ? 0 : null;
  }
  if (shuffle) {
    // 在「除当前以外」的 length-1 首里随机，不会连着放同一首
    final int pick = (random ?? Random()).nextInt(length - 1);
    return pick >= current ? pick + 1 : pick;
  }
  final int next = current + 1;
  if (next < length) {
    return next;
  }
  return (manual || repeat == RepeatKind.all) ? 0 : null;
}

/// 上一首的下标：从队首往前回到队尾。
int previousIndex({required int current, required int length}) {
  if (length <= 0) {
    return 0;
  }
  return (current - 1 + length) % length;
}
