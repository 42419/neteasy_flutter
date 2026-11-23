import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/pages/home/widgets/section_parts.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';

void main() {
  /// 条目铺满整行，和真实的歌曲 / 播客行一样：左边一个 tN，右边一个 rN
  /// （rN 相当于真实行右端的播放键，用来量一页的右边界）。
  /// 不能只放 Text：RowPages 里是 Column，Text 会被水平居中，量出来的左边距就不对了
  List<Widget> tiles() => <Widget>[
    for (int i = 0; i < 7; i++)
      Row(children: <Widget>[Text('t$i'), const Spacer(), Text('r$i')]),
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

  /// 这个文字有没有（哪怕一部分）露在屏幕里。没建出来的算不在屏幕里。
  bool onScreen(WidgetTester tester, String text) {
    final Finder finder = find.text(text);
    return tester.any(finder) && tester.getRect(finder).right > 0;
  }

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

  testWidgets('最后一页和其他页一样贴左，不会被推到右边、也不露出上一页', (WidgetTester tester) async {
    await tester.pumpWidget(host(400));
    await flingLeft(tester);
    await flingLeft(tester);
    // 最后一页（t6）左边距也是 16，和前面的页一样
    expect(left(tester, 't6'), closeTo(AppTheme.pagePadding, 0.5));
    // 上一页的右端（官方里是播放键）已经整个滑出屏幕左侧，不会在左边露一截。
    // 之前用 PageView 时它会被推到 x≈24 的位置露出来
    expect(onScreen(tester, 'r3'), isFalse);
    // 最后一页的右端离屏幕右缘 32dp：页内右边距为 0，页宽 368，400 − 368 = 32
    expect(
      tester.getTopRight(find.text('r6')).dx,
      closeTo(400 - AppTheme.pagePadding * 2, 0.5),
    );

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
