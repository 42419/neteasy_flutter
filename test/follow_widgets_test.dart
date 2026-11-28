import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neteasy_flutter/pages/follow/widgets/follow_feed_item.dart';
import 'package:neteasy_flutter/pages/follow/widgets/follow_states.dart';
import 'package:neteasy_flutter/theme/app_theme.dart';
import 'package:neteasy_flutter/viewmodels/feed_event.dart';

/// 动态卡片的两条硬要求：
/// - 正文超 4 行要折成「… 展开」（截图上是这么标的，不能直接省略号截断）
/// - 头像/配图地址为空时不能崩，也不能发起网络请求（测试环境没有网）

FeedEvent _event({String text = '秋天真好', int vipLevel = 0, bool svip = false}) {
  return FeedEvent(
    id: 1,
    type: FeedEvent.typeText,
    timeMs: DateTime(2026, 11, 26).millisecondsSinceEpoch,
    user: FeedUser(
      uid: 1452176465,
      nickname: '云音乐VIP',
      vipLevel: vipLevel,
      svip: svip,
    ),
    text: text,
    liked: true,
    likedCount: 2121,
    commentCount: 237,
    shareCount: 7,
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('动态卡：昵称、日期、正文、互动数都在', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(FollowFeedItem(event: _event(text: '#摄影# 秋天真好'))),
    );

    expect(find.text('云音乐VIP'), findsOneWidget);
    expect(find.text('11月26日'), findsOneWidget);
    expect(find.text('2121'), findsOneWidget);
    expect(find.text('237'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('正文超过 4 行：折成「… 查看全文」', (WidgetTester tester) async {
    final String long = '秋天的银杏把整条街染成金色，' * 20;
    await tester.pumpWidget(_host(FollowFeedItem(event: _event(text: long))));

    expect(
      find.textContaining('查看全文', findRichText: true),
      findsOneWidget,
      reason: '长正文要给出去详情页的入口',
    );
    expect(find.textContaining(long, findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('短正文不出现查看全文', (WidgetTester tester) async {
    await tester.pumpWidget(_host(FollowFeedItem(event: _event())));
    expect(find.textContaining('查看全文', findRichText: true), findsNothing);
  });

  testWidgets('互动数字用官方数字字体，日期保留正文字体', (WidgetTester tester) async {
    await tester.pumpWidget(_host(FollowFeedItem(event: _event())));

    final Text likes = tester.widget<Text>(find.text('2121'));
    expect(likes.style?.fontFamily, 'Dolphin');
    // 日期是中英混排，保留正文字体，只把数字换成等宽字形
    final Text date = tester.widget<Text>(find.text('11月26日'));
    expect(date.style?.fontFamily, isNull);
    expect(date.style?.fontFeatures, isNotEmpty);
  });

  testWidgets('昵称右侧按等级挂 VIP 徽章，普通用户不挂', (WidgetTester tester) async {
    /// 动作条里也有 SvgPicture，按资源路径挑出等级徽章
    Finder badgeFinder() => find.byWidgetPredicate(
      (Widget w) =>
          w is SvgPicture && '${w.bytesLoader}'.contains('vip/level/'),
    );

    await tester.pumpWidget(
      _host(FollowFeedItem(event: _event(vipLevel: 7, svip: true))),
    );
    expect(badgeFinder(), findsOneWidget);
    expect(tester.getSize(badgeFinder()).height, 16);

    await tester.pumpWidget(_host(FollowFeedItem(event: _event())));
    expect(badgeFinder(), findsNothing);
  });

  testWidgets('「查看全部动态」按钮宽度跟着文字走，不撑满整行', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: FollowEmptyState(text: '关注的音乐人近3天没有新动态'),
            ),
          ),
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(FollowPillButton));
    expect(size.height, FollowPillButton.height);
    expect(size.width, lessThan(200), reason: '不能吃满 400 宽');
    expect(size.width, greaterThan(80), reason: '至少容得下六个字');
  });

  testWidgets('话题不参与折叠，单独显示在正文下面', (WidgetTester tester) async {
    // 测试视口 800 宽，一屏能放约 47 个汉字；这里要足够长才折到 4 行
    final String long = '秋天的银杏把整条街染成金色，' * 20;
    await tester.pumpWidget(
      _host(FollowFeedItem(event: _event(text: '$long\n#摄影# #秋天#'))),
    );

    expect(find.text('#摄影#'), findsOneWidget);
    expect(find.text('#秋天#'), findsOneWidget);
    expect(
      find.textContaining('查看全文', findRichText: true),
      findsOneWidget,
      reason: '正文超长时仍要给出查看全文',
    );
  });

  testWidgets('短正文带话题：话题照样显示，不出现查看全文', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(FollowFeedItem(event: _event(text: '秋天真好 #摄影#'))),
    );
    expect(find.text('秋天真好'), findsOneWidget);
    expect(find.text('#摄影#'), findsOneWidget);
    expect(find.textContaining('查看全文', findRichText: true), findsNothing);
  });

  testWidgets('空态：文案 + 查看全部动态', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(FollowEmptyState(text: '关注的音乐人近3天没有新动态', onViewAll: () {})),
    );
    expect(find.text('关注的音乐人近3天没有新动态'), findsOneWidget);
    expect(find.text('查看全部动态'), findsOneWidget);
  });

  testWidgets('到底：两句文案 + 按钮', (WidgetTester tester) async {
    await tester.pumpWidget(_host(FollowEndState(onViewAll: () {})));
    expect(find.text('你关心的动态看完啦'), findsOneWidget);
    expect(find.text('查看全部动态'), findsOneWidget);
    expect(find.text('已经刷到底啦'), findsOneWidget);
  });
}
