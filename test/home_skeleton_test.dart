import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/pages/home/widgets/home_skeleton.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';

/// 骨架屏的行高全是手写常量，溢出只会在真机尺寸下暴露，这里按 406×904dp 渲染一次。
void main() {
  testWidgets('真机尺寸下骨架屏不溢出，且能下拉刷新', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1220, 2712);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: HomeSkeleton(
            onRefresh: () async {
              refreshes++;
            },
          ),
        ),
      ),
    );
    // 扫光在跑，不能用 pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeSkeleton), findsOneWidget);

    // 加载态也要能下拉刷新：从列表顶部往下拖
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(refreshes, 1);
  });
}
