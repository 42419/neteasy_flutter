import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../theme/app_theme.dart';

/// 「我的」页顶部的模糊头像背景。
///
/// 照官方截图复刻：头像放大后高斯模糊，**压一层黑色遮罩**（上半段约 25%，
/// 往下渐隐到几乎为 0），头部就是一块偏深的、带头像色调的底，上面的字用白色。
/// 底边不再渐变回页面底色，而是被白色圆角面板（[ProfileSheetCap]）盖住——
/// 圆角两侧露出的就是这块背景的颜色。
///
/// 这一层是固定的，由页面按滚动距离整体平移（见 `ProfileView`），
/// 所以它和头像、统计、快捷入口始终同步移动，白字不会落到变浅的背景上。
class ProfileBlurBackdrop extends StatelessWidget {
  const ProfileBlurBackdrop({super.key, required this.avatarUrl});

  /// 为空时用 [ProfileColors.headerFallback] 当底色
  final String avatarUrl;

  /// 面板顶边离屏幕顶端的距离：官方截图 1050px ÷ 2.81 = 374dp
  static const double sheetTop = 374;

  /// 面板顶部圆角：截图上约 19px ÷ 2.81 ≈ 7dp
  static const double sheetRadius = 7;

  /// 背景总高：多出一个圆角的高度，圆角处才露得出头部的颜色
  static const double height = sheetTop + sheetRadius;

  /// 下拉越界时向上多铺的一截，免得头部被拉下来后露出页面底色。
  /// 背景比可见区域高，所以图片的可见部分比官方截图略靠下，模糊后看不出来。
  static const double overscrollMargin = 160;

  /// 遮罩在头部高度的这个位置之前保持最深，到 [_scrimFadeEnd] 渐隐完。
  /// 截图实测：y=540px（51%）以上颜色几乎不变，y=960px（91%）起为原图色
  static const double _scrimHold = 0.51;
  static const double _scrimFadeEnd = 0.91;

  @override
  Widget build(BuildContext context) {
    final ProfileColors profileColors = AppTheme.profileOf(context);
    const double total = overscrollMargin + height;
    // 渐变铺在「越界余量 + 背景」整段上，所以停靠点要换算成这一整段里的比例
    const double holdStop = (overscrollMargin + sheetTop * _scrimHold) / total;
    const double fadeEndStop =
        (overscrollMargin + sheetTop * _scrimFadeEnd) / total;

    return SizedBox(
      height: height,
      child: Stack(
        // 向上溢出的那一截是给下拉越界用的，不能被裁掉
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: -overscrollMargin,
            left: 0,
            right: 0,
            height: total,
            // ClipRect：高斯模糊会在图片边缘外晕出一圈半透明的色，
            // 压在下面透明的歌单行上就成了「阴影」（深色下是发亮的一条）。
            // 把这一层裁在自己的矩形里，晕出去的部分就不会画出来
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (avatarUrl.isEmpty)
                    ColoredBox(color: profileColors.headerFallback)
                  else
                    ImageFiltered(
                      // mirror：边缘按镜像取样。默认情况下边缘外按透明算，
                      // 图片靠边的一段会越来越淡，露出页面底色，头部下沿就发白
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 100,
                        sigmaY: 100,
                        tileMode: ui.TileMode.mirror,
                      ),
                      // 背景只需要一团颜色，要个小图就够，不必把整张头像下下来
                      child: CoverImage(url: avatarUrl, logicalWidth: 40),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          profileColors.blurScrimTop,
                          profileColors.blurScrimTop,
                          profileColors.blurScrimBottom,
                          profileColors.blurScrimBottom,
                        ],
                        stops: const <double>[0, holdStop, fadeEndStop, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 头部下沿的白色圆角面板顶边：只有一个圆角高度，盖在 [ProfileBlurBackdrop]
/// 最底下那一截上，让头部和下面的标签栏之间是圆角过渡，不是一条硬边。
///
/// 放在滚动内容里、紧贴头部块的下面，随内容一起滚走。
class ProfileSheetCap extends StatelessWidget {
  const ProfileSheetCap({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Container(
      height: ProfileBlurBackdrop.sheetRadius,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ProfileBlurBackdrop.sheetRadius),
        ),
      ),
    );
  }
}
