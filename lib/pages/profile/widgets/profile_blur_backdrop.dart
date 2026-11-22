import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';

/// 「我的」页顶部的模糊头像背景。
///
/// 头像放大后高斯模糊，再压一层由浅到深的遮罩，向下过渡到页面底色。
/// 只画静态的那一层；往上滚时的淡出由页面订阅滚动距离后套 `Opacity`，
/// 这样背景本身不用重建。
class ProfileBlurBackdrop extends StatelessWidget {
  const ProfileBlurBackdrop({super.key, required this.avatarUrl});

  final String avatarUrl;

  /// 铺到快捷入口下方，再渐变回页面底色
  static const double height = 380;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final ProfileColors profileColors = AppTheme.profileOf(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            // 背景只需要一团颜色，要个小图就够，不必把整张头像下下来
            child: CoverImage(url: avatarUrl, logicalWidth: 40),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  colors.background.withValues(
                    alpha: profileColors.blurScrimStartAlpha,
                  ),
                  colors.background.withValues(
                    alpha: profileColors.blurScrimMidAlpha,
                  ),
                  colors.background,
                ],
                stops: const <double>[0, 0.62, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
