import 'package:dio/dio.dart';
import 'package:mooze_mobile/features/wallet_level/infra/datasources/wallet_levels_datasource.dart';
import 'package:mooze_mobile/features/wallet_level/infra/models/wallet_levels_response_model.dart';

/// Wallet Levels Remote Data Source (External Layer)
///
/// Fetches wallet level configuration from the remote S3 endpoint.
/// This is the concrete implementation of the datasource contract,
/// isolated in the external layer so it can be swapped without
/// affecting the infra or domain layers.
class WalletLevelsRemoteDataSource implements WalletLevelsDataSource {
  final Dio _dio;

  const WalletLevelsRemoteDataSource(this._dio);

  @override
  Future<WalletLevelsResponseModel> getWalletLevels() async {
    final response = await _dio.get(
      'https://mooze-public.s3.us-east-1.amazonaws.com/user_levels.json',
    );
    return WalletLevelsResponseModel.fromJson(response.data);
  }
}
