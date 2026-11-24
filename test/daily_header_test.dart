import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/pages/daily/widgets/daily_header.dart';

/// 每日推荐头部：展开时日期可见；上滑后顶栏和「播放全部」一起吸顶，
/// 日期块上移淡出，列表从播放栏下面滚过。
void main() {
  const double statusBar = 24;
  final DateTime date = DateTime(2026, 11, 24);
  final double maxExtent = DailyHeaderDelegate.maxExtentOf(statusBar);
  final double minExtent = DailyHeaderDelegate.minExtentOf(statusBar);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: DailyHeaderDelegate(
                  statusBarHeight: statusBar,
                  date: date,
                  refreshing: false,
                  onPlayAll: () {},
                  onRefresh: () {},
                ),
              ),
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (BuildContext context, int index) =>
                    SizedBox(height: 60, child: Text('row$index')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 日期块的显隐：外层 Opacity 是唯一判定依据（内容被完整构建，只是不可见）
  double dateOpacity(WidgetTester tester) {
    final Iterable<Opacity> layers = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('24'), matching: find.byType(Opacity)),
    );
    expect(layers, isNotEmpty);
    return layers.first.opacity;
  }

  test('收起高度 = 状态栏 + 顶栏 + 播放栏', () {
    expect(
      minExtent,
      statusBar +
          DailyHeaderDelegate.topBarHeight +
          DailyHeaderDelegate.actionBarHeight,
    );
    expect(maxExtent - minExtent, 54 + 48 + 6 + 30 + 30);
  });

  testWidgets('展开时顶栏在状态栏下方，日期完整可见', (WidgetTester tester) async {
    await pumpPage(tester);

    final Rect back = tester.getRect(find.byIcon(Icons.arrow_back));
    expect(back.top, greaterThan(statusBar));
    expect(back.bottom, lessThan(statusBar + DailyHeaderDelegate.topBarHeight));

    expect(dateOpacity(tester), 1);
    final Rect dateRect = tester.getRect(find.text('24'));
    // 日期块起点 = 状态栏 + 顶栏 + 留白
    expect(
      dateRect.top,
      closeTo(statusBar + DailyHeaderDelegate.topBarHeight + 54, 1),
    );
    expect(find.text('查看今日运势'), findsOneWidget);
    expect(find.text('历史日推'), findsOneWidget);
    expect(find.text('播放全部'), findsOneWidget);
  });

  testWidgets('上滑后顶栏和播放全部一起吸顶，日期收起', (WidgetTester tester) async {
    await pumpPage(tester);
    final double backTop = tester.getTopLeft(find.byIcon(Icons.arrow_back)).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // 吸顶：顶栏没跟着内容走
    expect(tester.getTopLeft(find.byIcon(Icons.arrow_back)).dy, backTop);
    // 播放栏也在收起后的头部之内，而且贴在顶栏下面
    final double playTop = tester.getTopLeft(find.text('播放全部')).dy;
    expect(playTop, lessThan(statusBar + minExtent));
    expect(playTop, greaterThan(statusBar + DailyHeaderDelegate.topBarHeight));
    // 日期块淡出到 0，已经钻到顶栏后面
    expect(dateOpacity(tester), 0);
    // 列表照常滚动
    expect(find.text('row0').hitTestable(), findsNothing);

    // 再往上滑：列表继续走，播放栏一动不动
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('播放全部')).dy, playTop);
  });

  testWidgets('滑回顶部后日期恢复显示', (WidgetTester tester) async {
    await pumpPage(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(dateOpacity(tester), 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(dateOpacity(tester), 1);
    expect(find.text('查看今日运势'), findsOneWidget);
  });
}
