/// 格式化工具（纯函数，无状态）。
library;

/// 播放量/收藏数：`1.2万` / `3.4亿`。
///
/// 按网易云 App 的口径（万/亿），与本机其他项目用的 `w` 不同，别混用。
String formatCount(int count) {
  if (count <= 0) {
    return '0';
  }
  if (count >= 100000000) {
    return '${(count / 100000000).toStringAsFixed(1)}亿';
  }
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}万';
  }
  return '$count';
}

/// 毫秒时长 → `mm:ss`；不足一分钟也补零。
String formatDuration(int milliseconds) {
  if (milliseconds <= 0) {
    return '00:00';
  }
  final int totalSeconds = milliseconds ~/ 1000;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  final String mm = minutes.toString().padLeft(2, '0');
  final String ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss';
}
