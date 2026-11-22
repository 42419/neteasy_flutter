import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/player/play_order.dart';

void main() {
  int? next({
    required int current,
    int length = 3,
    RepeatKind repeat = RepeatKind.all,
    bool shuffle = false,
    bool manual = false,
    Random? random,
  }) {
    return nextIndex(
      current: current,
      length: length,
      repeat: repeat,
      shuffle: shuffle,
      manual: manual,
      random: random,
    );
  }

  group('nextIndex 顺序播放', () {
    test('队中间：往后一首', () {
      expect(next(current: 0), 1);
      expect(next(current: 1), 2);
    });

    test('队尾：列表循环回到开头，不循环就停', () {
      expect(next(current: 2), 0);
      expect(next(current: 2, repeat: RepeatKind.none), isNull);
    });

    test('队尾点「下一首」：不循环也回到开头，不能没反应', () {
      expect(next(current: 2, repeat: RepeatKind.none, manual: true), 0);
    });

    test('空队列返回 null', () {
      expect(next(current: 0, length: 0), isNull);
    });
  });

  group('nextIndex 单曲循环', () {
    test('自然播完：原地重放', () {
      expect(next(current: 1, repeat: RepeatKind.one), 1);
    });

    test('手动点下一首：真的切歌', () {
      expect(next(current: 1, repeat: RepeatKind.one, manual: true), 2);
    });
  });

  group('nextIndex 只有一首', () {
    test('自然播完：循环就重放，不循环就停', () {
      expect(next(current: 0, length: 1), 0);
      expect(next(current: 0, length: 1, repeat: RepeatKind.none), isNull);
    });

    test('手动下一首：重放', () {
      expect(
        next(current: 0, length: 1, repeat: RepeatKind.none, manual: true),
        0,
      );
    });
  });

  group('nextIndex 随机', () {
    test('永远不会连着放同一首，也不越界', () {
      final Random random = Random(42);
      for (int current = 0; current < 5; current++) {
        for (int i = 0; i < 200; i++) {
          final int? picked = next(
            current: current,
            length: 5,
            shuffle: true,
            random: random,
          );
          expect(picked, isNotNull);
          expect(picked, isNot(current));
          expect(picked!, inInclusiveRange(0, 4));
        }
      }
    });
  });

  group('previousIndex', () {
    test('往前一首，队首回到队尾', () {
      expect(previousIndex(current: 2, length: 3), 1);
      expect(previousIndex(current: 0, length: 3), 2);
    });

    test('空队列不崩', () {
      expect(previousIndex(current: 0, length: 0), 0);
    });
  });
}
