import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fpdart/fpdart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:unique_identifier/unique_identifier.dart';

class DeviceInfoDatasource {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  TaskEither<String, Either<AndroidDeviceInfo, IosDeviceInfo>>
  _getDeviceInfo() {
    if (Platform.isAndroid) {
      return TaskEither.tryCatch(
        () async => Either.left(await deviceInfoPlugin.androidInfo),
        (error, stackTrace) => error.toString(),
      );
    } else if (Platform.isIOS) {
      return TaskEither.tryCatch(
        () async => Either.right(await deviceInfoPlugin.iosInfo),
        (error, stackTrace) => error.toString(),
      );
    }

    return TaskEither.left('Device info not found');
  }

  TaskEither<String, String> getDeviceModel() {
    return _getDeviceInfo().map(
      (deviceInfo) => deviceInfo.match(
        (androidInfo) => androidInfo.model,
        (iosInfo) => iosInfo.model,
      ),
    );
  }

  TaskEither<String, String> getDeviceVersion() {
    return _getDeviceInfo().map(
      (deviceInfo) => deviceInfo.match(
        (androidInfo) => androidInfo.version.release,
        (iosInfo) => iosInfo.systemVersion,
      ),
    );
  }

  String getDevicePlatform() {
    return Platform.isAndroid ? 'android' : 'ios';
  }

  TaskEither<String, String> getAppVersion() {
    return TaskEither.tryCatch(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, String> getDeviceId() {
    return TaskEither.tryCatch(() async {
      final deviceId = await UniqueIdentifier.serial;
      return deviceId ?? 'unknown';
    }, (error, stackTrace) => error.toString());
  }
}
