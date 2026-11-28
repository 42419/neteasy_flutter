import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../components/cover_image.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../viewmodels/feed_event.dart';
import 'image_origin_cache.dart';
import 'widgets/feed_vip_badge.dart';

/// 动态配图的大图页。
///
/// 三条硬要求（官方行为）：
/// - 打开时**不加载原图**，用 `thumbnail=1080x0` 的等比预览（不裁剪）
/// - 右上角「原图」按了才去下 [FeedPic.originUrl]，下载完按钮就收起来；
///   这张图以后从列表再点开，直接按原图显示、不再出现按钮（[ImageOriginCache]）
/// - 全部走 `cached_network_image`：预览和原图各缓存一份，返回再进不重下
///
/// 不直接用服务端的 `rectangleUrl`：那一档是 `param=WxH` 裁出来的方图，
/// 竖图会缺上下半截（实测 1440×1920 → 1080×1080）。
///
/// 底部保留发布者的文字与互动数，方便边看图边确认是哪条动态。
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.event,
    this.initialIndex = 0,
  });

  final FeedEvent event;
  final int initialIndex;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final int _index = widget.initialIndex;

  /// 是否已经切到原图。上次点过「原图」的这张图，这次直接按原图显示
  bool _origin = false;

  @override
  void initState() {
    super.initState();
    _origin = ImageOriginCache.isLoaded(_pic?.originUrl ?? '');
  }

  /// 重试计数：加载失败后靠它强制重建图片组件
  int _attempt = 0;

  /// 顶栏高度（不含状态栏），与动态页一致
  static const double _barHeight = 56;

  FeedPic? get _pic {
    if (widget.event.pics.isEmpty) {
      return null;
    }
    return widget.event.pics[_index.clamp(0, widget.event.pics.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final FeedPic? pic = _pic;
    return Scaffold(
      backgroundColor: AppTheme.viewerBackground,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: pic == null
                ? const SizedBox.shrink()
                : _buildImage(context, pic),
          ),
          // 必须定位：Stack 里只要有非定位子节点，整页高度就按它算。
          // 之前没定位，Stack 只有顶栏那 56dp，所有内容全挤在屏幕顶上
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 4),
                    _CloseButton(onTap: () => Navigator.of(context).pop()),
                    const Spacer(),
                    if (pic != null && !_origin)
                      _OriginButton(onTap: _loadOrigin),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFooter(context),
          ),
        ],
      ),
    );
  }

  /// 图片区：整屏容器 + `BoxFit.contain`，**绝不裁剪**。
  ///
  /// 之前按 `width/height` 算了一个容器再 cover 填进去，元数据不准就直接切边；
  /// 现在容器就是屏幕，图按原比例缩放到装得下为准，上下（或左右）留黑边。
  ///
  /// 预览和原图的 URL 不同，`CachedNetworkImage` 各存一份磁盘缓存，
  /// 再进大图页或再切原图都不会重新下载。
  Widget _buildImage(BuildContext context, FeedPic pic) {
    final String url = _origin ? pic.originUrl : _previewUrl(pic);
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: SizedBox.expand(
        child: CachedNetworkImage(
          key: ValueKey<String>('$_attempt-$url'),
          imageUrl: CoverImage.normalizeCoverUrl(url),
          fit: BoxFit.contain,
          httpHeaders: AppConstants.coverHeaders,
          // 预览按 1080 解码就够；原图不限制，否则「看原图」没意义
          memCacheWidth: _origin ? null : 1080,
          fadeInDuration: const Duration(milliseconds: 120),
          // 原图真的解码出来才记账：下载失败的不算，下次还会给按钮
          imageBuilder: (BuildContext context, ImageProvider<Object> provider) {
            if (_origin) {
              ImageOriginCache.markLoaded(pic.originUrl);
            }
            return Image(image: provider, fit: BoxFit.contain);
          },
          // 占位直接用列表那张（缓存里，瞬间有），
          // 预览图到了再淡入；两者都不裁，切换时不会跳比例
          placeholder: (BuildContext context, String _) => CachedNetworkImage(
            imageUrl: _listThumbUrl(pic),
            fit: BoxFit.contain,
            httpHeaders: AppConstants.coverHeaders,
          ),
          errorWidget: (BuildContext context, String _, Object _) =>
              _buildError(context),
        ),
      ),
    );
  }

  /// 预览图：原图地址 + `imageView&thumbnail=1080x0`。
  ///
  /// 实测（1440×1920 的图）：
  /// - `?param=1080y1080` → 1080×1080，**裁成方图**（服务端的 rectangleUrl 就是这个）
  /// - `?imageView&thumbnail=1080x0` → 1080×1440，**等比缩放不裁**，约 400KB
  ///
  /// 宽 0 表示高度自适应，正好满足「完整显示、不拉原图」。
  String _previewUrl(FeedPic pic) {
    final String origin = pic.originUrl.isNotEmpty ? pic.originUrl : pic.url;
    final String normalized = CoverImage.normalizeCoverUrl(origin);
    if (normalized.isEmpty || normalized.contains('?')) {
      return normalized;
    }
    return '$normalized?imageView&thumbnail=1080x0';
  }

  /// 列表里那张的地址（与 `CoverImage(crop: false)` 在 152dp 宽时拼的一致），
  /// 只当加载时的占位：已经在磁盘缓存里，进页面立刻有内容，不会白屏
  String _listThumbUrl(FeedPic pic) {
    final String normalized = CoverImage.normalizeCoverUrl(pic.url);
    if (normalized.isEmpty || normalized.contains('?')) {
      return normalized;
    }
    return '$normalized?imageView&thumbnail=450x0';
  }

  Widget _buildError(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() {
        _attempt++;
        if (_origin) {
          // 原图拉不下来就退回预览，别让整页空着；
          // 同时撤销记账，下次还会给「原图」按钮
          ImageOriginCache.forget(_pic?.originUrl ?? '');
          _origin = false;
        }
      }),
      child: Text(
        '图片加载失败，点击重试',
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: AppTheme.colorsOf(context).onMediaSecondary,
        ),
      ),
    );
  }

  /// 切原图：按钮立刻收起，加载中的转圈由图片自己显示。
  /// 失败时 [errorWidget] 会把 `_origin` 退回 false，按钮重新出现
  void _loadOrigin() {
    setState(() => _origin = true);
  }

  /// 底部：发布者的话（一行，超出省略）+ 作者与互动数
  Widget _buildFooter(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final FeedEvent event = widget.event;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (event.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  event.text.replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: colors.onMedia,
                  ),
                ),
              ),
            Row(
              children: <Widget>[
                ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: event.user.avatarUrl.isEmpty
                        ? ColoredBox(color: colors.placeholder)
                        : CoverImage(
                            url: event.user.avatarUrl,
                            logicalWidth: 36,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    event.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      color: colors.onMedia,
                    ),
                  ),
                ),
                if (event.user.vipLevel > 0) ...<Widget>[
                  const SizedBox(width: 6),
                  FeedVipBadge(user: event.user),
                ],
                const Spacer(),
                _ViewerAction(
                  asset: event.liked
                      ? AppConstants.feedPraisedIcon
                      : AppConstants.feedPraiseIcon,
                  count: event.likedCount,
                  tinted: !event.liked,
                ),
                const SizedBox(width: 22),
                _ViewerAction(
                  asset: AppConstants.feedCommentIcon,
                  count: event.commentCount,
                ),
                const SizedBox(width: 22),
                _ViewerAction(
                  asset: AppConstants.feedForwardIcon,
                  count: event.shareCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 左上角关闭：白色 X，点击面积给到 48
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              AppConstants.viewerCloseIcon,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(colors.onMedia, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

/// 右上角「原图」：52×28 的描边胶囊，按下后自行收起
class _OriginButton extends StatelessWidget {
  const _OriginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.viewerChipBorder),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              '原图',
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                color: colors.onMedia,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部右侧的互动数：白色描边图标 + 数字
class _ViewerAction extends StatelessWidget {
  const _ViewerAction({
    required this.asset,
    required this.count,
    this.tinted = true,
  });

  final String asset;
  final int count;

  /// 已点赞的图标自带红色，不染色
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(
          asset,
          width: 24,
          height: 24,
          colorFilter: tinted
              ? ColorFilter.mode(colors.onMedia, BlendMode.srcIn)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          formatCount(count),
          style: AppTheme.numeric(
            TextStyle(fontSize: 15, height: 1.2, color: colors.onMedia),
          ),
        ),
      ],
    );
  }
}
