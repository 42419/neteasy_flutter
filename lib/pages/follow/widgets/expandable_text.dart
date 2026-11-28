import 'package:material_ui/material_ui.dart';

/// 把正文里的 `#话题#` 切出来染色，其余按正文色。
///
/// 话题的边界：两个 `#` 之间不放 `#` 和换行；正文里 `#` 只出现在话题里，
/// 这个范围足够，也不至于把整段吞掉。
List<TextSpan> feedTextSpans(
  String text, {
  required TextStyle style,
  required TextStyle linkStyle,
}) {
  final List<TextSpan> spans = <TextSpan>[];
  int cursor = 0;
  for (final RegExpMatch match in _topic.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: style),
      );
    }
    spans.add(TextSpan(text: match.group(0), style: linkStyle));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return spans;
}

final RegExp _topic = RegExp(r'#[^#\n]{1,30}#');

/// 把话题从正文里拆出来：正文参与折叠，话题固定在正文下面单独一行。
///
/// 官方的做法就是这样——话题不跟着「查看全文」一起被截断，
/// 而是常驻在正文末尾，任何时候都能看到。
({String body, List<String> topics}) splitTopics(String text) {
  final List<String> topics = <String>[];
  for (final RegExpMatch match in _topic.allMatches(text)) {
    topics.add(match.group(0)!);
  }
  if (topics.isEmpty) {
    return (body: text.trim(), topics: const <String>[]);
  }
  String body = text.replaceAll(_topic, '');
  // 摘掉话题后会留下空行和行尾空白，收拾一下再折叠
  body = body
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return (body: body, topics: topics);
}

/// 动态正文：超过 N 行折叠成「… 查看全文」，话题单独一行常驻在下面。
///
/// 折叠位置要贴着第 N 行末尾，不能用 `TextOverflow.ellipsis`——
/// 那个省略号是画上去的，没法在后面接「查看全文」，也点不到。
/// 做法是用 TextPainter 量：先在候选长度上拼 `… 查看全文` 试排，
/// 二分找到最长的能放下的前缀。长度按 `characters` 数，
/// 免得把 emoji 从中间劈开。
///
/// 点「查看全文」交给 [onTap]（打开动态详情），不在这里原地展开——
/// 官方也是进详情页看全文。
class ExpandableText extends StatelessWidget {
  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    required this.linkStyle,
    this.maxLines = 4,
    this.onTap,
  });

  final String text;
  final TextStyle style;

  /// 话题与「查看全文」的颜色
  final TextStyle linkStyle;

  final int maxLines;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    final ({String body, List<String> topics}) parts = splitTopics(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (parts.body.isNotEmpty) _buildBody(context, parts.body),
        if (parts.topics.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: parts.body.isEmpty ? 0 : 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final String topic in parts.topics)
                  Text(topic, style: linkStyle),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, String body) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        if (!_overflows(body, width)) {
          return Text(body, style: style);
        }
        final int fit = _longestPrefix(body, width);
        final String head = body.characters.take(fit).toString();
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: head, style: style),
                TextSpan(text: '…', style: style),
                TextSpan(text: ' 查看全文', style: linkStyle),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _overflows(String text, double width) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final bool exceeded = painter.didExceedMaxLines;
    painter.dispose();
    return exceeded;
  }

  /// 能和第 N 行末尾的「… 查看全文」一起放下的最长前缀（按字符数）
  int _longestPrefix(String text, double width) {
    final Characters chars = text.characters;
    int low = 0;
    int high = chars.length;
    while (low < high) {
      final int mid = (low + high + 1) ~/ 2;
      final String candidate = '${chars.take(mid)}… 查看全文';
      final TextPainter painter = TextPainter(
        text: TextSpan(text: candidate, style: style),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final bool exceeded = painter.didExceedMaxLines;
      painter.dispose();
      if (exceeded) {
        high = mid - 1;
      } else {
        low = mid;
      }
    }
    return low;
  }
}
