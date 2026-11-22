import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 「新建歌单」「导入外部歌单」两行 + 底部说明。
///
/// 左边都是 48dp 的方块按钮，标题 15sp，导入那行多一句灰色副标题。
/// 两个入口都还没接弹窗，先只有视觉。
class ProfileActionRows extends StatelessWidget {
  const ProfileActionRows({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Column(
      children: <Widget>[
        _ActionRow(icon: Icons.add_rounded, title: '新建歌单', colors: colors),
        _ActionRow(
          icon: Icons.login_rounded,
          title: '导入外部歌单',
          subtitle: '轻松导入其他 APP 里的歌单',
          colors: colors,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            18,
            AppTheme.pagePadding,
            8,
          ),
          child: Text(
            '展示创建/收藏的 30 条内容，该列表仅自己可见',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 48dp 方形按钮 + 标题（可带副标题）
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.colors,
    this.subtitle = '',
  });

  final IconData icon;
  final String title;
  final AppColors colors;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.listRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Icon(icon, size: 26, color: colors.textPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTheme.listTitle(colors)),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTheme.listSubtitle(colors)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
