import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/peg_operation_provider.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:mooze_mobile/repositories/wallet/bitcoin.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_details_display.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_peg_warn.dart';
import 'package:mooze_mobile/screens/swap/check_peg_status.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class FinishPegScreen extends ConsumerStatefulWidget {
  final Asset sendAsset;
  final int sendAmount;

  const FinishPegScreen({
    super.key,
    required this.sendAsset,
    required this.sendAmount,
  });
  @override
  ConsumerState<FinishPegScreen> createState() => _FinishPegScreenState();
}

class _FinishPegScreenState extends ConsumerState<FinishPegScreen> {
  bool _withdrawToExternalWallet = false;
  final TextEditingController _addressController = TextEditingController();
  dynamic _pegResponse;
  dynamic _pst;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePegData();
  }

  Future<double> _getFeeRate() async {
    final swapInput = ref.read(swapInputNotifierProvider);

    if (swapInput.sendAsset == AssetCatalog.bitcoin) {
      final wallet =
          ref.read(bitcoinWalletRepositoryProvider) as BitcoinWalletRepository;
      final blockchain = wallet.blockchain;
      final estimatedFee = await blockchain?.estimateFee(
        target: BigInt.from(2),
      );

      return estimatedFee?.satPerVb ?? 2.0;
    }
    return 1.0;
  }

  Future<void> _initializePegData() async {
    try {
      final sideswapClient = ref.read(sideswapRepositoryProvider);
      final swapInput = ref.read(swapInputNotifierProvider);

      final ownedAssetsFuture = ref.read(ownedAssetsNotifierProvider.future);
      final networkFeesFuture = ref.read(networkFeeProviderProvider.future);

      final (ownedAssets, networkFees) =
          await (ownedAssetsFuture, networkFeesFuture).wait;

      final fees =
          (swapInput.sendAsset == AssetCatalog.bitcoin)
              ? networkFees.bitcoinFast
              : networkFees.liquid;

      final sendAmount = widget.sendAmount - fees.absoluteFees - 1;

      if (kDebugMode) {
        debugPrint("Widget send amount: ${widget.sendAmount}");
        debugPrint("Fees: ${fees.absoluteFees}");
        debugPrint("Send amount: $sendAmount");
      }

      final sendWallet =
          (swapInput.sendAsset == AssetCatalog.bitcoin)
              ? ref.read(bitcoinWalletRepositoryProvider)
              : ref.read(liquidWalletRepositoryProvider);
      final recvWallet =
          (swapInput.sendAsset == AssetCatalog.bitcoin)
              ? ref.read(liquidWalletRepositoryProvider)
              : ref.read(bitcoinWalletRepositoryProvider);

      final recvInternalAddress = await recvWallet.generateAddress();
      final pegIn = swapInput.sendAsset == AssetCatalog.bitcoin;
      final receiveAddress =
          (_withdrawToExternalWallet)
              ? _addressController.text
              : recvInternalAddress;

      sideswapClient.ensureConnection();

      final pegResponse = await sideswapClient.startPegOperation(
        pegIn,
        receiveAddress,
      );

      if (kDebugMode) {
        debugPrint("Received Peg response.");
        debugPrint("Order id: ${pegResponse?.orderId}");
        debugPrint("Sideswap payment address: ${pegResponse?.pegAddress}");
        debugPrint("Address to receive: $receiveAddress");
      }

      final feeRate = await _getFeeRate();

      if (kDebugMode) {
        print("Send asset ID: ${swapInput.sendAsset.id}");
        print("Send amount: $sendAmount");
        print("Fees: ${fees.absoluteFees}");
      }

      if (pegResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Erro ao contatar Sideswap. Tente novamente mais tarde.",
              ),
            ),
          );
        }
        return;
      }

      PartiallySignedTransaction pst;
      if (swapInput.sendAsset == AssetCatalog.bitcoin) {
        final bitcoinWallet = sendWallet as BitcoinWalletRepository;
        pst = await bitcoinWallet
            .buildPartiallySignedTransactionWithAbsoluteFees(
              ownedAssets.firstWhere(
                (asset) => asset.asset == swapInput.sendAsset,
              ),
              pegResponse.pegAddress,
              sendAmount,
              fees.absoluteFees,
            );
      } else {
        pst = await sendWallet.buildPartiallySignedTransaction(
          ownedAssets.firstWhere((asset) => asset.asset == swapInput.sendAsset),
          pegResponse.pegAddress,
          sendAmount - 1,
          feeRate,
        );
      }

      setState(() {
        _pegResponse = pegResponse;
        _pst = pst;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao inicializar dados: $e")),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onConfirmPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final swapInput = ref.read(swapInputNotifierProvider);
      final pegIn = swapInput.sendAsset == AssetCatalog.bitcoin;
      final sideswapClient = ref.read(sideswapRepositoryProvider);
      final ownedAssets = await ref.read(ownedAssetsNotifierProvider.future);
      final networkFees = await ref.read(networkFeeProviderProvider.future);

      final sendWallet =
          (swapInput.sendAsset == AssetCatalog.bitcoin)
              ? ref.read(bitcoinWalletRepositoryProvider)
              : ref.read(liquidWalletRepositoryProvider);

      dynamic pegResponseForConfirmation;
      dynamic pstForConfirmation;

      final fees =
          (swapInput.sendAsset == AssetCatalog.bitcoin)
              ? networkFees.bitcoinFast
              : networkFees.liquid;
      final int sendAmountInTx = widget.sendAmount - fees.absoluteFees - 1;

      if (kDebugMode) {
        debugPrint("Confirming peg operation.");
        debugPrint(
          "Widget send amount (total from user): ${widget.sendAmount}",
        );
        debugPrint(
          "Calculated fees (for network/service): ${fees.absoluteFees}",
        );
        debugPrint("Amount to send in Sideswap tx: $sendAmountInTx");
      }

      if (sendAmountInTx <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Valor de envio inválido após taxas.")),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_withdrawToExternalWallet) {
        final String externalAddress = _addressController.text.trim();
        if (externalAddress.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Endereço externo não pode estar vazio.")),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        sideswapClient.ensureConnection();
        final newPegResponse = await sideswapClient.startPegOperation(
          pegIn,
          externalAddress,
        );

        pegResponseForConfirmation = newPegResponse;

        if (kDebugMode) {
          debugPrint("External Peg initiated:");
          debugPrint("Order id: ${pegResponseForConfirmation?.orderId}");
          debugPrint(
            "Sideswap payment address: ${pegResponseForConfirmation?.pegAddress}",
          );
          debugPrint("Address to receive (external): $externalAddress");
        }

        final feeRate = await _getFeeRate();
        if (swapInput.sendAsset == AssetCatalog.bitcoin) {
          final bitcoinWallet = sendWallet as BitcoinWalletRepository;
          pstForConfirmation = await bitcoinWallet
              .buildPartiallySignedTransactionWithAbsoluteFees(
                ownedAssets.firstWhere(
                  (asset) => asset.asset == swapInput.sendAsset,
                ),
                pegResponseForConfirmation.pegAddress,
                sendAmountInTx,
                fees.absoluteFees,
              );
        } else {
          pstForConfirmation = await sendWallet.buildPartiallySignedTransaction(
            ownedAssets.firstWhere(
              (asset) => asset.asset == swapInput.sendAsset,
            ),
            pegResponseForConfirmation.pegAddress,
            sendAmountInTx,
            feeRate,
          );
        }
      } else {
        pegResponseForConfirmation = _pegResponse;
        pstForConfirmation = _pst;

        if (pegResponseForConfirmation == null || pstForConfirmation == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Dados de transação não disponíveis (interno). Tente novamente.",
                ),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
        if (kDebugMode) {
          debugPrint("Internal Peg (using pre-initialized data):");
          debugPrint("Order id: ${pegResponseForConfirmation?.orderId}");
          debugPrint(
            "Sideswap payment address: ${pegResponseForConfirmation?.pegAddress}",
          );
        }
      }

      await ref
          .read(activePegOperationProvider.notifier)
          .startPegOperation(pegResponseForConfirmation.orderId, pegIn);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => VerifyPinScreen(
                  onPinConfirmed: () async {
                    final tx = await sendWallet.signTransaction(
                      pstForConfirmation,
                    );
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CheckPegStatusScreen(
                                pegIn: pegIn,
                                orderId: pegResponseForConfirmation.orderId,
                              ),
                        ),
                      );
                    }
                  },
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao confirmar peg: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);

    return Scaffold(
      appBar: MoozeAppBar(title: "Confirmar peg"),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Spacer(),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(child: PegDetailsDisplay()),
                            const SizedBox(height: 16),
                            FittedBox(child: PegFeesDisplay()),
                            const SizedBox(height: 16),
                            if (swapInput.sendAsset != AssetCatalog.bitcoin)
                              Row(
                                children: [
                                  Checkbox(
                                    value: _withdrawToExternalWallet,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _withdrawToExternalWallet =
                                            value ?? false;
                                        if (!_withdrawToExternalWallet) {
                                          _addressController.clear();
                                        }
                                      });
                                    },
                                  ),
                                  const Text(
                                    "Sacar para carteira externa",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            if (_withdrawToExternalWallet) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  hintText: "Endereço Bitcoin",
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Spacer(),
                      SwapPegWarn(),
                      const SizedBox(height: 16),
                      if (_pegResponse != null)
                        SwipeToConfirm(
                          onConfirm: _onConfirmPressed,
                          text: "Confirmar",
                        ),
                      Spacer(),
                    ],
                  ),
                ),
              ),
    );
  }
}
