import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neteasy_flutter/utils/cookie_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 加密存储换成包自带的内存实现：单元测试里没有 Keystore，也不该真写磁盘。
void _useInMemoryVault(Map<String, String> data) {
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
    data,
  );
}

/// 模拟换机 / 恢复备份后 Keystore 里的密钥失效：读写都抛平台异常。
class _BrokenVault extends TestFlutterSecureStoragePlatform {
  _BrokenVault(super.data, {this.failRead = false, this.failWrite = false});

  final bool failRead;
  final bool failWrite;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    if (failRead) {
      throw PlatformException(code: 'bad_decrypt');
    }
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    if (failWrite) {
      throw PlatformException(code: 'bad_encrypt');
    }
    return super.write(key: key, value: value, options: options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> vault;

  setUp(() {
    vault = <String, String>{};
    _useInMemoryVault(vault);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('没有缓存时返回空表', () async {
    final CookieStore store = CookieStore();
    expect(await store.load(), isEmpty);
  });

  test('save 后能原样读回，且不再写 SharedPreferences', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CookieStore store = CookieStore(legacy: prefs);

    await store.save(<String, String>{'MUSIC_U': 'token42', 'os': 'android'});

    expect(await store.load(), <String, String>{
      'MUSIC_U': 'token42',
      'os': 'android',
    });
    expect(prefs.getString('ncm_cookies'), isNull);
  });

  test('旧版明文缓存搬到加密存储，成功后删掉旧键', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ncm_cookies': '{"MUSIC_U":"legacy"}',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CookieStore store = CookieStore(legacy: prefs);

    expect(await store.load(), <String, String>{'MUSIC_U': 'legacy'});
    expect(vault['ncm_cookies'], contains('legacy'));
    expect(prefs.getString('ncm_cookies'), isNull);
    // 迁移只做一次：第二次读走加密存储
    expect(await store.load(), <String, String>{'MUSIC_U': 'legacy'});
  });

  test('损坏的 JSON 当成未登录，不清掉原值', () async {
    vault['ncm_cookies'] = '{oops';
    final CookieStore store = CookieStore();

    expect(await store.load(), isEmpty);
    expect(vault['ncm_cookies'], '{oops');
  });

  test('clear 同时清掉加密存储与旧版明文键', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ncm_cookies': '{"MUSIC_U":"legacy"}',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final CookieStore store = CookieStore(legacy: prefs);
    await store.save(<String, String>{'MUSIC_U': 'token'});

    await store.clear();

    expect(vault, isEmpty);
    expect(prefs.getString('ncm_cookies'), isNull);
    expect(await store.load(), isEmpty);
  });

  test('加密存储解不开时按未登录处理，不抛异常', () async {
    FlutterSecureStoragePlatform.instance = _BrokenVault(vault, failRead: true);
    final CookieStore store = CookieStore();

    expect(await store.load(), isEmpty);
  });

  test('迁移写入失败时仍返回旧值，旧键留着下次再迁', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ncm_cookies': '{"MUSIC_U":"legacy"}',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FlutterSecureStoragePlatform.instance = _BrokenVault(
      vault,
      failWrite: true,
    );
    final CookieStore store = CookieStore(legacy: prefs);

    expect(await store.load(), <String, String>{'MUSIC_U': 'legacy'});
    expect(prefs.getString('ncm_cookies'), isNotNull);
  });

  test('写入失败只是这次没落盘，不往外抛', () async {
    FlutterSecureStoragePlatform.instance = _BrokenVault(
      vault,
      failWrite: true,
    );
    final CookieStore store = CookieStore();

    await store.save(<String, String>{'MUSIC_U': 'token'});

    expect(vault, isEmpty);
  });
}
