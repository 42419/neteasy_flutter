import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 关注页的几种整块状态：空态、到底、未登录。
///
/// 三者长得很像（一句灰字 + 一个描边胶囊按钮），差别只在文案和有没有按钮，
/// 所以共用 [FollowPillButton]。

/// 描边胶囊按钮：官方「查看全部动态」「登录」都是这个形状。
///
/// 真机量得：110×30dp（「查看全部动态」六个字 × 13sp + 左右各 16dp），
/// 圆角 15、描边 1dp，底部透明（透出页面底色），文字是正文色。
class FollowPillButton extends StatelessWidget {
  const FollowPillButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  /// 胶囊高度，圆角取一半
  static const double height = 30;

  /// 文字左右内边距
  static const double _padding = 16;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: _padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: colors.divider),
          ),
          // 不能用 `alignment`：带 alignment 的 Container 会把可用宽度吃满，
          // 按钮就变成整行宽了。这里要的是「文字宽 + 左右各 16」
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 某个标签下没有动态：「关注的音乐人近3天没有新动态」+ 查看全部动态
class FollowEmptyState extends StatelessWidget {
  const FollowEmptyState({super.key, required this.text, this.onViewAll});

  final String text;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      // 顶部接标签栏（真机约 8dp），底部到分隔线 20dp
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        children: <Widget>[
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: colors.textDescription,
            ),
          ),
          const SizedBox(height: 15),
          FollowPillButton(label: '查看全部动态', onTap: onViewAll),
        ],
      ),
    );
  }
}

/// 划到底：分隔线 → 一句「你关心的动态看完啦」+ 按钮 → 再一条线 + 「已经刷到底啦」
///
/// 两条线在真机截图里都在（y=5117 和 y=5416，颜色 #E6EAED）：
/// 上面那条离动作条约 23dp，文字离线上沿约 23dp。
class FollowEndState extends StatelessWidget {
  const FollowEndState({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Column(
      children: <Widget>[
        const _Hairline(),
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 20),
          child: Column(
            children: <Widget>[
              Text(
                '你关心的动态看完啦',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: colors.textDescription,
                ),
              ),
              const SizedBox(height: 15),
              FollowPillButton(label: '查看全部动态', onTap: onViewAll),
            ],
          ),
        ),
        const FollowBottomTip(),
      ],
    );
  }
}

/// 列表最底下的那条：分隔线 + 「已经刷到底啦」。
/// 空态和看完态都会走到这里，所以单独拆出来
class FollowBottomTip extends StatelessWidget {
  const FollowBottomTip({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Column(
      children: <Widget>[
        const _Hairline(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '已经刷到底啦',
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 未登录：一句提示 + 登录按钮（官方要求先登录才能用关注页）
class FollowGuestState extends StatelessWidget {
  const FollowGuestState({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: <Widget>[
          Text(
            '登录后查看关注动态',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FollowPillButton(label: '登录', onTap: onLogin),
        ],
      ),
    );
  }
}

/// 0.5dp 分隔线，和列表里的一致
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: AppTheme.colorsOf(context).divider);
  }
}
