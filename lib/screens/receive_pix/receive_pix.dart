import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart' as liquid;
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/payments.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/generate_pix_payment_code/generate_pix_payment_code.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/address_display.dart';
import 'package:mooze_mobile/screens/receive_pix/widgets/amount_input.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({Key? key}) : super(key: key);

  @override
  ReceivePixState createState() => ReceivePixState();
}

class ReceivePixState extends ConsumerState<ReceivePixScreen> {
  // depix as default asset
  Asset selectedAsset = AssetCatalog.getById("depix")!;

  // Controller for the BRL amount input
  final TextEditingController amountController = TextEditingController();
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
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

  Widget _assetDropdown(BuildContext context, List<Asset> assets) {
    return DropdownMenu<Asset>(
      initialSelection: assets.firstWhere(
        (asset) => asset.id == selectedAsset.id,
        orElse: () => assets[0],
      ),
      onSelected: _onAssetChanged,
      dropdownMenuEntries:
          assets.map((Asset asset) {
            return DropdownMenuEntry<Asset>(
              value: asset,
              label: asset.name,
              leadingIcon: Image.asset(asset.logoPath, width: 24, height: 24),
            );
          }).toList(),
      label: const Text("Selecione um ativo"),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
      menuStyle: Theme.of(context).dropdownMenuTheme.menuStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final liquidAddress = ref.watch(liquidWalletNotifierProvider);
    final liquidAssets = AssetCatalog.liquidAssets;

    return Scaffold(
      appBar: MoozeAppBar(title: "Receber por PIX"),
      body: liquidAddress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text("Erro ao instanciar carteira: ${err}")),
        data: (wallet) {
          return FutureBuilder<liquid.Address>(
            future: wallet.addressLastUnused(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return Center(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    if (liquidAssets.isNotEmpty)
                      _assetDropdown(context, liquidAssets),
                    Expanded(
                      child: Column(
                        children: [
                          // Pass the onChanged callback
                          PixInputAmount(
                            amountController: amountController,
                            onChanged: _handleTextChanged,
                          ),

                          // Use the local state to force rebuilds
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AddressDisplay(
                              address: snapshot.data!.confidential,
                              fiatAmount: _currentAmount,
                              asset: selectedAsset,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: SwipeToConfirm(
                        onConfirm: () {
                          if (selectedAsset == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Por favor, selecione um ativo."),
                              ),
                            );
                          }

                          if (_currentAmount < 0 || _currentAmount > 5000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Por favor, insira um valor válido.",
                                ),
                              ),
                            );
                          }

                          final PixTransaction pixTransaction = PixTransaction(
                            address: snapshot.data!.confidential,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        progressColor: Theme.of(context).colorScheme.secondary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        width: 300,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
