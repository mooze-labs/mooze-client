import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/clean_address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/drain_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_estimation_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/partially_signed_transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/send_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../swap/presentation/fixed_fee_provider.dart';

class _NoRepository implements WalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Records the fee rate of each transaction that it starts, and stops
/// there.
class _RecordingController extends WalletController {
  _RecordingController() : super(_NoRepository());

  final rates = <double?>[];

  @override
  TaskEither<String, PartiallySignedTransaction> beginNewTransaction({
    required String destination,
    required Asset asset,
    required Blockchain blockchain,
    required BigInt amount,
    double? feeRateSatPerVByte,
    bool drain = false,
  }) {
    rates.add(feeRateSatPerVByte);
    return TaskEither.left('recorded');
  }

  @override
  TaskEither<String, PartiallySignedTransaction> beginDrainTransaction({
    required String destination,
    required Asset asset,
    required Blockchain blockchain,
    required BigInt amount,
    double? feeRateSatPerVByte,
  }) {
    rates.add(feeRateSatPerVByte);
    return TaskEither.left('recorded');
  }
}

/// A form that passed its checks, so the fee estimate runs.
class _ReadyValidation extends SendValidationController {
  _ReadyValidation(super.ref) {
    state = const SendValidationState(isValid: true, canProceed: true);
  }
}

void main() {
  late _RecordingController wallet;

  /// A BTC send on the Bitcoin network. The fee rates are economic 2,
  /// normal 5 and fast 9 sat/vB.
  ProviderContainer container({bool drain = false}) {
    wallet = _RecordingController();
    final container = ProviderContainer(
      overrides: [
        walletControllerProvider.overrideWith(
          (ref) async => Right<WalletError, WalletController>(wallet),
        ),
        selectedAssetProvider.overrideWith((ref) => Asset.btc),
        selectedNetworkProvider.overrideWithValue(Blockchain.bitcoin),
        cleanAddressProvider.overrideWithValue('bc1qdestination'),
        finalAmountProvider.overrideWithValue(10000),
        isDrainTransactionProvider.overrideWithValue(drain),
        bitcoinFeeServiceProvider.overrideWithValue(FixedFeeProvider().service),
        sendValidationControllerProvider.overrideWith(_ReadyValidation.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the transaction starts at the custom rate', () async {
    final c = container();
    c.read(customFeeRateProvider.notifier).state = 14;

    await c.read(psbtProvider.future);

    expect(wallet.rates, [14]);
  });

  test('a rate below 1 sat/vB keeps its tenths down to the wallet', () async {
    final c = container();
    c.read(customFeeRateProvider.notifier).state = 0.3;

    await c.read(feeEstimationProvider.future);
    await c.read(psbtProvider.future);

    expect(wallet.rates, [0.3, 0.3]);
  });

  test('the fee estimate of the form uses the rate of the send, so the '
      'balance check counts its fee', () async {
    final c = container();
    c.read(feeSpeedProvider.notifier).state = FeeSpeed.fast;
    await c.read(feeEstimationProvider.future);

    c.read(customFeeRateProvider.notifier).state = 14;
    await c.read(feeEstimationProvider.future);

    expect(wallet.rates, [9, 14]);
  });

  test('a send of the whole balance uses the rate too', () async {
    final c = container(drain: true);
    c.read(customFeeRateProvider.notifier).state = 14;

    await c.read(feeEstimationProvider.future);
    await c.read(psbtProvider.future);

    expect(wallet.rates, [14, 14]);
  });
}
