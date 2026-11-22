import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// 封面图：按显示宽度向 CDN 要对应档位的缩略图，灰底占位，加载完淡入。
///
/// - `?param=WxH` 会让 CDN 现裁成正方形：150dp 卡取 450px（77KB → 24KB）、
///   48dp 行取 150px（→ 4.9KB）
/// - 一张封面只发一个请求。之前先挂 30px 模糊预览再换大图，一屏几十张封面
///   请求数翻倍，滑动时反而更卡
/// - 已带 `?imageView=...` 的 URL 不再叠 `param`（CDN 只认第一个处理指令）
///
/// 首页、每日推荐、我的页、迷你播放器都用它，所以放在公用目录，不要再各写一份。
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.url, this.logicalWidth = 150});

  final String url;

  /// 控件上的显示宽度，用来换算 CDN 档位与解码尺寸
  final double logicalWidth;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final String normalized = normalizeCoverUrl(url);
    if (normalized.isEmpty) {
      return ColoredBox(color: colors.placeholder);
    }
    final int preset = presets(logicalWidth);
    final String fullUrl = normalized.contains('?')
        ? normalized
        : '$normalized?param=${preset}y$preset';

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // 底层灰色：图没到、加载失败时都露这一层
        ColoredBox(color: colors.placeholder),
        CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.cover,
          memCacheWidth: preset,
          maxWidthDiskCache: preset,
          httpHeaders: AppConstants.coverHeaders,
          fadeInDuration: const Duration(milliseconds: 100),
          placeholder: (BuildContext context, String url) =>
              const SizedBox.shrink(),
          errorWidget: (BuildContext context, String url, Object error) {
            debugPrint('封面加载失败 URL: $url');
            debugPrint('封面加载失败原因: $error');
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// 显示宽度 → CDN 档位。按 3x 屏算，再大就是浪费流量。
  static int presets(double logicalWidth) {
    if (logicalWidth >= 120) {
      return 450;
    }
    if (logicalWidth >= 70) {
      return 300;
    }
    if (logicalWidth >= 55) {
      return 200;
    }
    if (logicalWidth >= 40) {
      return 150;
    }
    return 100;
  }

  /// 服务端给的是 `http://`，Android 默认拦明文，这里统一升 https
  static String normalizeCoverUrl(String raw) {
    final String url = raw.trim();
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('http://')) {
      return 'https://${url.substring(7)}';
    }
    return url;
  }
}
