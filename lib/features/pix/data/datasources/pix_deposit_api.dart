import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:mooze_mobile/features/pix/data/models/pix_transaction_details.dart';

const String backendApiUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://api.mooze.app',
);

class PixDepositApi {
  final Dio _dio;

  PixDepositApi(Dio dio) : _dio = dio;

  TaskEither<String, List<PixTransactionDetails>> getDeposits(
    List<String> ids,
  ) {
    return TaskEither.tryCatch(
      () async {
        final url = '$backendApiUrl/transactions/status';

        final response = await _dio.get(
          url,
          queryParameters: {'ids': ids},
          options: Options(validateStatus: (status) => true),
        );

        if (response.statusCode != 200) {
          final errorMsg = 'Erro HTTP ${response.statusCode}: ${response.data}';
          throw Exception(errorMsg);
        }

        final jsonResponse =
            response.data is String
                ? jsonDecode(response.data)
                : response.data as Map<String, dynamic>;

        final List list = jsonResponse['data'] ?? [];

        final pixDetails =
            list
                .map(
                  (e) => PixTransactionDetails.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList();

        return pixDetails;
      },
      (error, stackTrace) {
        final errorMsg = 'Erro ao buscar depósitos: $error';

        return errorMsg;
      },
    );
  }
}
