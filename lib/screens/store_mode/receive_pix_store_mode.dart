import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/store_mode/generate_pix_payment_code.dart';
import 'package:mooze_mobile/screens/store_mode/widgets/address_display.dart';
import 'package:mooze_mobile/screens/store_mode/widgets/amount_input.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class ReceivePixStoreScreen extends ConsumerStatefulWidget {
  const ReceivePixStoreScreen({Key? key}) : super(key: key);

  @override
  ReceivePixStoreState createState() => ReceivePixStoreState();
}

class ReceivePixStoreState extends ConsumerState<ReceivePixStoreScreen> {
  // depix as default asset
  Asset selectedAsset = AssetCatalog.getById("depix")!;
  late Future<String?> _addressFuture;
  // Controller for the BRL amount input
  final TextEditingController amountController = TextEditingController();
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
    _addressFuture =
        ref.read(liquidWalletNotifierProvider.notifier).generateAddress();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  // Handle text changes directly
  void _handleTextChanged(String text) {
    final newAmount = text.isEmpty ? 0 : int.tryParse(text) ?? 0;

    if (newAmount != _currentAmount) {
      setState(() {
        _currentAmount = newAmount;
      });
    }
  }

  void _onAssetChanged(Asset? asset) {
    setState(() {
      if (asset != null) {
        selectedAsset = asset;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final liquidWalletState = ref.watch(
      liquidWalletNotifierProvider,
    ); // Back to ref.watch

    final liquidAssets = AssetCatalog.liquidAssets;

    return Scaffold(
      appBar: MoozeAppBar(title: "Receber por PIX"),
      body: liquidWalletState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text("Erro ao instanciar carteira: $err")),
        data:
            (_) => FutureBuilder<String?>(
              future: _addressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao gerar endereço: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text("Nenhum endereço disponível"),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      PixInputAmount(
                        amountController: amountController,
                        onChanged: _handleTextChanged,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AddressDisplay(
                          address: snapshot.data!,
                          fiatAmount: _currentAmount,
                          asset: selectedAsset,
                        ),
                      ),
                      if (MediaQuery.of(context).viewInsets.bottom == 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 70),
                          child: SwipeToConfirm(
                            onConfirm: () {
                              if (selectedAsset == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Por favor, selecione um ativo.",
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_currentAmount < 0 || _currentAmount > 5000) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Por favor, insira um valor válido.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final pixTransaction = PixTransaction(
                                address: snapshot.data!,
                                brlAmount: _currentAmount,
                                asset:
                                    selectedAsset.liquidAssetId ??
                                    "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => GeneratePixPaymentCodeScreen(
                                        pixTransaction: pixTransaction,
                                        assetId: selectedAsset.liquidAssetId!,
                                      ),
                                ),
                              );
                            },
                            text: "Deslize para pagar",
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            progressColor:
                                Theme.of(context).colorScheme.secondary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            width: 300,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
