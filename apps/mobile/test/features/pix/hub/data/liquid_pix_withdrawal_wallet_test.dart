import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/domain/entities/balance.dart';
import 'package:mooze_mobile/domain/entities/broadcast_result.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/fee_estimate.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/liquid_pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Liquid service that answers the calls of the adapter only.
class _FakeLiquid implements LiquidWalletService {
  final List<SendRequest> requests = [];

  Either<ServiceFailure, BroadcastResult> sendResult = Right(
    BroadcastResult(
      chain: ChainId.liquid,
      txId: 'txid-1',
      feePaidSat: 152,
      transaction: Transaction(
        id: 'txid-1',
        chain: ChainId.liquid,
        direction: TransactionDirection.outgoing,
        status: TransactionStatus.pending,
        amountSat: 4689000000,
        feeSat: 152,
        timestamp: DateTime.utc(2026, 10, 24, 12),
      ),
    ),
  );
  Either<ServiceFailure, FeeEstimate> estimateResult = const Right(
    FeeEstimate(
      chain: ChainId.liquid,
      priority: FeePriority.medium,
      absoluteFeeSat: 152,
    ),
  );
  bool throwOnSend = false;

  @override
  Future<Either<ServiceFailure, BroadcastResult>> sendOnchain(
    SendRequest request,
  ) async {
    requests.add(request);
    if (throwOnSend) throw StateError('bridge crashed');
    return sendResult;
  }

  @override
  Future<Either<ServiceFailure, FeeEstimate>> estimateFee(
    SendRequest request,
  ) async {
    requests.add(request);
    return estimateResult;
  }

  @override
  Future<Either<ServiceFailure, Balance>> getBalance() async => Right(
    Balance(
      assets: const [
        AssetBalance(
          chain: ChainId.liquid,
          amountSat: 5000,
          assetId: lbtcAssetId,
        ),
        AssetBalance(
          chain: ChainId.liquid,
          amountSat: 12300000000,
          assetId: depixAssetId,
        ),
      ],
      snapshotAt: DateTime.utc(2026, 10, 24),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ServiceFailure _failure(String message) =>
    ServiceFailure(message, chain: ChainId.liquid);

void main() {
  late _FakeLiquid liquid;
  late LiquidPixWithdrawalWallet wallet;

  setUp(() {
    liquid = _FakeLiquid();
    wallet = LiquidPixWithdrawalWallet(liquid);
  });

  test('sends exactly the deposit, as DePix, to the address', () async {
    final result = await wallet.send(
      address: 'lq1qqdeposit',
      amountSats: 4689000000,
    );

    expect(result, isA<PixFundingSent>());
    expect((result as PixFundingSent).txid, 'txid-1');
    expect(result.networkFeeSats, 152);
    final request = liquid.requests.single;
    expect(request.chain, ChainId.liquid);
    expect(request.destination, 'lq1qqdeposit');
    expect(request.amountSat, 4689000000);
    expect(request.assetId, depixAssetId);
    expect(request.drain, isFalse);
    expect(request.subtractFeeFromAmount, isFalse);
  });

  test('reads the DePix balance only', () async {
    final balance = await wallet.depixBalanceSats();
    expect(balance.getRight().toNullable(), 12300000000);
  });

  group('a failed send', () {
    // Texts of mooze-core and of the Dart service, as `ServiceFailure.message`
    // carries them.
    final notSent = <String, PixHubErrorCode>{
      'insufficient L-BTC for fees: missing 120 sats':
          PixHubErrorCode.insufficientFeeAsset,
      'lwk buildAssetTx failed: InsufficientFunds { missing_sats: 10 }':
          PixHubErrorCode.insufficientFunds,
      'lwk signTx failed: invalid mnemonic': PixHubErrorCode.fundingFailed,
      'mnemonic not available': PixHubErrorCode.fundingFailed,
      'not connected': PixHubErrorCode.walletUnavailable,
    };
    notSent.forEach((message, code) {
      test('stopped before the broadcast: $message', () async {
        liquid.sendResult = Left(_failure(message));

        final result = await wallet.send(address: 'lq1qq', amountSats: 1);

        expect(result, isA<PixFundingNotSent>());
        expect((result as PixFundingNotSent).failure.code, code);
      });
    });

    // A broadcast error, a timeout or an unknown text can hide a transaction
    // that reached the network.
    const uncertain = [
      'lwk broadcastSignedPset failed: connection reset',
      'lwk sendOnchain timeout',
      'lwk sendOnchain failed: network: electrum unreachable',
      'something new',
    ];
    for (final message in uncertain) {
      test('uncertain: $message', () async {
        liquid.sendResult = Left(_failure(message));

        final result = await wallet.send(address: 'lq1qq', amountSats: 1);

        expect(result, isA<PixFundingUncertain>());
      });
    }

    test('a throw is uncertain', () async {
      liquid.throwOnSend = true;

      final result = await wallet.send(address: 'lq1qq', amountSats: 1);

      expect(result, isA<PixFundingUncertain>());
    });
  });

  group('the fee estimate', () {
    test('returns the L-BTC fee of a DePix transfer', () async {
      final fee = await wallet.estimateNetworkFeeSats(
        address: 'lq1qqdeposit',
        amountSats: 4689000000,
      );

      expect(fee.getRight().toNullable(), 152);
      expect(liquid.requests.single.assetId, depixAssetId);
    });

    test('names a missing L-BTC balance', () async {
      liquid.estimateResult = Left(
        _failure('insufficient L-BTC for fees: missing 120 sats'),
      );

      final fee = await wallet.estimateNetworkFeeSats(
        address: 'lq1qq',
        amountSats: 1,
      );

      expect(
        fee.getLeft().toNullable()?.code,
        PixHubErrorCode.insufficientFeeAsset,
      );
    });
  });
}
