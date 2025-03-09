import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/repositories/pix_gateway.dart';

part 'pix_gateway_provider.g.dart';

@riverpod
PixGatewayRepository pixGatewayRepository(Ref ref) {
  return PixGatewayRepository();
}

@riverpod
Future<PixTransactionResponse?> pixPayment(
  Ref ref,
  PixTransaction transaction,
) async {
  final repository = ref.watch(pixGatewayRepositoryProvider);
  return repository.newPixPayment(transaction);
}
