import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/repositories/wallet/signer.dart';
import 'package:mooze_mobile/repositories/wallet/wollet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'bitcoin_fee_provider.g.dart';

@riverpod
Future<NetworkFee?> bitcoinFee(Ref ref, int estimatedBlocks) async {
  final wallet =
      ref.read(bitcoinWolletRepositoryProvider) as BitcoinWolletRepository;
  final signer =
      ref.read(bitcoinSignerRepositoryProvider) as BitcoinSignerRepository;

  Future<String> addrFuture = wallet.generateAddress();
  Future<FeeRate> estimatedFeesFuture =
      wallet.blockchain?.estimateFee(target: BigInt.from(estimatedBlocks)) ??
      Future.value(FeeRate(satPerVb: 2));

  final (addr, estimatedFees) = await (addrFuture, estimatedFeesFuture).wait;
  try {
    final response = await signer.buildPartiallySignedTransaction(
      addr,
      546,
      feeRate: estimatedFees.satPerVb,
    );

    return NetworkFee(
      absoluteFees: response.feeAmount ?? 100,
      feeRate: estimatedFees.satPerVb,
    );
  } catch (e) {
    return NetworkFee(absoluteFees: 200, feeRate: estimatedFees.satPerVb);
  }
}
