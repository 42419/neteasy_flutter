import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 未登录时的「我的」页：标题 + 一张登录引导卡。
///
/// 卡片里只放一个入口，别在这加别的营销位——官方未登录态也是这么素。
class ProfileLoginEntry extends StatelessWidget {
  const ProfileLoginEntry({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors colors = AppTheme.colorsOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        24,
      ),
      children: <Widget>[
        Text(
          '我的',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.placeholder,
                child: Icon(Icons.person, size: 34, color: colors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                '登录网易云账号',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '登录后可看每日推荐、我的歌单与收藏',
                textAlign: TextAlign.center,
                style: AppTheme.caption(colors),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    minimumSize: const Size(64, 44),
                  ),
                  child: const Text('扫码登录'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
