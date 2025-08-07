import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';

part 'liquid_fee_provider.g.dart';

@riverpod
Future<NetworkFee?> liquidFee(Ref ref) async {
  final wallet = ref.read(liquidWolletRepositoryProvider);
  final signer = ref.read(liquidSignerRepositoryProvider);
  final addrFuture = wallet.generateAddress();

  final addr = await addrFuture;

  final response = await signer.buildPartiallySignedTransaction(
    addr,
    1,
    feeRate: null,
  );

  return NetworkFee(absoluteFees: response.feeAmount ?? 100, feeRate: 1.0);
}
