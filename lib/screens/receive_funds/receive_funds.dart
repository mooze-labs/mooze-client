import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/wallet/network_wallet_repository_provider.dart';
import 'package:mooze_mobile/screens/receive_funds/widgets/qr_code_display.dart';
import 'package:mooze_mobile/widgets/inputs/amount_input.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class ReceiveFundsScreen extends ConsumerStatefulWidget {
  const ReceiveFundsScreen({super.key});

  @override
  ReceiveFundsScreenState createState() => ReceiveFundsScreenState();
}

class ReceiveFundsScreenState extends ConsumerState<ReceiveFundsScreen> {
  final TextEditingController amountController = TextEditingController();
  Asset selectedAsset = AssetCatalog.bitcoin!;
  double? amount;
  String? currentAddress;
  bool isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    // Generate address for initial asset
    generateNewAddress();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> generateNewAddress() async {
    setState(() {
      isLoadingAddress = true;
      currentAddress = null;
    });

    final walletRepository = ref.read(
      walletRepositoryProvider(selectedAsset.network),
    );

    try {
      final address = await walletRepository.generateAddress();
      setState(() {
        currentAddress = address;
        isLoadingAddress = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAddress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível gerar um endereço de pagamento."),
          ),
        );
      }
    }
  }

  Widget _assetDropdown(BuildContext context) {
    return DropdownMenu<Asset>(
      initialSelection: AssetCatalog.all[0],
      onSelected: (Asset? asset) {
        if (asset != null && asset != selectedAsset) {
          setState(() {
            selectedAsset = asset;
            // Clear amount when asset changes
            amountController.clear();
            amount = null;
          });
          // Generate new address only when asset changes
          generateNewAddress();
        }
      },
      dropdownMenuEntries:
          AssetCatalog.all.map((Asset asset) {
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

  void onAmountChanged(double newAmount) {
    setState(() {
      amount = newAmount;
    });
  }

  String generatePaymentUri(String address, double? amount) {
    if (selectedAsset.network == Network.bitcoin) {
      if (amount == null || amount <= 0) return "bitcoin:$address";
      return "bitcoin:$address?amount=${amount.toStringAsFixed(selectedAsset.precision)}";
    }
    // amount on liquid can only be defined if asset is defined
    if (selectedAsset.liquidAssetId == null) return "liquidnetwork:$address";
    if (amount == null || amount <= 0) {
      return "liquidnetwork:$address?asset_id=${selectedAsset.liquidAssetId}";
    }
    return "liquidnetwork:$address?asset_id=${selectedAsset.liquidAssetId}&amount=${amount.toStringAsFixed(selectedAsset.precision)}";
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final availableContentHeight =
        screenHeight - keyboardHeight - kToolbarHeight - 150;
    final smallerDimension =
        availableHeight < screenWidth ? availableContentHeight : screenWidth;

    final qrSize =
        keyboardHeight > 0 ? smallerDimension * 0.40 : smallerDimension * 0.70;

    final qrBoundedSize = qrSize.clamp(150.0, 350.0);

    return Scaffold(
      appBar: MoozeAppBar(title: "Receber ativos"),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              _assetDropdown(context),
            const SizedBox(height: 10),
            SizedBox(
              child: Center(
                child:
                    isLoadingAddress
                        ? const Center(child: CircularProgressIndicator())
                        : currentAddress == null
                        ? const Center(
                          child: Text("Não foi possível gerar um endereço"),
                        )
                        : QRCodeWidget(
                          data: generatePaymentUri(currentAddress!, amount),
                          asset: selectedAsset,
                          qrSize: qrBoundedSize,
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
              ),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: currentAddress ?? ""));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Endereço copiado!"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SelectableText(
                        currentAddress ?? "",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontFamily: "roboto",
                          fontSize: 16,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            AmountInput(
              controller: amountController,
              asset: selectedAsset,
              onAmountChanged: onAmountChanged,
            ),
          ],
        ),
      ),
    );
  }
}
