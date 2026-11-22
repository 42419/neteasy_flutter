import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/components/mini_player/mini_player_scrim.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';

/// 遮罩是纯布局，肉眼只能看出「有没有」：
/// 之前 Column 用了默认的 center 对齐，没有子节点的 DecoratedBox / ColoredBox
/// 横向是松约束，宽度塌成 0，整条没画但页面看着一切正常。
void main() {
  testWidgets('铺满宽度，中线以下实色到底', (WidgetTester tester) async {
    const double fade = 30;
    const double barHeight = 94;
    final Color scrim = AppColors.light.scrim;

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: barHeight,
            child: MiniPlayerScrim(color: scrim, fadeHeight: fade),
          ),
        ),
      ),
    );

    final Rect solid = tester.getRect(
      find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == scrim),
    );
    expect(solid.width, 400, reason: '横向必须铺满，塌成 0 就等于没画');
    expect(solid.top, fade);
    expect(solid.height, barHeight - fade);
  });
}
