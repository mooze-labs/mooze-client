import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../../data/models.dart';
import '../providers/swap_controller.dart';
import '../widgets/confirm_swap_bottom_sheet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/text_button.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  final TextEditingController _fromAmountController = TextEditingController();
  core.Asset _fromAsset = core.Asset.lbtc;
  core.Asset _toAsset = core.Asset.usdt;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(swapControllerProvider.notifier).loadMetadata(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapState = ref.watch(swapControllerProvider);

    final quote = swapState.currentQuote?.quote;
    final isLoading = swapState.loading;
    final error = swapState.error;

    double? exchangeRate;
    if (quote != null && quote.baseAmount > 0) {
      exchangeRate = quote.quoteAmount / quote.baseAmount;
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Swap'),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.surfaceColor,
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _from(context),
              GestureDetector(
                onTap: () {
                  setState(() {
                    final tmp = _fromAsset;
                    _fromAsset = _toAsset;
                    _toAsset = tmp;
                  });
                  _requestQuoteDebounced();
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(child: _SwapIcon()),
                ),
              ),
              _to(context),
              const SizedBox(height: 15),
              if (isLoading)
                Shimmer.fromColors(
                  baseColor: AppColors.baseColor,
                  highlightColor: AppColors.highlightColor,
                  child: Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '1 ${_fromAsset.ticker} = ${_formatRate(exchangeRate)} ${_toAsset.ticker}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
              if (error != null) const SizedBox(height: 8),
              if (error != null)
                Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 15),
              const Center(child: Text('Powered by sideswap.io')),
              const SizedBox(height: 15),

              FutureBuilder<bool>(
                future: _hasInsufficientBalance(),
                builder: (context, snapshot) {
                  final hasInsufficientBalance = snapshot.data ?? false;

                  if (hasInsufficientBalance &&
                      _fromAmountController.text.isNotEmpty) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Saldo insuficiente para realizar o swap',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              FutureBuilder<bool>(
                future: _hasInsufficientBalance(),
                builder: (context, snapshot) {
                  final hasInsufficientBalance = snapshot.data ?? false;
                  final hasQuote = swapState.currentQuote?.quote != null;

                  return PrimaryButton(
                    text: 'swap',
                    isEnabled:
                        _fromAmountController.text.isNotEmpty &&
                        hasQuote &&
                        !isLoading &&
                        !hasInsufficientBalance,
                    onPressed:
                        (_fromAmountController.text.isNotEmpty &&
                                hasQuote &&
                                !isLoading &&
                                !hasInsufficientBalance)
                            ? () async {
                              ConfirmSwapBottomSheet.show(context);
                            }
                            : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FROM card
  Widget _from(BuildContext context) {
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
                    future: _getBalance(_fromAsset),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data ?? "..."}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  TransparentTextButton(
                    text: 'MAX',
                    onPressed: () async {
                      final balance = await _getBalanceRaw(_fromAsset);
                      _fromAmountController.text = balance.toString();
                      setState(() {});
                      _requestQuoteDebounced();
                    },
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
              SvgPicture.asset(_fromAsset.iconPath, width: 25, height: 25),
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<core.Asset>(
                      value: _fromAsset,
                      underline: const SizedBox.shrink(),
                      icon: SvgPicture.asset(
                        'assets/icons/menu/arrow_down.svg',
                      ),
                      onChanged: (core.Asset? newAsset) {
                        if (newAsset != null) {
                          setState(() {
                            _fromAsset = newAsset;
                            // Ensure TO asset is always different from FROM
                            if (_toAsset == _fromAsset) {
                              final alternatives =
                                  core.Asset.values
                                      .where((a) => a != _fromAsset)
                                      .toList();
                              if (alternatives.isNotEmpty) {
                                _toAsset = alternatives.first;
                              }
                            }
                          });
                          _requestQuoteDebounced();
                        }
                      },
                      items:
                          core.Asset.values.map<DropdownMenuItem<core.Asset>>((
                            core.Asset asset,
                          ) {
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
                        return core.Asset.values.map<Widget>((
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
                        controller: _fromAmountController,
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
                        onChanged: (value) => _requestQuoteDebounced(),
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
              Text(_fromAsset.name),
              FutureBuilder<Either<String, double>>(
                future: ref.read(fiatPriceProvider(_fromAsset).future),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!.fold((error) => const Text(' .00'), (
                      price,
                    ) {
                      final amount =
                          BigInt.tryParse(_fromAmountController.text.trim()) ??
                          BigInt.zero;
                      final usd = _fromAsset.toUsd(amount, price);
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

  // TO card
  Widget _to(BuildContext context) {
    final currency = ref.read(currencyControllerProvider.notifier);
    final quote = ref.watch(swapControllerProvider).currentQuote?.quote;
    final toOptions =
        core.Asset.values.where((asset) => asset != _fromAsset).toList();
    return Container(
      height: 115,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: const [Color(0xFF2D2E2A), AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Você recebe',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      FutureBuilder<String>(
                        future: _getBalance(_toAsset),
                        builder: (context, snapshot) {
                          return Text(
                            '${snapshot.data ?? "..."}',
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(_toAsset.iconPath, width: 25, height: 25),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<core.Asset>(
                          value: _toAsset,
                          underline: const SizedBox.shrink(),
                          icon: SvgPicture.asset(
                            'assets/icons/menu/arrow_down.svg',
                          ),
                          onChanged: (core.Asset? newAsset) {
                            if (newAsset != null) {
                              setState(() => _toAsset = newAsset);
                              _requestQuoteDebounced();
                            }
                          },
                          items:
                              toOptions.map<DropdownMenuItem<core.Asset>>((
                                core.Asset asset,
                              ) {
                                return DropdownMenuItem<core.Asset>(
                                  value: asset,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        asset.iconPath,
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        asset.ticker,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return toOptions.map<Widget>((core.Asset asset) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    asset.ticker,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                              );
                            }).toList();
                          },
                        ),
                        Text(
                          quote != null ? quote.quoteAmount.toString() : '0',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_toAsset.name),
                  FutureBuilder<Either<String, double>>(
                    future: ref.read(fiatPriceProvider(_toAsset).future),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (error) => const Text('0.00'),
                          (price) {
                            final q = quote?.quoteAmount ?? 0;
                            final usd = _toAsset.toUsd(BigInt.from(q), price);
                            return Text(
                              '${currency.icon}${usd.toStringAsFixed(2)}',
                            );
                          },
                        );
                      }
                      return const Text('...');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRate(double? rate) {
    if (rate == null) return '...';
    return rate.toStringAsFixed(8);
  }

  Future<String> _getBalance(core.Asset asset) async {
    final either = await ref.read(balanceProvider(asset).future);
    return either.match((l) => '0', (r) => asset.formatBalance(r));
  }

  Future<BigInt> _getBalanceRaw(core.Asset asset) async {
    final either = await ref.read(balanceProvider(asset).future);
    return either.match((l) => BigInt.zero, (r) => r);
  }

  Future<bool> _hasInsufficientBalance() async {
    if (_fromAmountController.text.isEmpty) return false;
    final balance = await _getBalanceRaw(_fromAsset);
    final amount =
        BigInt.tryParse(_fromAmountController.text.trim()) ?? BigInt.zero;
    return amount > balance;
  }

  void _requestQuoteDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final controller = ref.read(swapControllerProvider.notifier);
      final text = _fromAmountController.text.trim();
      final amount = BigInt.tryParse(text);
      if (amount == null || amount <= BigInt.zero) return;
      await controller.startQuote(
        baseAsset: _fromAsset.id,
        quoteAsset: _toAsset.id,
        assetType: 'Base',
        amount: amount,
        direction: SwapDirection.sell,
      );
    });
  }
}

class _SwapIcon extends StatelessWidget {
  const _SwapIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/icons/menu/swap.svg');
  }
}
