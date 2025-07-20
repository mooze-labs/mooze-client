import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import 'referral_service.dart';

class ReferralServiceImpl implements ReferralService {
  final Dio _dio;

  ReferralServiceImpl(Dio dio) : _dio = dio;

  @override
  TaskEither<String, bool> validateReferralCode(String referralCode) {
    return TaskEither.tryCatch(() async {
      final response = await _dio.get(
        "/referrals/${referralCode.toUpperCase()}",
      );

      final json = jsonDecode(response.data as String);

      if (json["error"] != null) {
        throw Exception(json["error"] as String);
      }

      if (response.statusCode == 404) {
        throw Exception("Referral not found.");
      }

      if (response.statusCode != 200) {
        throw Exception(
          "Error when validating code: ${response.statusMessage}",
        );
      }

      return json["data"];
    }, (error, stackTrace) => error.toString());
  }
}
