import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';

/// 队列按钮。队列页还没做，先只占位不接跳转。
class MiniPlayerQueueButton extends StatelessWidget {
  const MiniPlayerQueueButton({super.key, required this.colors});

  final AppColors colors;

  /// SVG 的 viewBox 是 24，但图形只占中间 74%（3.36→21.11），
  /// 想要 17dp 的墨迹就得开 24dp 的画布——按 17 画出来只有 12.6dp。
  static const double _box = 24;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SvgPicture.asset(
            AppConstants.queueIcon,
            width: _box,
            height: _box,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
