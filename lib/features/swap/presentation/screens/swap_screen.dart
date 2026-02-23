import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../providers/swap_controller.dart';
import '../widgets/confirm_swap_bottom_sheet.dart';
import '../widgets/btc_lbtc_swap_warning_dialog.dart';
import '../helpers/btc_lbtc_swap_helper.dart';
import '../providers/swap_onboarding_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/text_button.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/infra/sync/sync.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  final TextEditingController _fromAmountController = TextEditingController();
  late final TextEditingController _fromAmountDecimalController;
  core.Asset _fromAsset = core.Asset.depix;
  core.Asset _toAsset = core.Asset.lbtc;
  Timer? _debounce;
  bool _isSyncingDecimal = false;
  bool _hasShownNoLiquidityDialog = false;
  bool _useDrain = false;
  int _swapKey = 0;
  bool _hasCheckedBtcLbtcWarning = false;

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

        String newValue;
        if (isBtcOrLbtc) {
          newValue = amount.toString();
        } else {
          newValue = (amount.toDouble() / 100000000).toStringAsFixed(2);
        }

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
  void deactivate() {
    debugPrint('[SwapScreen] Deactivating - cleaning up active quote');
    ref.read(swapControllerProvider.notifier).resetQuote();
    super.deactivate();
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('Swap'),
          actions: [
            OfflineIndicator(
              onTap: () => OfflinePriceInfoOverlay.show(context),
            ),
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
              key: ValueKey(_swapKey),
              mainAxisSize: MainAxisSize.min,
              children: [
                _from(context),
                GestureDetector(
                  onTap: () async {
                    final oldFromAsset = _fromAsset;
                    final oldToAsset = _toAsset;

                    _fromAmountController.text = '';
                    _fromAmountDecimalController.text = '';

                    await ref
                        .read(swapControllerProvider.notifier)
                        .resetQuote();

                    if (!mounted) return;

                    setState(() {
                      final tmp = _fromAsset;
                      _fromAsset = _toAsset;
                      _toAsset = tmp;

                      _useDrain = false;
                      _swapKey++;
                    });

                    ref.invalidate(fiatPriceProvider(oldFromAsset));
                    ref.invalidate(fiatPriceProvider(oldToAsset));
                    ref.invalidate(fiatPriceProvider(_fromAsset));
                    ref.invalidate(fiatPriceProvider(_toAsset));

                    ref.invalidate(balanceProvider(oldFromAsset));
                    ref.invalidate(balanceProvider(oldToAsset));
                    ref.invalidate(balanceProvider(_fromAsset));
                    ref.invalidate(balanceProvider(_toAsset));

                    if (mounted) {
                      setState(() {});
                    }
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
                else if (!_isBtcLbtcSwap &&
                    _fromAmountController.text.isNotEmpty &&
                    swapState.currentQuote?.quote != null) ...[
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

                    final isQuoteValid =
                        !hasQuote ||
                        (swapState.lastSendAssetId == _fromAsset.id &&
                            swapState.lastReceiveAssetId == _toAsset.id);

                    final canProceed =
                        _isBtcLbtcSwap
                            ? _fromAmountController.text.isNotEmpty &&
                                !isLoading &&
                                !hasInsufficientBalance &&
                                _isBtcLbtcSwapAmountValid()
                            : _fromAmountController.text.isNotEmpty &&
                                hasQuote &&
                                isQuoteValid &&
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
                                      final currentState = ref.read(
                                        swapControllerProvider,
                                      );
                                      final quote = currentState.currentQuote;

                                      if (quote != null) {
                                        final isSendAssetCorrect =
                                            currentState.lastSendAssetId ==
                                            _fromAsset.id;
                                        final isReceiveAssetCorrect =
                                            currentState.lastReceiveAssetId ==
                                            _toAsset.id;

                                        if (!isSendAssetCorrect ||
                                            !isReceiveAssetCorrect) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Atualizando cotação...',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                          _requestQuoteDebounced();
                                          return;
                                        }
                                      }

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
                  FutureBuilder<Either<String, double>>(
                    future: ref.watch(fiatPriceProvider(_fromAsset).future),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (error) => const Text('0.00'),
                          (price) {
                            final amount =
                                BigInt.tryParse(
                                  _fromAmountController.text.trim(),
                                ) ??
                                BigInt.zero;
                            final usd = _fromAsset.toUsd(amount, price);
                            return Text(
                              '${currency.icon}${usd.toStringAsFixed(2)}',
                            );
                          },
                        );
                      }
                      return const Text('...');
                    },
                  ),
                  const SizedBox(width: 5),
                  TransparentTextButton(
                    text: 'MAX',
                    onPressed: () async {
                      await ref
                          .read(swapControllerProvider.notifier)
                          .resetQuote();

                      if (!mounted) return;

                      final balance = await _getBalanceRaw(_fromAsset);
                      if (!mounted) return;

                      _fromAmountController.text = balance.toString();
                      setState(() {
                        _useDrain = true;
                      });
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
                    _CustomAssetDropdown(
                      value: _fromAsset,
                      items: fromOptions,
                      onChanged: (core.Asset? newAsset) async {
                        if (newAsset != null) {
                          await ref
                              .read(swapControllerProvider.notifier)
                              .resetQuote();

                          if (!mounted) return;

                          setState(() {
                            _fromAsset = newAsset;
                            _useDrain = false;
                            _hasCheckedBtcLbtcWarning = false;

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

                          ref.invalidate(balanceProvider(_fromAsset));
                          ref.invalidate(balanceProvider(_toAsset));

                          await _checkAndShowBtcLbtcWarning();
                        }
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _fromAmountDecimalController,
                        keyboardType:
                            (_fromAsset == core.Asset.btc ||
                                    _fromAsset == core.Asset.lbtc)
                                ? const TextInputType.numberWithOptions(
                                  decimal: false,
                                )
                                : const TextInputType.numberWithOptions(
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

                          _useDrain = false;

                          if (value.isEmpty) {
                            _fromAmountController.text = '';
                            _isSyncingDecimal = false;
                            _requestQuoteDebounced();
                            return;
                          }

                          final isBtcOrLbtc =
                              _fromAsset == core.Asset.btc ||
                              _fromAsset == core.Asset.lbtc;
                          BigInt sats;

                          if (isBtcOrLbtc) {
                            sats = BigInt.tryParse(value) ?? BigInt.zero;
                          } else {
                            double parsed =
                                double.tryParse(value.replaceAll(',', '.')) ??
                                0;
                            sats = BigInt.from((parsed * 100000000).round());
                          }

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
              Text('Saldo disponível:'),
              Consumer(
                builder: (context, ref, child) {
                  final balanceAsync = ref.watch(balanceProvider(_fromAsset));
                  return balanceAsync.when(
                    data: (either) {
                      return either.fold(
                        (error) => Text(
                          '...',
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        (balance) => Text(
                          _fromAsset.formatBalance(balance),
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    },
                    loading:
                        () => Text(
                          '...',
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    error:
                        (err, stack) => Text(
                          '...',
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppColors.textSecondary),
                        ),
                  );
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

      final isQuoteValid =
          swapState.lastSendAssetId == _fromAsset.id &&
          swapState.lastReceiveAssetId == _toAsset.id;

      if (!isQuoteValid) return '0';

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
                      FutureBuilder<Either<String, double>>(
                        future: ref.watch(fiatPriceProvider(_toAsset).future),
                        builder: (context, snapshot) {
                          if (_fromAmountController.text.trim().isEmpty) {
                            return const Text('0.00');
                          }

                          final isQuoteValid =
                              swapState.lastSendAssetId == _fromAsset.id &&
                              swapState.lastReceiveAssetId == _toAsset.id;

                          if (!isQuoteValid) {
                            return const Text('0.00');
                          }

                          if (snapshot.hasData) {
                            return snapshot.data!.fold(
                              (error) => const Text('0.00'),
                              (price) {
                                final amount = swapState.receiveAmount ?? 0;
                                if (amount == 0) {
                                  return const Text('0.00');
                                }
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
              Row(
                children: [
                  SvgPicture.asset(_toAsset.iconPath, width: 25, height: 25),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CustomAssetDropdown(
                          value: _toAsset,
                          items: toOptions,
                          onChanged: (core.Asset? newAsset) async {
                            if (newAsset != null) {
                              await ref
                                  .read(swapControllerProvider.notifier)
                                  .resetQuote();

                              if (!mounted) return;

                              setState(() {
                                _toAsset = newAsset;
                                _useDrain = false;
                                _hasCheckedBtcLbtcWarning = false;

                                if (_toAsset == core.Asset.btc) {
                                  _fromAsset = core.Asset.lbtc;
                                }

                                _fromAmountController.text = '';
                                _fromAmountDecimalController.text = '';
                              });

                              ref.invalidate(balanceProvider(_fromAsset));
                              ref.invalidate(balanceProvider(_toAsset));

                              await _checkAndShowBtcLbtcWarning();
                            }
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
                  Text('Saldo disponível:'),
                  Consumer(
                    builder: (context, ref, child) {
                      final balanceAsync = ref.watch(balanceProvider(_toAsset));
                      return balanceAsync.when(
                        data: (either) {
                          return either.fold(
                            (error) => Text(
                              '...',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            (balance) => Text(
                              _toAsset.formatBalance(balance),
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          );
                        },
                        loading:
                            () => Text(
                              '...',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                        error:
                            (err, stack) => Text(
                              '...',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                      );
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

  Future<void> _clearSwapFields() async {
    if (!mounted) {
      debugPrint('[Swap] Widget não montado, cancelando _clearSwapFields');
      return;
    }

    final oldFromAsset = _fromAsset;
    final oldToAsset = _toAsset;

    setState(() {
      _fromAmountController.text = '';
      _fromAmountDecimalController.text = '';
    });

    try {
      if (!mounted) return;

      final walletDataManager = ref.read(walletDataManagerProvider.notifier);
      await walletDataManager.refreshWalletData();
    } catch (e) {
      debugPrint('[Swap] Erro ao atualizar dados da carteira: $e');
    }

    if (!mounted) {
      debugPrint(
        '[Swap] Widget não montado após refresh, cancelando invalidações',
      );
      return;
    }

    try {
      ref.invalidate(allBalancesProvider);

      ref.invalidate(fiatPriceProvider(oldFromAsset));
      ref.invalidate(fiatPriceProvider(oldToAsset));
      ref.invalidate(fiatPriceProvider(_fromAsset));
      ref.invalidate(fiatPriceProvider(_toAsset));

      ref.invalidate(balanceProvider(oldFromAsset));
      ref.invalidate(balanceProvider(oldToAsset));
      ref.invalidate(balanceProvider(_fromAsset));
      ref.invalidate(balanceProvider(_toAsset));
    } catch (e) {
      debugPrint('[Swap] Erro ao invalidar providers: $e');
    }
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

    if (!_useDrain &&
        (amount == null || amount < BigInt.from(_minBtcLbtcSwapSats))) {
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
      amount: amount ?? BigInt.zero,
      fromAsset: _fromAsset,
      toAsset: _toAsset,
      drain: _useDrain && _isBtcLbtcSwap,
    );
  }

  bool _isNoLiquidityError(String error) {
    return error.toLowerCase().contains('no matching orders') ||
        error.toLowerCase().contains('matching orders') ||
        error.toLowerCase().contains('liquidez');
  }

  Future<void> _checkAndShowBtcLbtcWarning() async {
    if (_hasCheckedBtcLbtcWarning) return;
    if (!_isBtcLbtcSwap) return;

    _hasCheckedBtcLbtcWarning = true;

    try {
      final service = await ref.read(
        swapOnboardingServiceFutureProvider.future,
      );

      if (!service.hasSeenBtcLbtcSwapWarning()) {
        if (!mounted) return;
        await BtcLbtcSwapWarningDialog.show(context);
        await service.markBtcLbtcSwapWarningAsSeen();
      }
    } catch (e) {
      // Silently fail if onboarding service is not available
      debugPrint('Error checking BTC/LBTC swap warning: $e');
    }
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

class _CustomAssetDropdown extends StatefulWidget {
  final core.Asset value;
  final List<core.Asset> items;
  final ValueChanged<core.Asset?> onChanged;

  const _CustomAssetDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_CustomAssetDropdown> createState() => _CustomAssetDropdownState();
}

class _CustomAssetDropdownState extends State<_CustomAssetDropdown> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _key = GlobalKey();

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    final spaceBelow = screenSize.height - position.dy - size.height;
    final itemHeight = 44.0;
    final maxItems = widget.items.length;
    final idealHeight = maxItems * itemHeight;
    final maxHeight = idealHeight < spaceBelow ? idealHeight : spaceBelow - 20;

    final spaceRight = screenSize.width - position.dx;
    final dropdownWidth = spaceRight > 200 ? 200.0 : spaceRight - 20;

    return OverlayEntry(
      builder:
          (context) => GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy + size.height + 4.0,
                  child: GestureDetector(
                    onTap: () {},
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.backgroundColor,
                      child: Container(
                        width: dropdownWidth,
                        constraints: BoxConstraints(
                          maxHeight: maxHeight > 0 ? maxHeight : 100,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children:
                              widget.items.map((core.Asset asset) {
                                return InkWell(
                                  onTap: () {
                                    widget.onChanged(asset);
                                    _closeDropdown();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          asset.iconPath,
                                          width: 20,
                                          height: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            asset.ticker,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.value.ticker,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(width: 5),
            SvgPicture.asset('assets/icons/menu/arrow_down.svg'),
          ],
        ),
      ),
    );
  }
}
