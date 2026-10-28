import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/domain/entities/broadcast_result.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' show depixAssetId;

/// [PixWithdrawalWallet] over the LWK-backed Liquid service of mooze-core.
///
/// The Liquid service pays the network fee in L-BTC for every asset transfer.
class LiquidPixWithdrawalWallet implements PixWithdrawalWallet {
  LiquidPixWithdrawalWallet(this._liquid);

  final LiquidWalletService _liquid;

  @override
  Future<Either<PixHubFailure, String>> refundAddress() async {
    final result = await _liquid.getReceiveAddress();
    return result.mapLeft(
      (f) => PixHubFailure(
        PixHubErrorCode.walletUnavailable,
        rawMessage: f.message,
      ),
    );
  }

  @override
  Future<Either<PixHubFailure, int>> depixBalanceSats() async {
    final result = await _liquid.getBalance();
    return result.bimap(
      (f) => PixHubFailure(
        PixHubErrorCode.walletUnavailable,
        rawMessage: f.message,
      ),
      (balance) {
        for (final asset in balance.assets) {
          if (asset.assetId == depixAssetId) return asset.amountSat;
        }
        return 0;
      },
    );
  }

  @override
  Future<Either<PixHubFailure, int>> estimateNetworkFeeSats({
    required String address,
    required int amountSats,
  }) async {
    final result = await _liquid.estimateFee(_request(address, amountSats));
    return result.bimap(
      (f) => buildFailure(f.message),
      (estimate) => estimate.absoluteFeeSat,
    );
  }

  @override
  Future<PixFundingResult> send({
    required String address,
    required int amountSats,
  }) async {
    final Either<ServiceFailure, BroadcastResult> result;
    try {
      result = await _liquid.sendOnchain(_request(address, amountSats));
    } catch (e) {
      // The service returns failures as values. A throw here gives no proof
      // about the broadcast.
      return PixFundingUncertain(rawMessage: '$e');
    }
    return result.fold(
      (f) => classifySendFailure(f.message),
      (broadcast) => PixFundingSent(
        txid: broadcast.txId,
        networkFeeSats: broadcast.feePaidSat,
      ),
    );
  }

  SendRequest _request(String address, int amountSats) {
    return SendRequest(
      chain: ChainId.liquid,
      destination: address,
      amountSat: amountSats,
      assetId: depixAssetId,
    );
  }

  /// Maps a failed transaction build to a hub failure.
  ///
  /// The texts come from mooze-core: `Error::InsufficientFeeAsset` and the
  /// LWK `InsufficientFunds` error inside `lwk buildAssetTx failed`.
  static PixHubFailure buildFailure(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('insufficient l-btc')) {
      return PixHubFailure(
        PixHubErrorCode.insufficientFeeAsset,
        rawMessage: message,
      );
    }
    if (lower.contains('insufficient') || lower.contains('balance is zero')) {
      return PixHubFailure(
        PixHubErrorCode.insufficientFunds,
        rawMessage: message,
      );
    }
    if (lower.contains('not connected')) {
      return PixHubFailure(
        PixHubErrorCode.walletUnavailable,
        rawMessage: message,
      );
    }
    return PixHubFailure(PixHubErrorCode.fundingFailed, rawMessage: message);
  }

  /// Sorts a failed send into "not sent" and "uncertain".
  ///
  /// The mobile bridge returns a broadcast error as a plain error, like a
  /// build error. Only the texts below come from steps that run before the
  /// broadcast. Any other text can come from the broadcast itself, so it is
  /// uncertain: the transaction may have reached the network.
  static PixFundingResult classifySendFailure(String message) {
    final lower = message.toLowerCase();
    final beforeBroadcast = _beforeBroadcastMarkers.any(lower.contains);
    if (!beforeBroadcast) return PixFundingUncertain(rawMessage: message);
    return PixFundingNotSent(buildFailure(message));
  }

  /// Error texts of mooze-core and of the Dart service that come from the
  /// checks, the build or the signature, never from the broadcast.
  static const List<String> _beforeBroadcastMarkers = [
    'not connected',
    'no credential store',
    'liquid service only handles',
    'amount must be positive',
    'destination is empty',
    'mnemonic not available',
    'mnemonic is empty',
    'lwk buildassettx failed',
    'insufficient l-btc',
    'asset balance is zero',
    'lwk signtx failed',
  ];
}
