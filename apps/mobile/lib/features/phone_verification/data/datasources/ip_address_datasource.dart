import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

const String _ipAddressApiUrl = 'https://api.ipify.org?format=json';

class IpAddressDatasource {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: String.fromEnvironment(
        'IP_ADDRESS_API_URL',
        defaultValue: _ipAddressApiUrl,
      ),
    ),
  );

  TaskEither<String, String> getIpAddress() {
    return TaskEither.tryCatch(() async {
      final response = await dio.get('/');
      if (response.statusCode == 200) {
        return response.data['ip'] as String;
      } else {
        throw Exception(
          'Falha ao obter o endereço IP: \nStatus: ${response.statusMessage}',
        );
      }
    }, (error, stackTrace) => error.toString());
  }
}
