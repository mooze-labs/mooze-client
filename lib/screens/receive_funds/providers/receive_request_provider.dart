import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mooze_mobile/providers/wallet/breez_provider.dart';
import '../providers/receive_invoice_provider.dart';

part 'receive_request_provider.g.dart';

@riverpod
Future<ReceivePaymentResponse> acceptReceiveRequest(
  Ref ref,
  PrepareReceiveResponse response,
) async {
  final breezRepository = ref.watch(breezRepositoryProvider);
  final receiveInvoice = ref.watch(receiveInvoiceNotifierProvider);

  final res = await breezRepository.client?.receivePayment(
    req: ReceivePaymentRequest(
      prepareResponse: response,
      description: receiveInvoice.description,
    ),
  );

  return res!;
}
