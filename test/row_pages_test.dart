import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/pages/home/widgets/section_parts.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';

void main() {
  /// 条目靠左铺满整行，和真实的歌曲 / 播客行一样。
  /// 不能直接放 Text：RowPages 里是 Column，Text 会被水平居中，量出来的左边距就不对了
  List<Widget> tiles() => <Widget>[
    for (int i = 0; i < 7; i++)
      Align(alignment: Alignment.centerLeft, child: Text('t$i')),
  ];

  /// 400 宽、7 条（t0~t6）→ 3 页：[t0 t1 t2] [t3 t4 t5] [t6]
  Widget host() {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: RowPages(
              rowHeight: 58,
              tiles: tiles(),
            ),
          ),
        ),
      ),
    );
  }

  double left(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;

  testWidgets('第一页贴左边留 16，下一页只在右缘露出一小截', (WidgetTester tester) async {
    await tester.pumpWidget(host());
    expect(left(tester, 't0'), closeTo(AppTheme.pagePadding, 0.5));
    // 页宽 = 400 − 32 = 368，下一页内容从 368 + 16 = 384 开始，右缘只露 16dp
    expect(left(tester, 't3'), closeTo(400 - AppTheme.pagePadding, 0.5));
  });

  testWidgets('拖得不够半页：松手回弹到当前页', (WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.drag(find.byType(PageView), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(left(tester, 't0'), closeTo(AppTheme.pagePadding, 0.5));
  });

  testWidgets('甩一下：吸附到下一页，该页贴到 16 的位置', (WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.fling(find.byType(PageView), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(left(tester, 't3'), closeTo(AppTheme.pagePadding, 0.5));
  });

  testWidgets('宽度变化换了控制器，当前页保留', (WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.fling(find.byType(PageView), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();

    // 屏宽从 400 变到 500：页宽、视口比例都变，控制器要重建
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 500,
              child: RowPages(
                rowHeight: 58,
                tiles: tiles(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(left(tester, 't3'), closeTo(AppTheme.pagePadding, 0.5));
  });
}
