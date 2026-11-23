import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// 扫光：一束半透明白光从左侧扫到右侧，盖在实色块上。
///
/// 骨架屏的公共基元，首页和每日推荐页共用。各页按真实几何自己拼装——
/// 行高、封面尺寸都照有数据时的值取，数据到达后高度不变，页面不会跳。
///
/// [animation] 为 null 时直接返回 child：系统开了「减少动态效果」就传 null，
/// 骨架退化成静态灰块。
class Shimmer extends StatelessWidget {
  const Shimmer({super.key, required this.animation, required this.child});

  final Animation<double>? animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = this.animation;
    if (animation == null) {
      return child;
    }
    final Color shine = AppTheme.colorsOf(context).skeletonShine;
    return AnimatedBuilder(
      animation: animation,
      // child 不参与重建，每帧只重算 shader
      child: child,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double t = animation.value;
            return LinearGradient(
              begin: Alignment(-1.8 + 3.4 * t, 0),
              end: Alignment(-0.8 + 3.4 * t, 0),
              colors: <Color>[
                shine.withValues(alpha: 0),
                shine,
                shine.withValues(alpha: 0),
              ],
              stops: const <double>[0, 0.5, 1],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// 骨架基础块：实色圆角，扫光只改它的亮度
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).placeholder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
