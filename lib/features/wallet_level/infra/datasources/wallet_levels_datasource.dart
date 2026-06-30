import 'package:mooze_mobile/features/wallet_level/infra/models/wallet_levels_response_model.dart';

/// Wallet Levels Data Source Contract (Infrastructure Layer)
///
/// Defines the contract for fetching wallet level data.
/// Concrete implementations live in the external layer.
abstract class WalletLevelsDataSource {
  Future<WalletLevelsResponseModel> getWalletLevels();
}
