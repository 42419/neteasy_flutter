import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../stores/session_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/user_profile.dart';
import '../login/login_view.dart';

/// 「我的」页。
///
/// 目前只承担登录入口与账号信息；歌单、收藏等模块等后端补齐接口后再加。
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final SessionStore session = context.watch<SessionStore>();

    return SafeArea(
      child: ListView(
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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (session.restoring)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (session.loggedIn)
            _buildAccount(context, scheme, session)
          else
            _buildLoginEntry(context, theme, scheme),
        ],
      ),
    );
  }

  Widget _buildLoginEntry(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.placeholder,
            child: Icon(Icons.person, size: 34, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            '登录网易云账号',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '登录后可看每日推荐、我的歌单与收藏',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const LoginView(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brand,
                minimumSize: const Size(64, 44),
              ),
              child: const Text('扫码登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccount(
    BuildContext context,
    ColorScheme scheme,
    SessionStore session,
  ) {
    final UserProfile profile = session.profile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: profile.avatarUrl.isEmpty
                      ? const ColoredBox(
                          color: AppTheme.placeholder,
                          child: Icon(
                            Icons.person,
                            color: AppTheme.textTertiary,
                          ),
                        )
                      : Image.network(
                          profile.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => const ColoredBox(
                                color: AppTheme.placeholder,
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (profile.isVip) ...<Widget>[
                          const SizedBox(width: 6),
                          // 徽章是 36×16 的横条，按高度定尺寸
                          SvgPicture.asset(AppConstants.vipBadge, height: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('UID ${profile.uid}', style: AppTheme.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _confirmLogout(context, session),
          child: Text('退出登录', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    SessionStore session,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('退出后每日推荐、我的歌单将不可用，确定退出？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await session.logout();
    }
  }
}
