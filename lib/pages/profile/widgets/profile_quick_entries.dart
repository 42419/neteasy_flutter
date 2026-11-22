import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';

/// 快捷入口：最近 / 本地 / 网盘 / 云贝 + 右侧宫格（音乐应用页）。
///
/// 底是 9% 白的半透明玻璃色，图标和字是 92% 白，浮在深色的模糊头部上
/// （颜色取自官方截图，深浅色主题下一样）。
/// 四个入口 + 宫格目前都没接页面，点了只弹一句提示。
class ProfileQuickEntries extends StatelessWidget {
  const ProfileQuickEntries({super.key, required this.onTapEntry});

  /// 点了某一格；传的是展示名（宫格是「音乐应用」）
  final void Function(String label) onTapEntry;

  static const List<(String, String)> _entries = <(String, String)>[
    ('assets/icons/profile/recent.svg', '最近'),
    ('assets/icons/profile/local.svg', '本地'),
    ('assets/icons/profile/cloud.svg', '网盘'),
    ('assets/icons/profile/yunbei.svg', '云贝'),
  ];

  @override
  Widget build(BuildContext context) {
    final ProfileColors profileColors = AppTheme.profileOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 0, 12, 0),
      child: Row(
        children: <Widget>[
          for (final (String asset, String label) in _entries) ...<Widget>[
            Expanded(
              child: _QuickChip(
                asset: asset,
                label: label,
                content: profileColors.quickChipContent,
                background: profileColors.quickChip,
                onTap: () => onTapEntry(label),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _QuickChip(
            content: profileColors.quickChipContent,
            background: profileColors.quickChip,
            onTap: () => onTapEntry('音乐应用'),
          ),
        ],
      ),
    );
  }
}

/// 单格：40dp 高，宫格那格是 40×40，其余按 Expanded 均分
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.content,
    required this.background,
    required this.onTap,
    this.asset,
    this.label = '',
  });

  /// 图标和字的颜色
  final Color content;
  final Color background;
  final VoidCallback onTap;

  /// 为 null 时画宫格图标（音乐应用入口）
  final String? asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool square = asset == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: square ? 40 : null,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (asset != null)
              SvgPicture.asset(
                asset!,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(content, BlendMode.srcIn),
              )
            else
              Icon(Icons.grid_view_rounded, size: 16, color: content),
            if (label.isNotEmpty) ...<Widget>[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 13, height: 1.2, color: content),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
