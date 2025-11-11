import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../providers/swap_controller.dart';
import '../widgets/confirm_swap_bottom_sheet.dart';
import '../helpers/btc_lbtc_swap_helper.dart';
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
  late final TextEditingController _fromAmountDecimalController;
  core.Asset _fromAsset = core.Asset.lbtc;
  core.Asset _toAsset = core.Asset.usdt;
  Timer? _debounce;
  bool _isSyncingDecimal = false;
  bool _hasShownNoLiquidityDialog = false;

  static const int _minBtcLbtcSwapSats = 25000;

  bool get _isBtcLbtcSwap {
    return (_fromAsset == core.Asset.btc && _toAsset == core.Asset.lbtc) ||
        (_fromAsset == core.Asset.lbtc && _toAsset == core.Asset.btc);
  }

  @override
  void initState() {
    super.initState();
    _fromAmountDecimalController = TextEditingController();

    _validateAndAdjustAssets();

    _fromAmountController.addListener(_syncDecimalFromAmount);

    Future.microtask(
      () => ref.read(swapControllerProvider.notifier).loadMetadata(),
    );
  }

  void _syncDecimalFromAmount() {
    if (_isSyncingDecimal) return;
    _isSyncingDecimal = true;

    final text = _fromAmountController.text.trim();
    if (text.isEmpty) {
      if (_fromAmountDecimalController.text.isNotEmpty) {
        _fromAmountDecimalController.text = '';
      }
    } else {
      final amount = BigInt.tryParse(text);
      if (amount != null && amount > BigInt.zero) {
        final isBtcOrLbtc =
            _fromAsset == core.Asset.btc || _fromAsset == core.Asset.lbtc;
        final decimals = isBtcOrLbtc ? 8 : 2;
        final newValue = (amount.toDouble() / 100000000).toStringAsFixed(
          decimals,
        );

        if (_fromAmountDecimalController.text != newValue) {
          _fromAmountDecimalController.text = newValue;
        }
      }
    }

    _isSyncingDecimal = false;
  }

  void _validateAndAdjustAssets() {
    if (_fromAsset == core.Asset.btc && _toAsset != core.Asset.lbtc) {
      _toAsset = core.Asset.lbtc;
    } else if (_toAsset == core.Asset.btc && _fromAsset != core.Asset.lbtc) {
      _fromAsset = core.Asset.lbtc;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromAmountController.removeListener(_syncDecimalFromAmount);
    _fromAmountController.dispose();
    _fromAmountDecimalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapState = ref.watch(swapControllerProvider);

    final isLoading = swapState.loading;
    final error = swapState.error;

    if (error != null &&
        _isNoLiquidityError(error) &&
        !_hasShownNoLiquidityDialog) {
      _hasShownNoLiquidityDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNoLiquidityDialog(context);
          ref.read(swapControllerProvider.notifier).resetQuote();
        }
      });
    }

    if (error == null || !_isNoLiquidityError(error)) {
      _hasShownNoLiquidityDialog = false;
    }

    final exchangeRate = swapState.exchangeRate;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Swap'),
        actions: [
          OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
          const SizedBox(width: 16),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
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
                  onTap: () async {
                    setState(() {
                      final tmp = _fromAsset;
                      _fromAsset = _toAsset;
                      _toAsset = tmp;

                      _fromAmountController.text = '';
                      _fromAmountDecimalController.text = '';
                    });
                    if (!mounted) return;
                    await ref
                        .read(swapControllerProvider.notifier)
                        .resetQuote();
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
                else if (!_isBtcLbtcSwap) ...[
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
                if (error != null && !_isNoLiquidityError(error))
                  FutureBuilder<bool>(
                    future: _hasInsufficientBalance(),
                    builder: (context, snapshot) {
                      final hasInsufficientBalance = snapshot.data ?? false;
                      final isInsufficientError =
                          error.toLowerCase().contains('insuficiente') ||
                          hasInsufficientBalance;

                      final isUtxoError =
                          error.toLowerCase().contains(
                            'aguarde alguns instantes',
                          ) ||
                          error.toLowerCase().contains('transação anterior');

                      if (isUtxoError) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }

                      if (isInsufficientError &&
                          _fromAmountController.text.isNotEmpty) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
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
                      } else {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }
                    },
                  ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    _isBtcLbtcSwap
                        ? 'Powered by breez.technology'
                        : 'Powered by sideswap.io',
                  ),
                ),
                const SizedBox(height: 15),

                FutureBuilder<bool>(
                  future: _hasInsufficientBalance(),
                  builder: (context, snapshot) {
                    final hasInsufficientBalance = snapshot.data ?? false;
                    final hasQuote = swapState.currentQuote?.quote != null;

                    final canProceed =
                        _isBtcLbtcSwap
                            ? _fromAmountController.text.isNotEmpty &&
                                !isLoading &&
                                !hasInsufficientBalance &&
                                _isBtcLbtcSwapAmountValid()
                            : _fromAmountController.text.isNotEmpty &&
                                hasQuote &&
                                !isLoading &&
                                !hasInsufficientBalance;

                    return Column(
                      children: [
                        if (_isBtcLbtcSwap &&
                            _fromAmountController.text.isNotEmpty &&
                            !_isBtcLbtcSwapAmountValid())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Valor mínimo: ${_minBtcLbtcSwapSats.toString()} sats',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        PrimaryButton(
                          text: 'swap',
                          isEnabled: canProceed,
                          onPressed:
                              canProceed
                                  ? () async {
                                    if (_isBtcLbtcSwap) {
                                      _handleBtcLbtcSwap();
                                    } else {
                                      ConfirmSwapBottomSheet.show(
                                        context,
                                        onSuccess: _clearSwapFields,
                                        onError: _clearSwapFields,
                                      );
                                    }
                                  }
                                  : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FROM card
  Widget _from(BuildContext context) {
    final currency = ref.read(currencyControllerProvider.notifier);

    final fromOptions = () {
      if (_toAsset == core.Asset.btc) {
        return [core.Asset.lbtc];
      } else if (_toAsset == core.Asset.lbtc) {
        return core.Asset.values
            .where((asset) => asset != core.Asset.lbtc)
            .toList();
      } else {
        return core.Asset.values
            .where((asset) => asset != _toAsset && asset != core.Asset.btc)
            .toList();
      }
    }();

    if (!fromOptions.contains(_fromAsset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _fromAsset = fromOptions.first;
        });
      });
    }
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
                      if (!mounted) return;
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
                      onChanged: (core.Asset? newAsset) async {
                        if (newAsset != null) {
                          setState(() {
                            _fromAsset = newAsset;

                            if (_fromAsset == core.Asset.btc) {
                              _toAsset = core.Asset.lbtc;
                            } else if (_toAsset == _fromAsset) {
                              final alternatives =
                                  core.Asset.values
                                      .where((a) => a != _fromAsset)
                                      .toList();
                              if (alternatives.isNotEmpty) {
                                _toAsset = alternatives.first;
                              }
                            }

                            _fromAmountController.text = '';
                            _fromAmountDecimalController.text = '';
                          });
                          if (!mounted) return;
                          await ref
                              .read(swapControllerProvider.notifier)
                              .resetQuote();
                        }
                      },
                      items:
                          fromOptions.map<DropdownMenuItem<core.Asset>>((
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
                        return fromOptions.map<Widget>((core.Asset asset) {
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
                        controller: _fromAmountDecimalController,
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
                          if (_isSyncingDecimal) return;
                          _isSyncingDecimal = true;

                          if (value.isEmpty) {
                            _fromAmountController.text = '';
                            _isSyncingDecimal = false;
                            _requestQuoteDebounced();
                            return;
                          }

                          double parsed =
                              double.tryParse(value.replaceAll(',', '.')) ?? 0;
                          BigInt sats = BigInt.from(
                            (parsed * 100000000).round(),
                          );
                          if (_fromAmountController.text != sats.toString()) {
                            _fromAmountController.text = sats.toString();
                          }
                          _isSyncingDecimal = false;
                          _requestQuoteDebounced();
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
              Text(_fromAsset.name),
              FutureBuilder<Either<String, double>>(
                future: ref.read(fiatPriceProvider(_fromAsset).future),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!.fold((error) => const Text('0.00'), (
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
    final swapState = ref.watch(swapControllerProvider);

    final toOptions = () {
      if (_fromAsset == core.Asset.btc) {
        return [core.Asset.lbtc];
      } else if (_fromAsset == core.Asset.lbtc) {
        return core.Asset.values
            .where((asset) => asset != core.Asset.lbtc)
            .toList();
      } else {
        return core.Asset.values
            .where((asset) => asset != _fromAsset && asset != core.Asset.btc)
            .toList();
      }
    }();

    if (!toOptions.contains(_toAsset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _toAsset = toOptions.first;
        });
      });
    }

    String displayToAmount() {
      if (_fromAmountController.text.trim().isEmpty) {
        return '0';
      }

      if (_isBtcLbtcSwap) {
        final text = _fromAmountController.text.trim();
        final amount = BigInt.tryParse(text) ?? BigInt.zero;
        if (_toAsset == core.Asset.btc || _toAsset == core.Asset.lbtc) {
          return amount.toString();
        } else {
          final value = amount.toDouble() / 100000000;
          return value.toStringAsFixed(2);
        }
      }

      final amount = swapState.receiveAmount;
      if (amount == null) return '0';

      if (_toAsset == core.Asset.btc || _toAsset == core.Asset.lbtc) {
        return amount.toString();
      } else {
        final value = amount / 100000000;
        return value.toStringAsFixed(2);
      }
    }

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
                            snapshot.data ?? "...",
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
                          onChanged: (core.Asset? newAsset) async {
                            if (newAsset != null) {
                              setState(() {
                                _toAsset = newAsset;

                                if (_toAsset == core.Asset.btc) {
                                  _fromAsset = core.Asset.lbtc;
                                }

                                _fromAmountController.text = '';
                                _fromAmountDecimalController.text = '';
                              });
                              if (!mounted) return;
                              await ref
                                  .read(swapControllerProvider.notifier)
                                  .resetQuote();
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            displayToAmount(),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
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
                  Text(_toAsset.name),
                  FutureBuilder<Either<String, double>>(
                    future: ref.read(fiatPriceProvider(_toAsset).future),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (error) => const Text('0.00'),
                          (price) {
                            final amount = swapState.receiveAmount ?? 0;
                            final usd = _toAsset.toUsd(
                              BigInt.from(amount),
                              price,
                            );
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

  void _clearSwapFields() {
    if (!mounted) return;
    setState(() {
      _fromAmountController.text = '';
      _fromAmountDecimalController.text = '';
    });
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

  bool _isBtcLbtcSwapAmountValid() {
    final text = _fromAmountController.text.trim();
    final amount = BigInt.tryParse(text);
    if (amount == null) return false;
    return amount >= BigInt.from(_minBtcLbtcSwapSats);
  }

  Future<void> _handleBtcLbtcSwap() async {
    final text = _fromAmountController.text.trim();
    final amount = BigInt.tryParse(text);

    if (amount == null || amount < BigInt.from(_minBtcLbtcSwapSats)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantidade mínima é ${_minBtcLbtcSwapSats} sats'),
          ),
        );
      }
      return;
    }

    final helper = BtcLbtcSwapHelper(context, ref);
    await helper.executeSwap(
      amount: amount,
      fromAsset: _fromAsset,
      toAsset: _toAsset,
    );
  }

  bool _isNoLiquidityError(String error) {
    return error.toLowerCase().contains('no matching orders') ||
        error.toLowerCase().contains('matching orders') ||
        error.toLowerCase().contains('liquidez');
  }

  void _showNoLiquidityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sem Liquidez',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No momento não há liquidez disponível na Sideswap para realizar esta operação.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _requestQuoteDebounced();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Fechar',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _requestQuoteDebounced() {
    _debounce?.cancel();

    if (_isBtcLbtcSwap) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      final controller = ref.read(swapControllerProvider.notifier);
      final text = _fromAmountController.text.trim();
      final amount = BigInt.tryParse(text);
      if (amount == null || amount <= BigInt.zero) return;
      await controller.startQuote(
        sendAsset: _fromAsset.id,
        receiveAsset: _toAsset.id,
        amount: amount,
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
