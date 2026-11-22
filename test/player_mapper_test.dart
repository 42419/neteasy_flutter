import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/api/ncm_mapper.dart';
import 'package:neteasy_flutter/viewmodels/song_url.dart';

void main() {
  test('正常地址：取 url 和码率，不是试听', () {
    final SongUrl? result = toSongUrl(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'url': ' http://m701.music.126.net/a.mp3 ',
          'br': 320000,
          'freeTrialInfo': null,
        },
      ],
    });
    expect(result, isNotNull);
    expect(result!.url, 'http://m701.music.126.net/a.mp3');
    expect(result.bitrate, 320000);
    expect(result.isTrial, isFalse);
  });

  test('freeTrialInfo 非空：标成试听片段', () {
    final SongUrl? result = toSongUrl(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'url': 'https://example.com/clip.mp3',
          'freeTrialInfo': <String, dynamic>{'start': 0, 'end': 30},
        },
      ],
    });
    expect(result!.isTrial, isTrue);
  });

  test('没有地址（无版权 / 下架）返回 null', () {
    expect(
      toSongUrl(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'url': null, 'code': 404},
        ],
      }),
      isNull,
    );
    expect(
      toSongUrl(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'url': '  '},
        ],
      }),
      isNull,
    );
  });

  test('data 缺失或为空返回 null，不抛异常', () {
    expect(toSongUrl(<String, dynamic>{}), isNull);
    expect(toSongUrl(<String, dynamic>{'data': <Object>[]}), isNull);
    expect(toSongUrl(<String, dynamic>{'data': 'oops'}), isNull);
  });
}
