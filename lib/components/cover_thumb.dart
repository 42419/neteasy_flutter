import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'cover_image.dart';

/// 封面缩略图：定尺寸 + 圆角 + [CoverImage]，列表行里天天要写的那一坨。
///
/// 只负责「一块方图」，不处理点击。尺寸由调用方给，圆角默认 4（官方
/// 歌单行、歌曲行、播客行都是 4），需要 6 或 8 时传 [radius]。
class CoverThumb extends StatelessWidget {
  const CoverThumb({
    super.key,
    required this.url,
    required this.size,
    this.width,
    this.height,
    this.radius = AppTheme.radiusThumb,
  });

  final String url;

  /// 正方形边长；给 [width] / [height] 时按矩形画（有声书是 64×80）
  final double size;

  final double? width;
  final double? height;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final double w = width ?? size;
    final double h = height ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: w,
        height: h,
        child: CoverImage(url: url, logicalWidth: w > h ? w : h),
      ),
    );
  }
}
