import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'selected_asset_provider.dart';
import 'selected_network_provider.dart';

final feeSpeedProvider = StateProvider<FeeSpeed>((ref) => FeeSpeed.medium);

/// The fee rate that the user set for a Bitcoin on-chain send, in sat/vB,
/// with tenths, such as 0.5. Null while a speed of [feeSpeedProvider]
/// applies.
final customFeeRateProvider = StateProvider<double?>((ref) => null);

/// The fee rate of a Bitcoin on-chain send, in sat/vB: the custom rate, or
/// the rate of the selected speed.
///
/// The fee estimate of the form and the transaction both use it, so the
/// balance check counts the fee that the send pays. Null for other sends,
/// and when the fee rates do not load: the wallet then uses its default
/// rate.
final bitcoinSendFeeRateProvider = FutureProvider<double?>((ref) async {
  final asset = ref.watch(selectedAssetProvider);
  final blockchain = ref.watch(selectedNetworkProvider);
  if (asset != Asset.btc || blockchain != Blockchain.bitcoin) return null;

  final custom = ref.watch(customFeeRateProvider);
  if (custom != null) return custom;

  final speed = ref.watch(feeSpeedProvider);
  final estimate = await ref.read(bitcoinFeeServiceProvider).fetchFeeEstimate();
  if (estimate == null) return null;
  return switch (speed) {
    FeeSpeed.low => estimate.lowFeeSatPerVByte,
    FeeSpeed.medium => estimate.mediumFeeSatPerVByte,
    FeeSpeed.fast => estimate.fastFeeSatPerVByte,
  }.toDouble();
});
