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

  /// 7 条（t0~t6）→ 3 页：[t0 t1 t2] [t3 t4 t5] [t6]
  Widget host(double width) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: RowPages(rowHeight: 58, tiles: tiles()),
          ),
        ),
      ),
    );
  }

  double left(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dx;

  Future<void> flingLeft(WidgetTester tester) async {
    await tester.fling(find.byType(ListView), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
  }

  testWidgets('第一页贴左边留 16，下一页只在右缘露出一小截', (WidgetTester tester) async {
    await tester.pumpWidget(host(400));
    expect(left(tester, 't0'), closeTo(AppTheme.pagePadding, 0.5));
    // 页宽 = 400 − 32 = 368，下一页内容从 368 + 16 = 384 开始，右缘只露 16dp
    expect(left(tester, 't3'), closeTo(400 - AppTheme.pagePadding, 0.5));
  });

  testWidgets('拖得不够半页：松手回弹到当前页', (WidgetTester tester) async {
    await tester.pumpWidget(host(400));
    await tester.drag(find.byType(ListView), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(left(tester, 't0'), closeTo(AppTheme.pagePadding, 0.5));
  });

  testWidgets('甩一下：吸附到下一页，该页贴到 16 的位置', (WidgetTester tester) async {
    await tester.pumpWidget(host(400));
    await flingLeft(tester);
    expect(left(tester, 't3'), closeTo(AppTheme.pagePadding, 0.5));
  });

  testWidgets('最后一页和其他页一样贴左，不会被推到右边、也不露出上一页', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(400));
    await flingLeft(tester);
    await flingLeft(tester);
    // 最后一页（t6）左边距也是 16
    expect(left(tester, 't6'), closeTo(AppTheme.pagePadding, 0.5));
    // 上一页（t3）已经整页滑出屏幕左侧，不会在左边露一截
    expect(left(tester, 't3'), lessThan(0));

    // 到头了再甩，位置不动
    await flingLeft(tester);
    expect(left(tester, 't6'), closeTo(AppTheme.pagePadding, 0.5));
  });

  testWidgets('宽度变化后仍停在原来那一页', (WidgetTester tester) async {
    await tester.pumpWidget(host(400));
    await flingLeft(tester);

    // 屏宽从 400 变到 500：页宽、可滚动范围都变了
    await tester.pumpWidget(host(500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(left(tester, 't3'), closeTo(AppTheme.pagePadding, 0.5));
  });
}
