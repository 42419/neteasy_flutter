import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/components/pull_to_refresh.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';

/// 指示器的跟手逻辑全靠滚动通知驱动，真机上只能靠肉眼看，
/// 这里把「拉多少 → 描边走多少帧」和「松手才算数」两条钉住。
void main() {
  const double threshold = 64;

  /// 手势起点：落在列表靠上的位置，别用 find.text 的居中点——
  /// 那个点可能已经在视口外，拖了也没人接
  const Offset startAt = Offset(400, 200);
  // 描边在第 42 帧长满，整段 78 帧
  const double growth = 42 / 78;

  Widget host({
    required Future<void> Function() onRefresh,
    double threshold = 64,
    ValueNotifier<double>? externalExtraTop,
    Color? indicatorColor,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: PullToRefresh(
          onRefresh: onRefresh,
          threshold: threshold,
          extraTop: externalExtraTop,
          indicatorColor: indicatorColor,
          builder: (BuildContext context, double extraTop) => CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(child: SizedBox(height: extraTop)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('内容'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
  }

  /// 当前越界距离：bouncing 物理下再往下拉 pixels 就是负的
  double pulled(WidgetTester tester) {
    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable),
    );
    return math.max(0, -scrollable.position.pixels);
  }

  double progress(WidgetTester tester) {
    final Lottie note = tester.widget<Lottie>(find.byType(Lottie));
    return note.controller!.value;
  }

  testWidgets('下拉时描边进度跟着手指走，到阈值就长满', (WidgetTester tester) async {
    await tester.pumpWidget(host(onRefresh: () async {}));
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    // 前 18 是触摸 slop，剩下的才落到滚动上
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    final double pulledOnce = pulled(tester);
    expect(pulledOnce, greaterThan(20));
    expect(pulledOnce, lessThan(threshold));
    // 没拉够阈值：进度就是下拉比例，不是自己播
    expect(progress(tester), closeTo(pulledOnce / threshold * growth, 1e-9));
    final double indicatorTop = tester.getTopLeft(find.byType(Lottie)).dy;
    expect(indicatorTop, greaterThan(0));

    // 继续拉到超过阈值
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(pulled(tester), greaterThan(threshold));
    // 描边停在长满那一帧，不再往前走
    expect(progress(tester), closeTo(growth, 1e-9));

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('没拉到出现距离，指示器压根不露面', (WidgetTester tester) async {
    await tester.pumpWidget(host(onRefresh: () async {}));
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    // 20 里先扣掉 18 的触摸 slop，真正落到滚动上的只有一点点
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('松手后只回弹一次，落定之后不许再动', (WidgetTester tester) async {
    final Completer<void> done = Completer<void>();
    await tester.pumpWidget(host(onRefresh: () => done.future));
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();

    final List<double> trace = <double>[];
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      trace.add(tester.getTopLeft(find.text('内容')).dy);
    }

    // 回弹只朝一个方向走：中间反弹回去就是「弹两下」
    for (int i = 1; i < trace.length; i++) {
      expect(
        trace[i],
        lessThanOrEqualTo(trace[i - 1] + 0.01),
        reason:
            '第 $i 帧往回弹了：${trace.map((double v) => v.toStringAsFixed(1)).toList()}',
      );
    }

    // 收回曲线走完（340ms，留点余量取到 420ms）必须钉死不动——
    // 之后物理还在慢慢爬，得由留白把它吃掉
    final double settled = trace[26];
    for (int i = 27; i < trace.length; i++) {
      expect(trace[i], closeTo(settled, 0.05), reason: '第 $i 帧还在飘');
    }

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('刷新完成后指示器收起、内容回到原位', (WidgetTester tester) async {
    final Completer<void> done = Completer<void>();
    await tester.pumpWidget(host(onRefresh: () => done.future));
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Lottie), findsOneWidget, reason: '刷新中指示器要还在');

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(Lottie), findsNothing, reason: '刷新完了指示器必须收起');
    expect(tester.getTopLeft(find.text('内容')).dy, closeTo(24, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('松手才判刷新，没拉够不触发', (WidgetTester tester) async {
    int calls = 0;
    final Completer<void> done = Completer<void>();
    await tester.pumpWidget(
      host(
        onRefresh: () {
          calls++;
          return done.future;
        },
      ),
    );
    await tester.pump();

    // 拉一点点就松手：不算
    TestGesture gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(calls, 0);

    // 这次拉够再松手
    gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    expect(calls, 0, reason: '手指还没抬起来就不该刷新');
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(calls, 1);

    // 刷新悬停：内容被留白撑住，指示器保持可见
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Lottie), findsOneWidget);

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // 只触发一次，回弹不会再来一遍
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('传入外部 extraTop：悬停时同步留白，刷新完成后归零', (WidgetTester tester) async {
    final ValueNotifier<double> extraTop = ValueNotifier<double>(0);
    addTearDown(extraTop.dispose);
    final Completer<void> done = Completer<void>();
    await tester.pumpWidget(
      host(onRefresh: () => done.future, externalExtraTop: extraTop),
    );
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    // 页面靠它把固定在滚动视图后面的背景一起推下去，悬停时必须有值
    expect(extraTop.value, greaterThan(0));

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(extraTop.value, closeTo(0, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('可指定指示器颜色：压在深色头部上用白色', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(onRefresh: () async {}, indicatorColor: const Color(0xFFFFFFFF)),
    );
    await tester.pump();

    final TestGesture gesture = await tester.startGesture(startAt);
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(find.byType(Lottie), findsOneWidget);

    // 音符素材本身是纯黑描边，颜色全靠 ColorFilter 整体替换：
    // 这里错了，压在深色头部上的指示器就等于隐形
    final ColorFiltered filtered = tester.widget<ColorFiltered>(
      find.ancestor(
        of: find.byType(Lottie),
        matching: find.byType(ColorFiltered),
      ),
    );
    expect(
      filtered.colorFilter,
      const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn),
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('外部传入的 extraTop 在 PullToRefresh 销毁后仍可用', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<double> extraTop = ValueNotifier<double>(0);
    addTearDown(extraTop.dispose);
    await tester.pumpWidget(
      host(onRefresh: () async {}, externalExtraTop: extraTop),
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // 谁传进来谁释放：已被 dispose 的 ValueNotifier 再赋值会抛异常
    extraTop.value = 5;
    expect(tester.takeException(), isNull);
  });
}
