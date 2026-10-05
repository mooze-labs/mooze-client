import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';
import 'package:safe_device/safe_device.dart';
import 'package:unique_identifier/unique_identifier.dart';

import '../../shared/authentication/models/device_info.dart';
import '../../shared/authentication/services/device_info_service.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/storage/mnemonic_prefetch.dart';
import '../../shared/storage/secure_storage.dart';

/// Raw hardware identifiers for `MoozeCore.authDeviceId`.
typedef HardwareIds = ({String? serial, String? platformId});

/// Gives the core the platform services that the API session needs.
///
/// [apply] runs right after `MoozeCore.open`, before any other core call:
/// 1. Registers the secure-storage callbacks.
/// 2. Sets the backend base URL if the build overrides `BACKEND_API_URL`.
/// 3. Sets the device integrity result (`SafeDevice`, release builds only).
/// 4. Starts the device metrics collection. This step does not block.
class CorePlatformSetup {
  CorePlatformSetup({
    required this.logger,
    FlutterSecureStorage? storage,
    FlutterSecureStorage? deviceIdStorage,
    Future<String?> Function()? readMnemonic,
    Future<bool> Function()? isSafeDevice,
    Future<DeviceInfo> Function()? deviceInfo,
    Future<HardwareIds> Function()? hardwareIds,
    String? baseUrlOverride,
  })  : _storage = storage ?? SecureStorageProvider.instance,
        _deviceIdStorage = deviceIdStorage ?? _legacyDeviceIdStorage,
        _readMnemonic = readMnemonic ?? MnemonicPrefetch.get,
        _isSafeDevice = isSafeDevice ?? _defaultIsSafeDevice,
        _deviceInfo = deviceInfo ?? (() => DeviceInfoService().getDeviceInfo()),
        _hardwareIds = hardwareIds ?? _defaultHardwareIds,
        _baseUrlOverride = baseUrlOverride ?? _envBaseUrl;

  final StructuredLogger logger;
  final FlutterSecureStorage _storage;
  final FlutterSecureStorage _deviceIdStorage;
  final Future<String?> Function() _readMnemonic;
  final Future<bool> Function() _isSafeDevice;
  final Future<DeviceInfo> Function() _deviceInfo;
  final Future<HardwareIds> Function() _hardwareIds;
  final String? _baseUrlOverride;

  /// Secure-store key of the device id. The legacy `DeviceIdService` kept
  /// it in a storage with other iOS Keychain options, so this key keeps
  /// that storage. A different storage gives the device a new id.
  static const String deviceIdKey = 'device_id';

  /// The options of the legacy `DeviceIdService` storage.
  static const FlutterSecureStorage _legacyDeviceIdStorage =
      FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static const String? _envBaseUrl = bool.hasEnvironment('BACKEND_API_URL')
      ? String.fromEnvironment('BACKEND_API_URL')
      : null;

  /// The completed metrics step of the last [apply]. Tests await it.
  @visibleForTesting
  Future<void>? metricsDone;

  /// Configures [core]. Call it once, right after `MoozeCore.open`.
  Future<void> apply(MoozeCore core) async {
    await core.setSecureStorage(
      read: _read,
      write: _write,
      delete: _delete,
      listKeys: _listKeys,
    );
    final baseUrl = _baseUrlOverride;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      await core.apiSetBaseUrl(baseUrl: baseUrl);
    }
    final safe = await _safeDevice();
    await core.authSetDeviceSafe(safe: safe);
    logger.info('core.platform.ready', {
      'base_url_override': baseUrl != null && baseUrl.isNotEmpty,
      'device_safe': safe,
    });
    metricsDone = _applyMetrics(core);
    unawaited(metricsDone);
  }

  FlutterSecureStorage _storageFor(String key) =>
      key == deviceIdKey ? _deviceIdStorage : _storage;

  Future<String?> _read(String key) {
    // The mnemonic prefetch cache holds the same Keychain read.
    if (key == MnemonicPrefetch.key) return _readMnemonic();
    return _storageFor(key).read(key: key);
  }

  Future<void> _write(String key, String value) async {
    await _storageFor(key).write(key: key, value: value);
    if (key == MnemonicPrefetch.key) MnemonicPrefetch.clear();
  }

  Future<void> _delete(String key) async {
    await _storageFor(key).delete(key: key);
    if (key == MnemonicPrefetch.key) MnemonicPrefetch.clear();
  }

  Future<List<String>> _listKeys(String prefix) async {
    final all = await _storage.readAll();
    final keys = all.keys.where((k) => k.startsWith(prefix)).toSet();
    if (deviceIdKey.startsWith(prefix) &&
        await _deviceIdStorage.containsKey(key: deviceIdKey)) {
      keys.add(deviceIdKey);
    }
    return keys.toList()..sort();
  }

  /// Same rule as the legacy interceptor: debug and profile builds are
  /// safe; a failed check is unsafe.
  Future<bool> _safeDevice() async {
    try {
      return await _isSafeDevice();
    } catch (e) {
      logger.warn('core.platform.safe_device_failed', {'error': '$e'});
      return false;
    }
  }

  Future<void> _applyMetrics(MoozeCore core) async {
    try {
      final stored = await core.secureGet(key: deviceIdKey);
      final String deviceId;
      if (stored != null && stored.isNotEmpty) {
        deviceId = await core.authDeviceId();
      } else {
        final ids = await _hardwareIds();
        deviceId = await core.authDeviceId(
          serial: ids.serial,
          platformId: ids.platformId,
        );
      }
      final info = await _deviceInfo();
      await core.apiSetMetrics(
        metrics: DeviceMetricsDto(
          deviceId: deviceId,
          batteryLevel: info.batteryLevel,
          screenBrightness: info.screenBrightness,
          bootTime: info.bootTime?.toIso8601String(),
        ),
      );
    } catch (e) {
      // The legacy interceptor sent requests without metrics on failure.
      logger.warn('core.platform.metrics_failed', {'error': '$e'});
    }
  }

  static Future<bool> _defaultIsSafeDevice() async {
    if (!kReleaseMode) return true;
    return SafeDevice.isSafeDevice;
  }

  static Future<HardwareIds> _defaultHardwareIds() async {
    String? serial;
    try {
      serial = await UniqueIdentifier.serial;
    } catch (_) {}
    String? platformId;
    try {
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        platformId = (await plugin.androidInfo).id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platformId = (await plugin.iosInfo).identifierForVendor;
      }
    } catch (_) {}
    return (serial: serial, platformId: platformId);
  }
}
