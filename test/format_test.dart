import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/utils/format.dart';

void main() {
  test('formatCount 按万/亿收敛，边界不串档', () {
    expect(formatCount(0), '0');
    expect(formatCount(-5), '0');
    expect(formatCount(9999), '9999');
    expect(formatCount(10000), '1.0万');
    expect(formatCount(12345), '1.2万');
    expect(formatCount(99999999), '10000.0万');
    expect(formatCount(100000000), '1.0亿');
    expect(formatCount(340000000), '3.4亿');
  });

  test('formatDuration 补零到 mm:ss', () {
    expect(formatDuration(0), '00:00');
    expect(formatDuration(-1), '00:00');
    expect(formatDuration(1000), '00:01');
    expect(formatDuration(65000), '01:05');
    expect(formatDuration(3600000), '60:00');
  });
}
