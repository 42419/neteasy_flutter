import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../viewmodels/feed_event.dart';

/// 昵称右侧的黑胶等级徽章（「SVIP·柒」）。
///
/// 和「我的」页用同一套资源（`assets/icons/vip/level/`），高度 16。
/// 本地只有 1–7 七档，超出范围按 7 画，至少不会空着。
/// 动态卡和大图页都用它，别再各写一份。
class FeedVipBadge extends StatelessWidget {
  const FeedVipBadge({super.key, required this.user, this.height = 16});

  final FeedUser user;
  final double height;

  /// 只有带等级的才画；调用方判断 `vipLevel > 0` 后再用
  static String assetOf(FeedUser user) {
    final String kind = user.svip ? 'svip' : 'vip';
    final int level = user.vipLevel.clamp(1, 7);
    return 'assets/icons/vip/level/$kind$level.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(assetOf(user), height: height);
  }
}
