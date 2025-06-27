import 'dart:io';

class PhoneVerificationRequest {
  final String phoneNumber;
  final String appVersion;
  final Platform platform;
  final String? ip;
  final String? deviceId;
  final String? osVersion;

  PhoneVerificationRequest({
    required this.phoneNumber,
    required this.appVersion,
    required this.platform,
    this.ip,
    this.deviceId,
    this.osVersion,
  });
}

class PhoneVerificationValidation {
  final String phoneNumber;
  final String code;

  PhoneVerificationValidation({required this.phoneNumber, required this.code});
}
