import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/text_button.dart';

class SwapFromCard extends ConsumerStatefulWidget {
  final core.Asset selectedAsset;
  final List<core.Asset> availableAssets;
  final TextEditingController amountController;
  final TextEditingController decimalController;
  final ValueChanged<core.Asset> onAssetChanged;
  final VoidCallback onAmountChanged;
  final VoidCallback onMaxPressed;
  final bool isSyncing;
  final Function(bool) onSyncingChanged;

  const SwapFromCard({
    super.key,
    required this.selectedAsset,
    required this.availableAssets,
    required this.amountController,
    required this.decimalController,
    required this.onAssetChanged,
    required this.onAmountChanged,
    required this.onMaxPressed,
    required this.isSyncing,
    required this.onSyncingChanged,
  });

  @override
  ConsumerState<SwapFromCard> createState() => _SwapFromCardState();
}

class _SwapFromCardState extends ConsumerState<SwapFromCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDecimalController();
    });
  }

  @override
  void didUpdateWidget(SwapFromCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAsset != widget.selectedAsset ||
        oldWidget.amountController.text != widget.amountController.text) {
      _syncDecimalController();
    }
  }

  void _syncDecimalController() {
    if (widget.isSyncing) return;
    widget.onSyncingChanged(true);

    final text = widget.amountController.text.trim();
    if (text.isEmpty) {
      widget.decimalController.text = '';
    } else {
      final amount = BigInt.tryParse(text) ?? BigInt.zero;
      final isBtcOrLbtc =
          widget.selectedAsset == core.Asset.btc ||
          widget.selectedAsset == core.Asset.lbtc;
      final decimals = isBtcOrLbtc ? 8 : 2;
      widget.decimalController.text = (amount.toDouble() / 100000000)
          .toStringAsFixed(decimals);
    }

    widget.onSyncingChanged(false);
  }

  Future<String> _getBalance() async {
    final either = await ref.read(balanceProvider(widget.selectedAsset).future);
    return either.match(
      (l) => '0',
      (r) => widget.selectedAsset.formatBalance(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.read(currencyControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColors.backgroundColor,
      ),
      height: 115,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Você envia', style: Theme.of(context).textTheme.labelLarge),
              Row(
                children: [
                  FutureBuilder<String>(
                    future: _getBalance(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? "...",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  TransparentTextButton(
                    text: 'MAX',
                    onPressed: widget.onMaxPressed,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              SvgPicture.asset(
                widget.selectedAsset.iconPath,
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<core.Asset>(
                      value: widget.selectedAsset,
                      underline: const SizedBox.shrink(),
                      icon: SvgPicture.asset(
                        'assets/icons/menu/arrow_down.svg',
                      ),
                      onChanged: (core.Asset? newAsset) {
                        if (newAsset != null) {
                          widget.onAssetChanged(newAsset);
                        }
                      },
                      items:
                          widget.availableAssets.map<
                            DropdownMenuItem<core.Asset>
                          >((core.Asset asset) {
                            return DropdownMenuItem<core.Asset>(
                              value: asset,
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    asset.iconPath,
                                    width: 15,
                                    height: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    asset.ticker,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return widget.availableAssets.map<Widget>((
                          core.Asset asset,
                        ) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                asset.ticker,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(width: 5),
                            ],
                          );
                        }).toList();
                      },
                    ),

                    Expanded(
                      child: TextField(
                        controller: widget.decimalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: true,
                          hintText: '0',
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                        onChanged: (value) {
                          final parsed =
                              double.tryParse(value.replaceAll(',', '.')) ?? 0;
                          final sats = BigInt.from(
                            (parsed * 100000000).round(),
                          );
                          if (widget.amountController.text != sats.toString()) {
                            widget.amountController.text = sats.toString();
                            widget.onAmountChanged();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.selectedAsset.name),
              FutureBuilder<Either<String, double>>(
                future: ref.read(
                  fiatPriceProvider(widget.selectedAsset).future,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!.fold((error) => const Text('0.00'), (
                      price,
                    ) {
                      final amount =
                          BigInt.tryParse(
                            widget.amountController.text.trim(),
                          ) ??
                          BigInt.zero;
                      final usd = widget.selectedAsset.toUsd(amount, price);
                      return Text('${currency.icon}${usd.toStringAsFixed(2)}');
                    });
                  }
                  return const Text('...');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
