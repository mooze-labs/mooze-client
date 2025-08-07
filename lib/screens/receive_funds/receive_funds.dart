import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
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
  Asset? selectedAsset;
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
    if (selectedAsset == null) return;
    setState(() {
      isLoadingAddress = true;
      currentAddress = null;
    });

    final walletRepository = ref.read(
      walletRepositoryProvider(selectedAsset!.network),
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
    return Center(
      child: DropdownMenu<Asset>(
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
        textAlign: TextAlign.center,
        leadingIcon:
            (selectedAsset != null)
                ? Transform.scale(
                  scale: 0.5,
                  child: Image.asset(
                    selectedAsset!.logoPath,
                    width: 24,
                    height: 24,
                  ),
                )
                : null,
      ),
    );
  }

  void onAmountChanged(double newAmount) {
    setState(() {
      amount = newAmount;
    });
  }

  String? generatePaymentUri(String address, double? amount) {
    if (selectedAsset == null) return null;
    if (selectedAsset!.network == Network.bitcoin) {
      if (amount == null || amount <= 0) return "bitcoin:$address";
      return "bitcoin:$address?amount=${amount.toStringAsFixed(selectedAsset!.precision)}";
    }
    // amount on liquid can only be defined if asset is defined
    if (selectedAsset!.liquidAssetId == null) return "liquidnetwork:$address";
    if (amount == null || amount <= 0) {
      return "liquidnetwork:$address?asset_id=${selectedAsset!.liquidAssetId}";
    }
    return "liquidnetwork:$address?amount=${amount.toStringAsFixed(selectedAsset!.precision)}&assetid=${selectedAsset!.liquidAssetId}";
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
            Spacer(),
            if (selectedAsset != null)
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
                            data:
                                generatePaymentUri(currentAddress!, amount) ??
                                "",
                            asset: selectedAsset!,
                            qrSize: qrBoundedSize,
                          ),
                ),
              ),
            Spacer(),
            if (selectedAsset != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent),
                ),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: currentAddress ?? ""),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Endereço copiado!"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: SelectableText(
                          (currentAddress != null)
                              ? "${currentAddress!.substring(0, 4)} ${currentAddress!.substring(4, 8)} ${currentAddress!.substring(8, 12)} ... ${currentAddress!.substring(currentAddress!.length - 12, currentAddress!.length - 8)} ${currentAddress!.substring(currentAddress!.length - 8, currentAddress!.length - 4)} ${currentAddress!.substring(currentAddress!.length - 4)}"
                              : "",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontFamily: "roboto",
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 16),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (selectedAsset != null)
              AmountInput(
                controller: amountController,
                asset: selectedAsset!,
                onAmountChanged: onAmountChanged,
              ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
