import 'package:material_ui/material_ui.dart';

/// 整页加载失败：一句错误 + 一个「重试」。
///
/// 首页、每日推荐、我的页都要这一块，之前三处各写了一遍。
/// 文字样式留了 [style] 口子：我的页在卡片里，用的比首页小一号。
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.style,
    this.spacing = 16,
  });

  final String message;
  final VoidCallback onRetry;

  /// 不传就用主题默认正文样式
  final TextStyle? style;

  /// 文字与按钮之间的间距
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center, style: style),
            SizedBox(height: spacing),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
