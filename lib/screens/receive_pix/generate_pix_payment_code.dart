import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/providers/external/pix_gateway_provider.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/pix_qr_display.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/transaction_info.dart';
import 'package:mooze_mobile/utils/store_mode.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class GeneratePixPaymentCodeScreen extends ConsumerStatefulWidget {
  final PixTransaction pixTransaction;
  final String assetId;

  const GeneratePixPaymentCodeScreen({
    super.key,
    required this.pixTransaction,
    this.assetId =
        "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189", // defaults to Depix
  });

  @override
  GeneratePixPaymentCodeState createState() => GeneratePixPaymentCodeState();
}

class GeneratePixPaymentCodeState
    extends ConsumerState<GeneratePixPaymentCodeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(pixPaymentProvider(widget.pixTransaction));

    return Scaffold(
      appBar: MoozeAppBar(
        title: 'Gerar pagamento PIX',
        action: IconButton(
          icon: Icon(Icons.home),
          onPressed: () async {
            final isStoreMode = await StoreModeHandler().isStoreMode();
            if (isStoreMode) {
              Navigator.pushNamed(context, "/store_mode");
            } else {
              Navigator.pushNamed(context, "/wallet");
            }
          },
        ),
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          return Center(child: Text("Erro: $err"));
        },
        data: (response) {
          if (response == null) {
            return const Center(
              child: Text("Falha ao criar transação. Tente novamente."),
            );
          }

          return Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: PixQrDisplay(
                    qrImageUrl: response.qrImageUrl,
                    qrCopyPaste: response.qrCopyPaste,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Escaneie o código QR acima para pagar.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: "roboto",
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: TransactionInfo(
                    amount: widget.pixTransaction.brlAmount,
                    assetId: widget.assetId,
                    address: widget.pixTransaction.address,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
