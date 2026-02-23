import 'package:fpdart/fpdart.dart';

import '../datasources.dart';

import '../../domain/repositories/phone_verification_repository.dart';
import '../../domain/entities.dart';
import 'dart:convert';

class PhoneVerificationRepositoryImpl implements PhoneVerificationRepository {
  final PhoneVerificationDatasource phoneVerificationDatasource;
  final VerificationStatusDatasource verificationStatusDatasource;
  final DeviceInfoDatasource deviceInfoDatasource;
  final IpAddressDatasource ipAddressDatasource;

  PhoneVerificationRepositoryImpl({
    required this.phoneVerificationDatasource,
    required this.deviceInfoDatasource,
    required this.ipAddressDatasource,
    required this.verificationStatusDatasource,
  });

  @override
  TaskEither<String, String> beginPhoneVerification(
    String phoneNumber,
    PhoneVerificationMethod method,
  ) {
    return TaskEither.tryCatch(() async {
      // Collect device information
      final deviceModelTask = deviceInfoDatasource.getDeviceModel();
      final deviceVersionTask = deviceInfoDatasource.getDeviceVersion();
      final appVersionTask = deviceInfoDatasource.getAppVersion();
      final deviceIdTask = deviceInfoDatasource.getDeviceId();
      final ipAddressTask = ipAddressDatasource.getIpAddress();

      // Execute all tasks concurrently
      final results =
          await (
            deviceModelTask.run(),
            deviceVersionTask.run(),
            appVersionTask.run(),
            deviceIdTask.run(),
            ipAddressTask.run(),
          ).wait;

      // Extract results
      final String? deviceModel = results.$1.fold(
        (error) => null,
        (model) => model,
      );
      final String? deviceVersion = results.$2.fold(
        (error) => null,
        (version) => version,
      );
      final String? appVersion = results.$3.fold(
        (error) => null,
        (version) => version,
      );
      final String? deviceId = results.$4.fold((error) => null, (id) => id);
      final String? ipAddress = results.$5.fold((error) => null, (ip) => ip);

      final platform = deviceInfoDatasource.getDevicePlatform();
      final methodString = method.name;

      // Call the phone verification datasource
      final verificationResult =
          await phoneVerificationDatasource
              .startPhoneVerification(
                phoneNumber,
                methodString,
                ipAddress: ipAddress,
                deviceId: deviceId,
                platform: platform,
                deviceModel: deviceModel,
                appVersion: appVersion,
                osVersion: deviceVersion,
              )
              .run();

      return verificationResult.fold(
        (error) => throw Exception(error),
        (verificationId) => verificationId,
      );
    }, (error, stackTrace) => error.toString());
  }

  @override
  TaskEither<String, bool> verifyCode(String verificationId, String code) {
    return TaskEither.tryCatch(() async {
      final verificationResult =
          await phoneVerificationDatasource
              .verifyPhoneCode(verificationId, code)
              .run();

      return verificationResult.fold(
        (error) => throw Exception(error),
        (success) => success,
      );
    }, (error, stackTrace) => error.toString());
  }

  @override
  Stream<Either<String, VerificationStatus>> watchStatus(
    String verificationId,
  ) {
    final stream = verificationStatusDatasource.listen(verificationId);
    return stream.map(
      (event) => event.fold(
        (error) => Left(error),
        (status) => Right(VerificationStatus.fromJson(jsonDecode(status))),
      ),
    );
  }
}
