import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../models/device_info.dart';

class DeviceInfoService {
  final Battery _battery = Battery();
  final ScreenBrightness _screenBrightness = ScreenBrightness();

  /// Collects all device information
  Future<DeviceInfo> getDeviceInfo() async {
    final batteryLevel = await _getBatteryLevel();
    final screenBrightness = await _getScreenBrightness();
    final bootTime = await _getBootTime();

    return DeviceInfo(
      batteryLevel: batteryLevel,
      screenBrightness: screenBrightness,
      bootTime: bootTime,
    );
  }

  /// Gets battery level (0-100)
  Future<int?> _getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return null;
    }
  }

  /// Gets screen brightness (0.0-1.0)
  Future<double?> _getScreenBrightness() async {
    try {
      return await _screenBrightness.current;
    } catch (e) {
      return null;
    }
  }

  /// Gets device boot time
  Future<DateTime?> _getBootTime() async {
    try {
      // On Android/iOS, we can use platform channels to get boot time
      const platform = MethodChannel('com.mooze.deviceinfo/boot_time');
      final bootTimeMillis = await platform.invokeMethod<int>('getBootTime');

      if (bootTimeMillis != null) {
        return DateTime.fromMillisecondsSinceEpoch(bootTimeMillis);
      }

      return null;
    } catch (e) {
      // Fallback: if unable to get via platform channel, return null
      return null;
    }
  }
}
