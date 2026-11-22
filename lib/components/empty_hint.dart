import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// 空态/未实现提示：居中一行灰字。
///
/// 底部导航的「关注」和我的页的「播客 / 笔记」都是这个形态，外层留白交给调用方。
class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.text,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(text, style: AppTheme.caption(AppTheme.colorsOf(context))),
      ),
    );
  }
}
