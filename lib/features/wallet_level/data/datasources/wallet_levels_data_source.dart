import '../models/wallet_levels_response_model.dart';

abstract class WalletLevelsDataSource {
  Future<WalletLevelsResponseModel> getWalletLevels();
}
