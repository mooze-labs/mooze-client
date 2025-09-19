import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:mooze_mobile/features/pix/data/models.dart';

const String backendApiUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'https://api.mooze.app/v1/',
);

class PixDepositApi {
  final Dio _dio;

  PixDepositApi(Dio dio) : _dio = dio;

  TaskEither<String, List<PixStatusEvent>> getDeposits(List<String> ids) {
    return TaskEither.tryCatch(() async {
      final response = await _dio.get(
        "$backendApiUrl/transactions/statuses",
        queryParameters: {'ids': ids},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.data);
        final List<Map<String, dynamic>> statusesArray = jsonResponse['data'];
        final pixStatuses =
            statusesArray.map((json) => PixStatusEvent.fromJson(json)).toList();

        return pixStatuses;
      }

      throw Error();
    }, (error, stackTrace) => error.toString());
  }
}
