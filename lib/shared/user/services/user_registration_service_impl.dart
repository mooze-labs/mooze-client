import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';

import 'user_registration_service.dart';

const _timeout = Duration(seconds: 10);

class UserRegistrationServiceImpl implements UserRegistrationService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: "https://api.mooze.app/v1/",
      ),
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
  );

  UserRegistrationServiceImpl();

  @override
  TaskEither<String, User> createNewUser(
    String publicKey,
    String? referralCode,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await _dio.post(
        "/registration",
        data: jsonEncode({
          "public_key": publicKey,
          "referral_code": referralCode,
        }),
      );

      if (response.statusCode == 409) {
        throw Exception("User already exists.");
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Error when creating user: ${response.statusCode}");
      }

      return User.fromJson(jsonDecode(response.data as String));
    }, (error, stackTrace) => error.toString());
  }
}
