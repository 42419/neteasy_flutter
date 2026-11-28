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

/// 毫秒时间戳 → `11月26日`。
///
/// 关注页的动态按这个口径显示发布时间（不是「2 天前」）。
/// 不是今年的动态要带上年份，否则去年的 11 月看起来像今年的。
String formatMonthDay(int milliseconds, {DateTime? now}) {
  if (milliseconds <= 0) {
    return '';
  }
  final DateTime time = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final int thisYear = (now ?? DateTime.now()).year;
  if (time.year != thisYear) {
    return '${time.year}年${time.month}月${time.day}日';
  }
  return '${time.month}月${time.day}日';
}

/// 毫秒时间戳 → 「刚刚 / 12分钟前 / 3小时前 / 2天前 / 11月20日」。
///
/// 评论、动态详情用的是相对时间；超过 30 天就退回日期，
/// 免得出现「800天前」这种没人读得懂的数字。
String formatRelativeTime(int milliseconds, {DateTime? now}) {
  if (milliseconds <= 0) {
    return '';
  }
  final DateTime time = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final DateTime current = now ?? DateTime.now();
  final Duration diff = current.difference(time);
  if (diff.inSeconds < 60) {
    return '刚刚';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}分钟前';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}小时前';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays}天前';
  }
  return formatMonthDay(milliseconds, now: current);
}
