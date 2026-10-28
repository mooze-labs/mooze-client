import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';

/// Result of a DePix transfer that funds a withdrawal.
sealed class PixFundingResult {
  const PixFundingResult();
}

/// The wallet broadcast the transfer.
class PixFundingSent extends PixFundingResult {
  final String txid;

  /// Liquid network fee paid in L-BTC, in satoshis.
  final int? networkFeeSats;

  const PixFundingSent({required this.txid, this.networkFeeSats});
}

/// The wallet stopped before the broadcast. No funds left the wallet.
class PixFundingNotSent extends PixFundingResult {
  final PixHubFailure failure;

  const PixFundingNotSent(this.failure);
}

/// The broadcast failed, but the transaction may have reached the network.
class PixFundingUncertain extends PixFundingResult {
  /// Wallet error, kept for logs. It is not shown to the user.
  final String? rawMessage;

  const PixFundingUncertain({this.rawMessage});
}

/// The wallet operations that a Pix withdrawal needs.
abstract class PixWithdrawalWallet {
  /// A bare Liquid address of the wallet, for the refund of a withdrawal.
  Future<Either<PixHubFailure, String>> refundAddress();

  /// DePix balance of the wallet, in base units.
  ///
  /// The value comes from the local wallet view. Use it to warn early. The
  /// transaction build is the check that decides.
  Future<Either<PixHubFailure, int>> depixBalanceSats();

  /// Builds, without signing, a transfer of [amountSats] DePix to [address].
  ///
  /// Returns the Liquid network fee in L-BTC satoshis. The build fails when
  /// the wallet lacks DePix or L-BTC.
  Future<Either<PixHubFailure, int>> estimateNetworkFeeSats({
    required String address,
    required int amountSats,
  });

  /// Builds, signs and broadcasts a transfer of [amountSats] DePix to
  /// [address].
  Future<PixFundingResult> send({
    required String address,
    required int amountSats,
  });
}
