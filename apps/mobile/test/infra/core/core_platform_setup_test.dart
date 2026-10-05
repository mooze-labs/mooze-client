import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/infra/core/core_platform_setup.dart';
import 'package:mooze_mobile/shared/authentication/models/device_info.dart';

import 'core_test_fixtures.dart';

class _MockCore extends Mock implements MoozeCore {}

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// In-memory [FlutterSecureStorage] built on mocktail stubs.
_MockStorage _memoryStorage(Map<String, String> data) {
  final s = _MockStorage();
  when(() => s.read(key: any(named: 'key')))
      .thenAnswer((i) async => data[i.namedArguments[#key]]);
  when(() => s.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((i) async {
    data[i.namedArguments[#key] as String] = i.namedArguments[#value] as String;
  });
  when(() => s.delete(key: any(named: 'key')))
      .thenAnswer((i) async => data.remove(i.namedArguments[#key]));
  when(() => s.readAll()).thenAnswer((_) async => Map.of(data));
  when(() => s.containsKey(key: any(named: 'key')))
      .thenAnswer((i) async => data.containsKey(i.namedArguments[#key]));
  return s;
}

typedef _Callbacks = ({
  FutureOr<String?> Function(String) read,
  FutureOr<void> Function(String, String) write,
  FutureOr<void> Function(String) delete,
  FutureOr<List<String>> Function(String) listKeys,
});

void main() {
  setUpAll(() {
    registerFallbackValue(const DeviceMetricsDto(deviceId: ''));
    registerFallbackValue((String _) => null);
    registerFallbackValue((String _, String _) {});
    registerFallbackValue((String _) => <String>[]);
  });

  late _MockCore core;
  late Map<String, String> main;
  late Map<String, String> deviceStore;
  late MemoryLogger logger;
  late List<String> calls;
  _Callbacks? callbacks;

  setUp(() {
    core = _MockCore();
    main = {};
    deviceStore = {};
    logger = MemoryLogger();
    calls = [];
    callbacks = null;
    when(() => core.setSecureStorage(
          read: any(named: 'read'),
          write: any(named: 'write'),
          delete: any(named: 'delete'),
          listKeys: any(named: 'listKeys'),
        )).thenAnswer((i) async {
      calls.add('setSecureStorage');
      callbacks = (
        read: i.namedArguments[#read],
        write: i.namedArguments[#write],
        delete: i.namedArguments[#delete],
        listKeys: i.namedArguments[#listKeys],
      );
    });
    when(() => core.apiSetBaseUrl(baseUrl: any(named: 'baseUrl')))
        .thenAnswer((_) async => calls.add('apiSetBaseUrl'));
    when(() => core.authSetDeviceSafe(safe: any(named: 'safe')))
        .thenAnswer((_) async => calls.add('authSetDeviceSafe'));
    when(() => core.apiSetMetrics(metrics: any(named: 'metrics')))
        .thenAnswer((_) async {});
    when(() => core.secureGet(key: any(named: 'key')))
        .thenAnswer((i) async => callbacks!.read(i.namedArguments[#key]));
    when(() => core.authDeviceId(
          serial: any(named: 'serial'),
          platformId: any(named: 'platformId'),
        )).thenAnswer((_) async => 'dev-1');
  });

  CorePlatformSetup setup({
    bool safe = true,
    String? baseUrl,
    Future<bool> Function()? isSafe,
  }) =>
      CorePlatformSetup(
        logger: logger,
        storage: _memoryStorage(main),
        deviceIdStorage: _memoryStorage(deviceStore),
        readMnemonic: () async => 'cached mnemonic',
        isSafeDevice: isSafe ?? () async => safe,
        deviceInfo: () async => DeviceInfo(
          batteryLevel: 80,
          screenBrightness: 0.5,
          bootTime: DateTime.utc(2026, 1, 2, 3),
        ),
        hardwareIds: () async => (serial: 'SER', platformId: 'PID'),
        baseUrlOverride: baseUrl,
      );

  test('registers storage first, then the device check', () async {
    final s = setup(safe: false);
    await s.apply(core);
    await s.metricsDone;

    expect(calls, ['setSecureStorage', 'authSetDeviceSafe']);
    verify(() => core.authSetDeviceSafe(safe: false)).called(1);
    verifyNever(() => core.apiSetBaseUrl(baseUrl: any(named: 'baseUrl')));
  });

  test('sets the base URL when the build overrides it', () async {
    final s = setup(baseUrl: 'https://staging.mooze.app');
    await s.apply(core);
    await s.metricsDone;

    expect(calls, ['setSecureStorage', 'apiSetBaseUrl', 'authSetDeviceSafe']);
    verify(() => core.apiSetBaseUrl(baseUrl: 'https://staging.mooze.app'))
        .called(1);
  });

  test('a failed device check counts as unsafe', () async {
    final s = setup(isSafe: () async => throw StateError('no plugin'));
    await s.apply(core);
    await s.metricsDone;

    verify(() => core.authSetDeviceSafe(safe: false)).called(1);
    expect(logger.hasTag('core.platform.safe_device_failed'), isTrue);
  });

  test('callbacks use the app storage and keep device_id apart', () async {
    final s = setup();
    await s.apply(core);
    await s.metricsDone;
    final cb = callbacks!;

    await cb.write('jwt', 'token');
    await cb.write('refresh_token', 'r');
    await cb.write('device_id', 'dev');
    expect(main, {'jwt': 'token', 'refresh_token': 'r'});
    expect(deviceStore, {'device_id': 'dev'});

    expect(await cb.read('jwt'), 'token');
    expect(await cb.read('device_id'), 'dev');
    expect(await cb.read('mnemonic_mainWallet'), 'cached mnemonic');
    expect(await cb.read('missing'), isNull);

    main['pix_a'] = '1';
    main['pix_b'] = '2';
    expect(await cb.listKeys('pix_'), ['pix_a', 'pix_b']);
    expect(await cb.listKeys('d'), ['device_id']);

    await cb.delete('jwt');
    await cb.delete('absent');
    expect(main.containsKey('jwt'), isFalse);
  });

  test('metrics derive a new device id from the hardware ids', () async {
    final s = setup();
    await s.apply(core);
    await s.metricsDone;

    verify(() => core.authDeviceId(serial: 'SER', platformId: 'PID')).called(1);
    final metrics = verify(
            () => core.apiSetMetrics(metrics: captureAny(named: 'metrics')))
        .captured
        .single as DeviceMetricsDto;
    expect(metrics.deviceId, 'dev-1');
    expect(metrics.batteryLevel, 80);
    expect(metrics.screenBrightness, 0.5);
    expect(metrics.bootTime, '2026-01-02T03:00:00.000Z');
  });

  test('metrics reuse the stored device id without hardware reads', () async {
    deviceStore['device_id'] = 'stored';
    final s = setup();
    await s.apply(core);
    await s.metricsDone;

    verify(() => core.authDeviceId()).called(1);
    verifyNever(() => core.authDeviceId(serial: 'SER', platformId: 'PID'));
  });

  test('a metrics failure is logged and does not throw', () async {
    when(() => core.authDeviceId(
          serial: any(named: 'serial'),
          platformId: any(named: 'platformId'),
        )).thenThrow(const CoreError(kind: CoreErrorKind.storage, message: 'x'));
    final s = setup();
    await s.apply(core);
    await s.metricsDone;

    expect(logger.hasTag('core.platform.metrics_failed'), isTrue);
    verifyNever(() => core.apiSetMetrics(metrics: any(named: 'metrics')));
  });
}
