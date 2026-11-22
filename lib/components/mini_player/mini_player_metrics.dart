/// 迷你播放器共用的几何值。
///
/// 胶囊高度、黑胶唱片直径、封面直径这三个数在 bar 和 disc 之间共享，
/// 放一处才不会改了一个忘了另一个。
abstract final class MiniPlayerMetrics {
  /// 胶囊高度，同时也是黑胶唱片的直径
  static const double height = 44;

  /// 胶囊上下的留白（底部渐隐的起点也算它）
  static const double gap = 8;
}
