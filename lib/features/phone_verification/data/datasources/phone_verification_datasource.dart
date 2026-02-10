import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

const int _timeoutDuration = 10;

class PhoneVerificationDatasource {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://api.mooze.app/v1/',
      ),
      connectTimeout: const Duration(seconds: _timeoutDuration),
      receiveTimeout: const Duration(seconds: _timeoutDuration),
    ),
  );

  TaskEither<String, String> startPhoneVerification(
    String phoneNumber,
    String method, {
    String? ipAddress,
    String? deviceId,
    String? platform,
    String? deviceModel,
    String? appVersion,
    String? osVersion,
  }) {
    final body = {
      'phone_number': phoneNumber,
      'method': method,
      'ip_address': ipAddress,
      'device_id': deviceId,
      'platform': platform,
      'device_model': deviceModel,
      'app_version': appVersion,
      'os_version': osVersion,
    };

    return TaskEither.tryCatch(() async {
      final response = await dio.post("/phone/begin_verification", data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['verification_id'] != null) {
          return data['verification_id'] as String;
        } else {
          throw Exception(
            'Serviço de verificação de telefone não está disponível. Tente novamente mais tarde.',
          );
        }
      } else {
        throw Exception(
          'Falha ao enviar o código de verificação: \nStatus: ${response.statusMessage}',
        );
      }
    }, (error, stackTrace) => error.toString());
  }

  TaskEither<String, bool> verifyPhoneCode(String verificationId, String code) {
    final body = {'verification_id': verificationId, 'code': code};

    return TaskEither.tryCatch(() async {
      final response = await dio.post("/phone/verify", data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.data);
        return data['success'] as bool;
      } else {
        throw Exception(
          'Falha ao verificar o telefone: \nStatus: ${response.statusMessage}',
        );
      }
    }, (error, stackTrace) => error.toString());
  }
}
