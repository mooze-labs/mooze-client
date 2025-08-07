import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/wallet/breez_provider.dart';
import 'package:mooze_mobile/screens/receive_funds/providers/receive_invoice_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

import '../models/receive_crypto_input.dart' as model;

part 'prepare_receive_request_provider.g.dart';

@riverpod
Future<PrepareReceiveResponse> fetchReceiveDetails(Ref ref) async {
  final recvInvoice = ref.watch(receiveInvoiceNotifierProvider);
  final breezRepository = ref.watch(breezRepositoryProvider);

  final paymentMethod = switch (recvInvoice.network) {
    model.Network.bitcoin => PaymentMethod.bitcoinAddress,
    model.Network.liquid => PaymentMethod.liquidAddress,
    model.Network.lightning => PaymentMethod.bolt11Invoice,
  };

  final amount = _getReceiveAmount(paymentMethod, recvInvoice);

  // Lightning invoices require an amount
  if (paymentMethod == PaymentMethod.bolt11Invoice && amount == null) {
    throw Exception("Amount is required for lightning invoice");
  }

  // Make the request with the determined payment method and amount
  final response = await breezRepository.client?.prepareReceivePayment(
    req: PrepareReceiveRequest(paymentMethod: paymentMethod, amount: amount),
  );

  return response!;
}

// Helper function to prepare the ReceiveAmount based on payment method
ReceiveAmount? _getReceiveAmount(
  PaymentMethod method,
  model.ReceiveCryptoInput invoice,
) {
  if (method == PaymentMethod.liquidAddress && invoice.assetId != null) {
    // Convert satoshis to BTC
    final payerAmount =
        invoice.recvAmount != null
            ? invoice.recvAmount! /
                100000000 // 10^8 satoshis per BTC
            : null;
    return ReceiveAmount_Asset(
      assetId: invoice.assetId!,
      payerAmount: payerAmount,
    );
  } else if (method == PaymentMethod.bitcoinAddress ||
      method == PaymentMethod.bolt11Invoice) {
    return invoice.recvAmount != null
        ? ReceiveAmount_Bitcoin(
          payerAmountSat: BigInt.from(invoice.recvAmount!),
        )
        : null;
  }
  return null;
}
