import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/cover_image.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/feed_event.dart';

/// 动态里的配图：**不裁剪、不改比例**。
///
/// 尺寸规则和官方一致：给一个上限（宽不超过正文栏，高不超过 [maxHeight]），
/// 图按自己的比例缩到装得下为止——竖图自然变窄，横图自然变矮，
/// 不会出现「先塞进一个固定框再 cover」那种切边或留灰边。
///
/// 另外不要用 `?param=WxH`：那是裁方图。这里用 `?imageView&thumbnail=Wx0`，
/// 宽 W、高自适应（实测 1440×1920 → 450×600，比例不变）。
class FeedImage extends StatelessWidget {
  const FeedImage({
    super.key,
    required this.pic,
    this.maxWidth,
    this.maxHeight = 240,
    this.radius = AppTheme.radiusThumb,
  });

  final FeedPic pic;

  /// 正文栏的宽度；不传就用父级的可用宽度
  final double? maxWidth;

  /// 高度上限（官方约 240dp）
  final double maxHeight;

  final double radius;

  /// 450 是列表这一档：450×600 解码后约 90KB，3x 屏上 180dp 宽够用
  static const int _preset = 450;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _build(context, maxWidth ?? constraints.maxWidth);
      },
    );
  }

  Widget _build(BuildContext context, double limitWidth) {
    final AppColors colors = AppTheme.colorsOf(context);
    final String url = _url(pic);
    if (url.isEmpty) {
      return SizedBox(
        width: _fitWidth(pic.aspectRatio, limitWidth),
        height: _fitWidth(pic.aspectRatio, limitWidth) / pic.aspectRatio,
      );
    }
    // 占位按接口给的宽高比先撑住位置；真图到了按自己的比例落位，
    // 两者比例一致时不会有跳动
    final double placeholderWidth = _fitWidth(pic.aspectRatio, limitWidth);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: limitWidth, maxHeight: maxHeight),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          httpHeaders: AppConstants.coverHeaders,
          memCacheWidth: _preset,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (BuildContext context, String _) => SizedBox(
            width: placeholderWidth,
            height: placeholderWidth / pic.aspectRatio,
            child: ColoredBox(color: colors.placeholder),
          ),
          errorWidget: (BuildContext context, String _, Object _) =>
              ColoredBox(color: colors.placeholder),
        ),
      ),
    );
  }

  /// 按比例算「装进 limitWidth × maxHeight」后的宽度
  double _fitWidth(double aspectRatio, double limitWidth) {
    final double byHeight = maxHeight * aspectRatio;
    return byHeight < limitWidth ? byHeight : limitWidth;
  }

  /// 原图地址 + 等比缩略参数；已经是带参数的地址就不动
  String _url(FeedPic pic) {
    final String origin = pic.originUrl.isNotEmpty ? pic.originUrl : pic.url;
    final String normalized = CoverImage.normalizeCoverUrl(origin);
    if (normalized.isEmpty || normalized.contains('?')) {
      return normalized;
    }
    return '$normalized?imageView&thumbnail=${_preset}x0';
  }
}
