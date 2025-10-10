import 'package:dio/dio.dart';
import '../models/wallet_levels_response_model.dart';
import 'wallet_levels_data_source.dart';

class WalletLevelsRemoteDataSource implements WalletLevelsDataSource {
  final Dio dio;

  WalletLevelsRemoteDataSource({required this.dio});

  @override
  Future<WalletLevelsResponseModel> getWalletLevels() async {
    final response = await dio.get(
      'https://mooze-public.s3.us-east-1.amazonaws.com/user_levels.json',
    );
    return WalletLevelsResponseModel.fromJson(response.data);
  }
}
