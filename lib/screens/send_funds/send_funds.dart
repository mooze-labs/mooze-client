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
  const SendFundsScreen({super.key});

  @override
  SendFundsScreenState createState() => SendFundsScreenState();
}

class SendFundsScreenState extends ConsumerState<SendFundsScreen> {
  OwnedAsset? selectedAsset;
  double? feeRate;
  int? fees;
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

  Future<void> _handleAmountChanged(double amount) async {
    assetAmountInSats =
        (amount * pow(10, selectedAsset!.asset.precision)).toInt();

    setState(() {
      if (selectedAsset == null) return;
      this.assetAmountInSats = assetAmountInSats;
    });
  }

  Future<int?> _calculateFeeAmount(String address) async {
    if (selectedAsset == null) {
      return null;
    }

    if (address.isEmpty) {
      return null;
    }

    if (this.feeRate == null) {
      return null;
    }

    final wallet = ref.watch(
      walletRepositoryProvider(selectedAsset!.asset.network),
    );
    final feeRate =
        (selectedAsset!.asset.network == Network.liquid) ? 1.0 : this.feeRate;

    if (selectedAsset!.asset.network == Network.bitcoin) {
      final psbt = await wallet.buildPartiallySignedTransaction(
        selectedAsset!,
        address,
        1,
        null,
      );

      setState(() {
        fees = 250;
      });

      return 250;
    }

    final psbt = await wallet.buildPartiallySignedTransaction(
      selectedAsset!,
      address,
      1,
      (selectedAsset!.asset.network == Network.liquid) ? feeRate : null,
    );

    setState(() {
      fees = psbt.feeAmount;
    });

    if (kDebugMode) {
      print("Recipient: ${psbt.recipient}");
      print("Fee amount: $fees");
    }

    return psbt.feeAmount;
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
          debugPrint("Fee rate updated to $feeRate");
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(
          "[WARN] Failed to fetch network fees. Fallbacking to default. Error: $e",
        );
      }
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

  void _handleContinue() async {
    if (kDebugMode) {
      print("Parsed amount in sats: $assetAmountInSats");
    }

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

    if (fees == null && selectedAsset!.asset.network == Network.liquid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao calcular taxas de rede.")),
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

      final fees =
          (selectedAsset!.asset.network == Network.bitcoin) ? 250 : this.fees;
      if (assetAmountInSats! + fees! > selectedAsset!.amount) {
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

  @override
  Widget build(BuildContext context) {
    final ownedAssetsState = ref.watch(ownedAssetsNotifierProvider);
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: MoozeAppBar(title: "Enviar ativos"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AddressInput(
                    controller: addressController,
                    onAddressChanged: (address) {
                      _calculateFeeAmount(address);
                    },
                  ),
                  SizedBox(height: 10),
                  AmountInput(
                    controller: amountController,
                    asset:
                        (selectedAsset != null)
                            ? selectedAsset!.asset
                            : AssetCatalog.bitcoin!,
                    onAmountChanged: (amount) async {
                      await _handleAmountChanged(amount);
                    },
                    fees:
                        (selectedAsset != null &&
                                (selectedAsset!.asset.network ==
                                    Network.bitcoin))
                            ? 250
                            : fees,
                    maxAmount: selectedAsset?.amount,
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
                  (fees != null &&
                          selectedAsset!.asset.network == Network.liquid)
                      ? Text("Taxas totais: ${fees} sats")
                      : (selectedAsset != null &&
                          selectedAsset!.asset.network == Network.bitcoin)
                      ? Text("Taxas totais: 250 sats")
                      : Text(""),
                ],
              ),
            ),
            if (!isKeyboardOpen)
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
