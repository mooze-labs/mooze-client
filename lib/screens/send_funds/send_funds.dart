import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart' as lwk;
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/external/mempool_repository_provider.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'dart:math';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_wallet_repository_provider.dart';
import 'package:mooze_mobile/screens/confirm_send_transaction/confirm_send_transaction.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/available_funds.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/inputs.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/widgets/inputs/amount_input.dart';
import 'package:mooze_mobile/widgets/inputs/convertible_amount_input.dart';

class SendFundsScreen extends ConsumerStatefulWidget {
  const SendFundsScreen({Key? key}) : super(key: key);

  @override
  SendFundsScreenState createState() => SendFundsScreenState();
}

class SendFundsScreenState extends ConsumerState<SendFundsScreen> {
  OwnedAsset? selectedAsset;
  double? feeRate;
  int? assetAmountInSats;
  bool isFiatMode = false;
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    addressController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _handleAmountChanged(double amount) {
    setState(() {
      if (selectedAsset == null) return;
      assetAmountInSats =
          (amount * pow(10, selectedAsset!.asset.precision)).toInt();
    });
  }

  int _calculateFeeAmount(double feeRate, int recipients, int outputs) {
    const fixedWeight = 44;
    const singlesigVinWeight = 367;
    const voutWeight = 4810;
    const feeWeight = 178;

    final int txSize =
        fixedWeight +
        singlesigVinWeight * recipients +
        voutWeight * outputs +
        feeWeight;

    final vsize = (txSize + 3) / 4;
    return (vsize * feeRate).ceil();
  }

  Future<void> _updateNetworkFees() async {
    if (selectedAsset == null) {
      setState(() {
        feeRate = null;
      });
      return;
    }

    try {
      final mempoolRepository = ref.watch(
        mempoolRepositoryProvider(selectedAsset!.asset.network),
      );
      final recommendedFees = await mempoolRepository.getRecommendedFees();
      setState(() {
        feeRate = recommendedFees.halfHourFee.toDouble();
        if (kDebugMode) {
          debugPrint("Fee rate updated to ${feeRate}");
        }
      });
    } catch (e) {
      print(
        "[WARN] Failed to fetch network fees. Fallbacking to default. Error: $e",
      );
      setState(() {
        feeRate = 2.0;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNetworkFees();
  }

  void _handleContinue() {
    print("Parsed amount in sats: $assetAmountInSats");
    if (selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecione um ativo primeiro."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Digite um valor para enviar."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Digite um endereço."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      // Check if assetAmountInSats was properly set by the _handleAmountChanged callback
      if (assetAmountInSats == null || assetAmountInSats! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("O valor deve ser maior que zero."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final totalFees =
          (feeRate != null) ? _calculateFeeAmount(feeRate!, 1, 2) : 100;

      // Compare the amount in sats directly with the available balance in sats
      if (assetAmountInSats! > selectedAsset!.amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Saldo insuficiente. O valor inserido excede o saldo disponível.",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (assetAmountInSats! + 26 > selectedAsset!.amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "O valor inserido excede o saldo disponível + taxas de rede.",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConfirmSendTransactionScreen(
                ownedAsset: selectedAsset!,
                address: addressController.text,
                amount: assetAmountInSats!,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Ocorreu um erro ao processar a transação. Tente novamente.",
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _assetDropdown(BuildContext context, List<OwnedAsset> assets) {
    return DropdownMenu<OwnedAsset>(
      onSelected: (OwnedAsset? asset) {
        setState(() {
          selectedAsset = asset;
          _updateNetworkFees();
        });
      },
      dropdownMenuEntries:
          assets.map((OwnedAsset asset) {
            return DropdownMenuEntry<OwnedAsset>(
              value: asset,
              label: asset.asset.name,
              leadingIcon: Image.asset(
                asset.asset.logoPath,
                width: 24,
                height: 24,
              ),
            );
          }).toList(),
      label: const Text("Selecione um ativo"),
      inputDecorationTheme:
          Theme.of(context).dropdownMenuTheme.inputDecorationTheme,
      menuStyle: Theme.of(context).dropdownMenuTheme.menuStyle,
      leadingIcon:
          (selectedAsset != null)
              ? Transform.scale(
                scale: 0.5,
                child: Image.asset(
                  selectedAsset!.asset.logoPath,
                  width: 24,
                  height: 24,
                ),
              )
              : null,
    );
  }

  Widget _amountInput() {
    final fiatPrices = ref.watch(fiatPricesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);

    if (selectedAsset == null) {
      return Container();
    }

    return fiatPrices.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) {
        return ConvertibleAmountInput(
          assetId: selectedAsset!.asset.id,
          assetTicker: selectedAsset!.asset.ticker,
          assetPrecision: selectedAsset!.asset.precision,
          fiatCurrency: baseCurrency,
          fiatPrice: 0.0,
          controller: amountController,
        );
      },
      data: (prices) {
        final price = prices[selectedAsset!.asset.fiatPriceId];
        return ConvertibleAmountInput(
          assetId: selectedAsset!.asset.id,
          assetTicker: selectedAsset!.asset.ticker,
          assetPrecision: selectedAsset!.asset.precision,
          fiatCurrency: baseCurrency,
          fiatPrice: price ?? 0.0,
          controller: amountController,
          onAmountChanged: _handleAmountChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownedAssetsState = ref.watch(ownedAssetsNotifierProvider);
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: MoozeAppBar(title: "Enviar ativos"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: ownedAssetsState.when(
                data: (ownedAssets) => _assetDropdown(context, ownedAssets),
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text("Erro: $err"),
              ),
            ),
            SizedBox(height: 20),
            if (selectedAsset != null)
              AvailableFunds(ownedAsset: selectedAsset),
            // Expanded widget to center the TextFields
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AddressInput(controller: addressController),
                  SizedBox(height: 10),
                  AmountInput(
                    controller: amountController,
                    asset:
                        (selectedAsset != null)
                            ? selectedAsset!.asset
                            : AssetCatalog.bitcoin!,
                    onAmountChanged: _handleAmountChanged,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child:
                        feeRate == null
                            ? Text(
                              "",
                              style: TextStyle(
                                fontFamily: "roboto",
                                fontSize: 14,
                              ),
                            )
                            : Text(
                              "Taxas de rede: $feeRate sats/vB",
                              style: TextStyle(
                                fontFamily: "roboto",
                                fontSize: 14,
                              ),
                            ),
                  ),
                  /*
                  if (feeRate != null)
                    Text(
                      "Taxas totais: ${_calculateFeeAmount(feeRate!, 1, 2)} sats",
                    ),
                  */
                ],
              ),
            ),
            if (MediaQuery.of(context).viewInsets.bottom == 0) // check keyboard
              Padding(
                padding: EdgeInsets.only(bottom: 100),
                child: PrimaryButton(
                  text: "Revisar transação",
                  onPressed: _handleContinue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
