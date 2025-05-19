// Based on Aqua Wallet implementation

import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/repositories/sideswap.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import '../providers/swap_input_provider.dart';

import 'package:stream_transform/stream_transform.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_max_amount_button.dart';

class SwapAssetRow extends StatelessWidget {
  final List<Asset> assets;
  final Asset selectedAsset;
  final TextEditingController amountController;
  final Function(Asset asset) onAssetChange;
  final Function(String amount)? onAmountChange;
  final VoidCallback? onEditingComplete;
  final bool readOnly;

  const SwapAssetRow({
    super.key,
    required this.assets,
    required this.selectedAsset,
    required this.amountController,
    required this.onAssetChange,
    this.onAmountChange,
    this.onEditingComplete,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.secondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: amountController,
              onChanged: onAmountChange,
              onEditingComplete:
                  onEditingComplete ??
                  (onAmountChange != null
                      ? () => onAmountChange!(amountController.text)
                      : null),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                hintText: "0",
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              readOnly: readOnly,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textInputAction: TextInputAction.done,
              onTapOutside: (PointerDownEvent event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              keyboardType:
                  (Platform.isIOS)
                      ? null
                      : TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
              inputFormatters: [
                // Allow numbers, a single comma or dot for the decimal
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
                // Custom formatter to ensure only one decimal separator exists
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Count how many decimal separators (comma or dot) are in the text
                  int commaCount = newValue.text.split(',').length - 1;
                  int dotCount = newValue.text.split('.').length - 1;

                  // If there's more than one total decimal separator, reject the edit
                  if (commaCount + dotCount > 1) {
                    return oldValue;
                  }
                  return newValue;
                }),
              ],
            ),
          ),
          Container(
            child: PopupMenuButton<Asset>(
              itemBuilder:
                  (context) =>
                      assets
                          .map(
                            (asset) => PopupMenuItem(
                              value: asset,
                              child: ListTile(
                                leading: Image.asset(
                                  asset.logoPath,
                                  width: 24,
                                  height: 24,
                                ),
                                title: Text(asset.ticker),
                              ),
                            ),
                          )
                          .toList(),
              onSelected: (Asset? asset) {
                if (asset != null) {
                  onAssetChange(asset);
                }
              },
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(selectedAsset.logoPath, width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text(selectedAsset.ticker),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SendAssetRow extends ConsumerStatefulWidget {
  final TextEditingController? amountController;

  const SendAssetRow({super.key, this.amountController});

  @override
  ConsumerState<SendAssetRow> createState() => _SendAssetRowState();
}

class _SendAssetRowState extends ConsumerState<SendAssetRow> {
  late final TextEditingController _internalController;
  StreamController<int> amountStreamController =
      StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    _internalController = widget.amountController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.amountController == null) {
      _internalController.dispose();
    }
    amountStreamController.close();
    super.dispose();
  }

  void _onEditingComplete() {
    if (!mounted) return;
    final value = _internalController.text;
    final amount = double.tryParse(value.replaceAll(",", ".")) ?? 0;
    final parsedAmount = (amount * pow(10, 8)).toInt();
    if (kDebugMode) {
      print("amount: $amount");
      print("parsedAmount: $parsedAmount");
    }
    ref
        .read(swapInputNotifierProvider.notifier)
        .changeSendAssetSatoshiAmount(parsedAmount);

    if (parsedAmount == 0) {
      ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final sendAsset = swapInput.sendAsset;
    List<Asset> assets;
    if (swapInput.recvAsset == AssetCatalog.getById("btc")) {
      assets = [AssetCatalog.getById("lbtc")!];
    } else {
      assets =
          AssetCatalog.all
              .where((asset) => asset.id != swapInput.recvAsset.id)
              .toList();
    }

    // Clear the controller when amount is 0
    if (swapInput.sendAssetSatoshiAmount == 0 &&
        _internalController.text.isNotEmpty) {
      _internalController.clear();
    }

    return SwapAssetRow(
      assets: assets,
      selectedAsset: sendAsset,
      amountController: _internalController,
      onAssetChange: (asset) {
        ref.read(swapInputNotifierProvider.notifier).changeSendAsset(asset);
        if (asset == AssetCatalog.bitcoin) {
          ref
              .read(swapInputNotifierProvider.notifier)
              .changeRecvAsset(AssetCatalog.getById("lbtc")!);
        }
      },
      onAmountChange: null,
      onEditingComplete: _onEditingComplete,
      readOnly: false,
    );
  }
}

class ReceiveAssetRow extends ConsumerStatefulWidget {
  const ReceiveAssetRow({super.key});

  @override
  ConsumerState<ReceiveAssetRow> createState() => _ReceiveAssetRowState();
}

class _ReceiveAssetRowState extends ConsumerState<ReceiveAssetRow> {
  late final TextEditingController amountController;
  StreamSubscription<QuoteResponse>? _quoteSubscription;

  @override
  void initState() {
    super.initState();
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    sideswapClient.ensureConnection();
    amountController = TextEditingController();

    // Subscribe to the quote response stream
    _quoteSubscription = sideswapClient.quoteResponseStream.listen((
      quoteResponse,
    ) {
      if (!mounted) return;
      final swapInput = ref.read(swapInputNotifierProvider);
      if (quoteResponse.isSuccess && quoteResponse.quote != null) {
        final isSendAssetQuoteAmount =
            swapInput.sendAssetSatoshiAmount ==
            quoteResponse.quote!.quoteAmount;
        // Convert satoshis to BTC/LBTC
        final amount =
            isSendAssetQuoteAmount
                ? quoteResponse.quote!.baseAmount / pow(10, 8)
                : quoteResponse.quote!.quoteAmount / pow(10, 8);
        amountController.text = amount.toStringAsFixed(8);
      }
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final recvAsset = swapInput.recvAsset;
    List<Asset> assets;
    if (swapInput.sendAsset == AssetCatalog.bitcoin) {
      assets = [AssetCatalog.getById("lbtc")!];
    } else if (swapInput.sendAsset == AssetCatalog.getById("lbtc")) {
      assets = [
        AssetCatalog.bitcoin!,
        AssetCatalog.getById("usdt")!,
        AssetCatalog.getById("depix")!,
      ];
    } else {
      assets =
          AssetCatalog.all
              .where(
                (asset) =>
                    asset.id != swapInput.sendAsset.id &&
                    asset != AssetCatalog.bitcoin,
              )
              .toList();
    }

    // Clear the controller when amount is 0
    if (swapInput.sendAssetSatoshiAmount == 0 &&
        amountController.text.isNotEmpty) {
      amountController.clear();
    }

    final formattedAmount = (swapInput.sendAssetSatoshiAmount == 0
            ? swapInput.recvAssetSatoshiAmount / pow(10, 8)
            : 0)
        .toStringAsFixed(8);

    if (swapInput.sendAsset == AssetCatalog.bitcoin ||
        swapInput.recvAsset == AssetCatalog.bitcoin) {
      amountController.text = ((swapInput.sendAssetSatoshiAmount * 0.99) /
              pow(10, 8))
          .toStringAsFixed(8);
    } else {
      amountController.text = formattedAmount;
    }

    return SwapAssetRow(
      assets: assets,
      selectedAsset: recvAsset,
      amountController: amountController,
      onAssetChange: (asset) {
        ref.read(swapInputNotifierProvider.notifier).changeRecvAsset(asset);
        if (asset == AssetCatalog.bitcoin) {
          ref
              .read(swapInputNotifierProvider.notifier)
              .changeSendAsset(AssetCatalog.getById("lbtc")!);
        }
      },
      onAmountChange: (_) {}, // no-op since it's readOnly
      onEditingComplete: null,
      readOnly: true,
    );
  }
}
