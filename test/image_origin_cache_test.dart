import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/pages/follow/image_origin_cache.dart';

/// 点过一次「原图」之后，同一张图再打开要直接按原图显示、不再给按钮。
void main() {
  setUp(ImageOriginCache.clear);

  test('标记后同一张图算已加载原图', () {
    const String url = 'https://p3.music.126.net/a.jpg';
    expect(ImageOriginCache.isLoaded(url), isFalse);

    ImageOriginCache.markLoaded(url);

    expect(ImageOriginCache.isLoaded(url), isTrue);
    expect(
      ImageOriginCache.isLoaded('https://p3.music.126.net/b.jpg'),
      isFalse,
      reason: '别的图不受影响',
    );
  });

  test('加载失败可以撤销记账', () {
    const String url = 'https://p3.music.126.net/a.jpg';
    ImageOriginCache.markLoaded(url);
    ImageOriginCache.forget(url);
    expect(ImageOriginCache.isLoaded(url), isFalse);
  });

  test('空地址不记账，免得所有缺图的动态互相影响', () {
    ImageOriginCache.markLoaded('');
    expect(ImageOriginCache.isLoaded(''), isFalse);
  });
}
