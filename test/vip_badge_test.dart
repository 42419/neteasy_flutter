import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/components/vip_badge.dart';

/// 徽章高度按 12dp 设计（17.7×12），这里只锁高度——测试环境的字体是等宽兜底字体，
/// 文字宽度和真机对不上，断宽度会假红。
void main() {
  testWidgets('默认高度 12dp，文字是 VIP', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: VipBadge())),
      ),
    );

    expect(tester.getSize(find.byType(VipBadge)).height, 12);
    expect(find.text('VIP'), findsOneWidget);
  });

  testWidgets('高度可调，文字随之缩放', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: VipBadge(height: 18))),
      ),
    );

    expect(tester.getSize(find.byType(VipBadge)).height, 18);
    final Text text = tester.widget<Text>(find.text('VIP'));
    expect(text.style?.fontSize, 18 * 0.75);
  });

  testWidgets('SVIP 也能用同一个组件', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: VipBadge(label: 'SVIP')),
        ),
      ),
    );

    expect(find.text('SVIP'), findsOneWidget);
  });
}
