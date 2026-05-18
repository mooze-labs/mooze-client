import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:mooze_mobile/shared/prices/models.dart' show Currency;

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
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart' hide balanceProvider;
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

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
  bool _hasCheckedBtcLbtcWarning = false;
  bool _isFiatMode = false;
  double? _cachedFromPrice;

  /// Cached locale used by listeners that have no [BuildContext]
  /// (e.g. [_syncDecimalFromAmount]). Refreshed in
  /// [didChangeDependencies] whenever Flutter's locale changes.
  String _locale = 'en_US';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).toString();
  }

  void _syncDecimalFromAmount() {
    if (_isSyncingDecimal) return;
    if (_isFiatMode) return;
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
          // Format with locale-aware thousands separators so the
          // displayed text matches what the input formatter would
          // produce on user keystrokes.
          newValue = NumberFormat('#,##0', _locale).format(amount.toInt());
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
    debugPrint('[SwapScreen] Deactivating - disposing swap provider');
    ref.invalidate(swapControllerProvider);
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
    final t = AppLocalizations.of(context);
    final swapState = ref.watch(swapControllerProvider);

    final isLoading = swapState.loading;
    final error = swapState.error;

    if (error != null &&
        error.code == SwapErrorCode.noLiquidity &&
        !_hasShownNoLiquidityDialog) {
      _hasShownNoLiquidityDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNoLiquidityDialog(context);
          ref.read(swapControllerProvider.notifier).resetQuote();
        }
      });
    }

    if (error == null || error.code != SwapErrorCode.noLiquidity) {
      _hasShownNoLiquidityDialog = false;
    }

    final exchangeRate = swapState.exchangeRate;

    final currency = ref.watch(currencyControllerProvider.notifier);
    final canToggleFiatMode = _cachedFromPrice != null && _cachedFromPrice! > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(t.swap_title),
          actions: [
            _FiatModeSwitch(
              isFiatMode: _isFiatMode,
              currencyIcon: currency.icon,
              enabled: canToggleFiatMode,
              onChanged: (value) {
                if (!canToggleFiatMode) return;
                if (value == _isFiatMode) return;
                _toggleFiatMode();
              },
            ),
            OfflineIndicator(
              onTap: () => OfflinePriceInfoOverlay.show(context),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          // No outer card surface — the From/To cards already carry
          // their own elevated surfaces. A third wrapper just stacked
          // surfaces and muddied the contrast in both themes.
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _from(context),
                _SwapDirectionChip(
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
                    });

                    ref.invalidate(fiatPriceProvider(oldFromAsset));
                    ref.invalidate(fiatPriceProvider(oldToAsset));
                    ref.invalidate(fiatPriceProvider(_fromAsset));
                    ref.invalidate(fiatPriceProvider(_toAsset));

                    ref.invalidate(balanceProvider(oldFromAsset));
                    ref.invalidate(balanceProvider(oldToAsset));
                    ref.invalidate(balanceProvider(_fromAsset));
                    ref.invalidate(balanceProvider(_toAsset));

                    if (mounted) setState(() {});
                  },
                ),
                _to(context),
                const SizedBox(height: 15),
                if (isLoading)
                  Shimmer.fromColors(
                    baseColor: context.colors.baseColor,
                    highlightColor: context.colors.highlightColor,
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
                  _RateIndicator(
                    remainingMs: swapState.millisecondsRemaining ??
                        swapState.ttlMilliseconds,
                    totalMs: swapState.ttlMilliseconds,
                    showShimmer:
                        swapState.status == QuoteStatus.fetching ||
                            swapState.status == QuoteStatus.refreshing,
                    rateText: _rateLineText(exchangeRate),
                    onTap: ref
                        .read(swapControllerProvider.notifier)
                        .requestFreshQuote,
                  ),
                ],
                if (error != null) const SizedBox(height: 8),
                if (error != null && error.code != SwapErrorCode.noLiquidity)
                  FutureBuilder<bool>(
                    future: _hasInsufficientBalance(),
                    builder: (context, snapshot) {
                      final hasInsufficientBalance = snapshot.data ?? false;
                      final isInsufficientError =
                          error.code == SwapErrorCode.insufficientBalance ||
                          hasInsufficientBalance;
                      final isUtxoError = error.code == SwapErrorCode.utxoBusy;

                      final _StatusTone tone;
                      final IconData icon;
                      final String message;
                      if (isUtxoError) {
                        tone = _StatusTone.info;
                        icon = Icons.schedule;
                        message = error.localize(context);
                      } else if (isInsufficientError &&
                          _fromAmountController.text.isNotEmpty) {
                        tone = _StatusTone.warning;
                        icon = Icons.warning_amber_rounded;
                        message = t.swap_insufficient_balance;
                      } else {
                        tone = _StatusTone.error;
                        icon = Icons.error_outline;
                        message = error.localize(context);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StatusBanner(
                          tone: tone,
                          icon: icon,
                          message: message,
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isBtcLbtcSwap
                        ? 'Powered by breez.technology'
                        : 'Powered by sideswap.io',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                            child: _StatusBanner(
                              tone: _StatusTone.warning,
                              icon: Icons.info_outline,
                              message: t.swap_min_value_sats(
                                _minBtcLbtcSwapSats.toString(),
                              ),
                            ),
                          ),
                        PrimaryButton(
                          text: t.swap_title,
                          isEnabled: canProceed,
                          onPressed:
                              canProceed
                                  ? () async {
                                    if (_isBtcLbtcSwap) {
                                      _handleBtcLbtcSwap();
                                      return;
                                    }

                                    // First click: the debounced quote
                                    // from typing is already on screen,
                                    // so open the sheet immediately —
                                    // no extra round-trip. `show` returns
                                    // false if a sheet is already visible
                                    // (rapid double-tap guard).
                                    final didOpen =
                                        await ConfirmSwapBottomSheet.show(
                                          context,
                                          onSuccess: _clearSwapFields,
                                          onError: _clearSwapFields,
                                        );

                                    if (!mounted) return;
                                    if (!didOpen) return;

                                    // After the sheet closes, refresh
                                    // the quote subscription so the next
                                    // open starts with a fresh quote_id
                                    // and a full TTL. Skip if the swap
                                    // succeeded or errored (both clear
                                    // the input via _clearSwapFields).
                                    final remaining = BigInt.tryParse(
                                      _fromAmountController.text.trim(),
                                    );
                                    if (remaining == null ||
                                        remaining <= BigInt.zero) {
                                      return;
                                    }
                                    final controller = ref.read(
                                      swapControllerProvider.notifier,
                                    );
                                    await controller.resetQuote();
                                    if (!mounted) return;
                                    await controller.startQuote(
                                      sendAsset: _fromAsset.id,
                                      receiveAsset: _toAsset.id,
                                      amount: remaining,
                                    );
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
    final t = AppLocalizations.of(context);
    final currencyEnum = ref.watch(currencyControllerProvider);

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _swapCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: label + fiat-estimate / MAX ────────────────────
          Row(
            children: [
              _CardLabel(t.swap_you_send),
              const Spacer(),
              FutureBuilder<Either<String, double>>(
                future: ref.watch(fiatPriceProvider(_fromAsset).future),
                builder: (context, snapshot) {
                  final secondaryStyle = theme.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                  );
                  if (!snapshot.hasData) {
                    return Text('—', style: secondaryStyle);
                  }
                  return snapshot.data!.fold(
                    (_) => Text('—', style: secondaryStyle),
                    (price) {
                      _cachedFromPrice = price;
                      final amount =
                          BigInt.tryParse(_fromAmountController.text.trim()) ??
                          BigInt.zero;
                      if (_isFiatMode) {
                        final locale =
                            Localizations.localeOf(context).toString();
                        final assetDisplay =
                            '${_fromAsset.formatAmount(amount.toInt(), locale: locale)} ${_fromAsset.displayUnit}';
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            amount > BigInt.zero ? '≈ $assetDisplay' : '',
                            key: ValueKey('fiat_$assetDisplay'),
                            style: secondaryStyle,
                          ),
                        );
                      }
                      final usd = _fromAsset.toUsd(amount, price);
                      return Text(
                        _formatFiatFromDouble(
                          usd,
                          currencyEnum,
                          withSymbol: true,
                        ),
                        style: secondaryStyle,
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              TransparentTextButton(
                text: t.common_max,
                onPressed: () async {
                  await ref.read(swapControllerProvider.notifier).resetQuote();
                  if (!mounted) return;
                  final balance = await _getBalanceRaw(_fromAsset);
                  if (!mounted) return;
                  _fromAmountController.text = balance.toString();
                  if (_isFiatMode &&
                      _cachedFromPrice != null &&
                      _cachedFromPrice! > 0) {
                    final fiatValue = _fromAsset.toUsd(
                      balance,
                      _cachedFromPrice!,
                    );
                    _fromAmountDecimalController.text = _formatFiatFromDouble(
                      fiatValue,
                      currencyEnum,
                      withSymbol: true,
                    );
                  }
                  setState(() => _useDrain = true);
                  _requestQuoteDebounced();
                },
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.colors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Main row: asset chip + amount input ────────────────────
          // Fixed height keeps the From card aligned to the To card —
          // a bare `TextField` is intrinsically taller than a `Text`
          // due to cursor/baseline padding.
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(_fromAsset.iconPath, width: 28, height: 28),
                const SizedBox(width: 10),
                _CustomAssetDropdown(
                  value: _fromAsset,
                  items: fromOptions,
                  onChanged: (core.Asset? newAsset) async {
                    if (newAsset == null) return;
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
                  },
                ),
                Expanded(
                  child: Row(
                    // Baseline alignment so the unit suffix (e.g. USDT)
                    // sits on the same alphabetic baseline as the bold
                    // TextField content — matching the To-card layout.
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromAmountDecimalController,
                          keyboardType:
                              _isFiatMode
                                  ? const TextInputType.numberWithOptions(
                                    decimal: false,
                                    signed: false,
                                  )
                                  : (_fromAsset == core.Asset.btc ||
                                      _fromAsset == core.Asset.lbtc)
                                  ? const TextInputType.numberWithOptions(
                                    decimal: false,
                                  )
                                  : const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                          textAlign: TextAlign.end,
                          inputFormatters:
                              _isFiatMode
                                  ? [_FiatCentInputFormatter(currencyEnum)]
                                  : (_fromAsset == core.Asset.btc ||
                                      _fromAsset == core.Asset.lbtc)
                                  ? [
                                    _IntegerThousandsFormatter(
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ),
                                  ]
                                  : null,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
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
                            hintText:
                                _isFiatMode
                                    ? _formatFiatFromCents(
                                      BigInt.zero,
                                      currencyEnum,
                                      withSymbol: true,
                                    )
                                    : '0',
                            hintStyle: theme.textTheme.titleMedium?.copyWith(
                              color: context.colors.textTertiary,
                              fontWeight: FontWeight.w700,
                            ),
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
                            if (_isFiatMode) {
                              final fiatAmount = _parseFiatToDouble(value);
                              if (_cachedFromPrice != null &&
                                  _cachedFromPrice! > 0) {
                                final sats = _fromAsset.fromUsd(
                                  fiatAmount,
                                  _cachedFromPrice!,
                                );
                                if (_fromAmountController.text !=
                                    sats.toString()) {
                                  _fromAmountController.text = sats.toString();
                                }
                              }
                            } else {
                              final isBtcOrLbtc =
                                  _fromAsset == core.Asset.btc ||
                                  _fromAsset == core.Asset.lbtc;
                              BigInt sats;
                              if (isBtcOrLbtc) {
                                // Field is formatted with thousands separators
                                // (`1,253,048`), so strip everything but digits
                                // before parsing.
                                final digits = value.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                sats = BigInt.tryParse(digits) ?? BigInt.zero;
                              } else {
                                final parsed =
                                    double.tryParse(
                                      value.replaceAll(',', '.'),
                                    ) ??
                                    0;
                                sats = BigInt.from(
                                  (parsed * 100000000).round(),
                                );
                              }
                              if (_fromAmountController.text !=
                                  sats.toString()) {
                                _fromAmountController.text = sats.toString();
                              }
                            }
                            _isSyncingDecimal = false;
                            _requestQuoteDebounced();
                          },
                        ),
                      ),
                      if (!_isFiatMode) ...[
                        const SizedBox(width: 6),
                        Text(
                          _fromAsset.displayUnit,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _CardDivider(),
          const SizedBox(height: 10),
          _BalanceRow(asset: _fromAsset),
        ],
      ),
    );
  }

  // TO card
  Widget _to(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currencyEnum = ref.watch(currencyControllerProvider);
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

    final locale = Localizations.localeOf(context).toString();

    String displayToAmount() {
      if (_fromAmountController.text.trim().isEmpty) return '0';

      if (_isBtcLbtcSwap) {
        final amount =
            BigInt.tryParse(_fromAmountController.text.trim()) ?? BigInt.zero;
        return _toAsset.formatAmount(amount.toInt(), locale: locale);
      }

      final isQuoteValid =
          swapState.lastSendAssetId == _fromAsset.id &&
          swapState.lastReceiveAssetId == _toAsset.id;
      if (!isQuoteValid) return '0';

      final amount = swapState.receiveAmount;
      if (amount == null) return '0';
      return _toAsset.formatAmount(amount, locale: locale);
    }

    // Drive shimmer / fade off the unified quote status so the
    // receive amount stays consistent with the bottom sheet's UX.
    // BTC↔LBTC uses Breez (not Sideswap) so it has no QuoteStatus — fall
    // back to "valid" while the user has an amount typed in.
    final hasFromAmount = _fromAmountController.text.trim().isNotEmpty;
    final receiveIsFetching =
        !_isBtcLbtcSwap &&
        hasFromAmount &&
        swapState.status == QuoteStatus.fetching;
    final receiveIsRefreshing =
        !_isBtcLbtcSwap &&
        hasFromAmount &&
        swapState.status == QuoteStatus.refreshing;

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _swapCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: label + fiat estimate ──────────────────────────
          Row(
            children: [
              _CardLabel(t.swap_you_receive),
              const Spacer(),
              FutureBuilder<Either<String, double>>(
                future: ref.watch(fiatPriceProvider(_toAsset).future),
                builder: (context, snapshot) {
                  final secondaryStyle = theme.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                  );
                  if (_fromAmountController.text.trim().isEmpty) {
                    return Text('—', style: secondaryStyle);
                  }
                  final isQuoteValid =
                      swapState.lastSendAssetId == _fromAsset.id &&
                      swapState.lastReceiveAssetId == _toAsset.id;
                  if (!isQuoteValid) {
                    return Text('—', style: secondaryStyle);
                  }
                  if (!snapshot.hasData) {
                    return Text('—', style: secondaryStyle);
                  }
                  return snapshot.data!.fold(
                    (_) => Text('—', style: secondaryStyle),
                    (price) {
                      final amount = swapState.receiveAmount ?? 0;
                      if (amount == 0) {
                        return Text('—', style: secondaryStyle);
                      }
                      final usd = _toAsset.toUsd(BigInt.from(amount), price);
                      return Text(
                        '≈ ${_formatFiatFromDouble(usd, currencyEnum, withSymbol: true)}',
                        style: secondaryStyle,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Main row: asset chip + receive amount (status-aware) ───
          // Fixed height matches the From card so the two read as a pair.
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(_toAsset.iconPath, width: 28, height: 28),
                const SizedBox(width: 10),
                _CustomAssetDropdown(
                  value: _toAsset,
                  items: toOptions,
                  onChanged: (core.Asset? newAsset) async {
                    if (newAsset == null) return;
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
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedOpacity(
                      opacity: receiveIsRefreshing ? 0.55 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child:
                          receiveIsFetching
                              ? Align(
                                alignment: Alignment.centerRight,
                                child: Shimmer.fromColors(
                                  baseColor: context.colors.baseColor,
                                  highlightColor: context.colors.highlightColor,
                                  child: Container(
                                    width: 110,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayToAmount(),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _toAsset.displayUnit,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: context.colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _CardDivider(),
          const SizedBox(height: 10),
          _BalanceRow(asset: _toAsset),
        ],
      ),
    );
  }

  String _formatRate(double? rate) {
    if (rate == null) return '...';
    // Adaptive precision: very small rates need many decimals to be
    // useful (e.g. BTC per stablecoin = 0.00001307); large rates only
    // need a couple. Thousands separators in the integer part stay
    // locale-aware via `NumberFormat`.
    final String pattern;
    if (rate < 0.0001) {
      pattern = '#,##0.########';
    } else if (rate < 1) {
      pattern = '#,##0.######';
    } else if (rate < 1000) {
      pattern = '#,##0.####';
    } else {
      pattern = '#,##0.##';
    }
    return NumberFormat(pattern, _locale).format(rate);
  }

  /// Produces the rate text rendered in [_RateIndicator]. When the
  /// receive asset is BTC/LBTC we express the right-hand side in sats
  /// (e.g. `1 USDT = 1,300 SATS`) — matches how amounts are shown in
  /// the deal cards. Otherwise the natural unit is used.
  String _rateLineText(double? rate) {
    if (rate == null) return '...';
    final isReceiveBtc =
        _toAsset == core.Asset.btc || _toAsset == core.Asset.lbtc;
    final scale = isReceiveBtc ? 100000000.0 : 1.0;
    final scaled = rate * scale;
    final formatted = isReceiveBtc
        // BTC/LBTC sats are always integer-valued for rate display —
        // skip decimal noise like ".00".
        ? NumberFormat('#,##0', _locale).format(scaled)
        : _formatRate(scaled);
    return '1 ${_fromAsset.ticker} = $formatted ${_toAsset.displayUnit}';
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

      final useCase = await ref.read(refreshWalletProvider.future);
      await useCase(strategy: SyncStrategy.light);
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
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.swap_min_amount_sats(_minBtcLbtcSwapSats.toString()),
            ),
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
        final t = AppLocalizations.of(context);
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
                  t.swap_no_liquidity_title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    // color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.swap_no_liquidity_body,
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
                      backgroundColor: context.colors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t.common_retry,
                      style: const TextStyle(
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
                      t.common_close,
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

  void _toggleFiatMode() {
    if (_cachedFromPrice == null || _cachedFromPrice! <= 0) return;
    setState(() {
      _isFiatMode = !_isFiatMode;
      _convertForModeSwitch();
    });
  }

  void _convertForModeSwitch() {
    final sats =
        BigInt.tryParse(_fromAmountController.text.trim()) ?? BigInt.zero;

    if (_isFiatMode) {
      // Switching TO fiat mode: convert current sats to fiat display
      if (sats > BigInt.zero &&
          _cachedFromPrice != null &&
          _cachedFromPrice! > 0) {
        final fiatValue = _fromAsset.toUsd(sats, _cachedFromPrice!);
        final currencyEnum = ref.read(currencyControllerProvider);
        _fromAmountDecimalController.text = _formatFiatFromDouble(
          fiatValue,
          currencyEnum,
          withSymbol: true,
        );
      } else {
        _fromAmountDecimalController.text = '';
      }
    } else {
      // Switching TO asset mode: convert sats back to asset decimal.
      // Programmatic `.text = ...` assignments bypass the field's
      // `_IntegerThousandsFormatter` (formatters run on user input
      // only), so the formatting must be reapplied here — otherwise
      // toggling fiat off would drop the locale-aware thousands
      // separators and the user would see "1312123" instead of
      // "1,312,123". Mirrors the path in `_syncDecimalFromAmount`.
      final text = _fromAmountController.text.trim();
      if (text.isEmpty) {
        _fromAmountDecimalController.text = '';
      } else {
        final amount = BigInt.tryParse(text);
        if (amount != null && amount > BigInt.zero) {
          final isBtcOrLbtc =
              _fromAsset == core.Asset.btc || _fromAsset == core.Asset.lbtc;
          if (isBtcOrLbtc) {
            _fromAmountDecimalController.text =
                NumberFormat('#,##0', _locale).format(amount.toInt());
          } else {
            _fromAmountDecimalController.text = (amount.toDouble() / 100000000)
                .toStringAsFixed(2);
          }
        } else {
          _fromAmountDecimalController.text = '';
        }
      }
    }
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

/// Minimal rate indicator rendered between the To card and the confirm
/// button. Mirrors `_ExpirationIndicator` in the confirm-swap sheet:
/// a small filling progress ring (driven by the quote TTL) + the
/// inline rate text + a refresh affordance. Tapping anywhere requests
/// a fresh quote. The ring's tone color escalates with remaining time
/// (green / amber / red) so the two screens speak the same visual
/// language about quote freshness.
class _RateIndicator extends StatelessWidget {
  final int? remainingMs;
  final int? totalMs;
  final bool showShimmer;
  final String rateText;
  final Future<void> Function() onTap;

  const _RateIndicator({
    required this.remainingMs,
    required this.totalMs,
    required this.showShimmer,
    required this.rateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(
      remainingMs,
      theme.colorScheme,
      context.appColors.warning,
    );

    // Fills from 0 → 1 as the TTL drains.
    final progress = (remainingMs == null || totalMs == null || totalMs == 0)
        ? null
        : (1.0 - (remainingMs! / totalMs!)).clamp(0.0, 1.0);
    final isLoading = showShimmer || remainingMs == null;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value: isLoading ? null : progress,
                    strokeWidth: 2,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  rateText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.refresh_rounded, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _toneColor(int? remainingMs, ColorScheme cs, Color warning) {
    final r = remainingMs ?? 0;
    if (r >= 10000) return cs.tertiary;
    if (r >= 5000) return warning;
    return cs.error;
  }
}

enum _StatusTone { info, warning, error }

/// Tone-aware status banner used on the swap screen for transient
/// notices (utxo busy, insufficient balance, generic errors). Visual
/// language mirrors the confirm-sheet's `_StaleBanner` / `_ErrorCard`
/// for cross-screen consistency. Tone colors derive from theme tokens
/// so light/dark both look right.
class _StatusBanner extends StatelessWidget {
  final _StatusTone tone;
  final IconData icon;
  final String message;

  const _StatusBanner({
    required this.tone,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      _StatusTone.info => theme.colorScheme.primary,
      _StatusTone.warning => context.appColors.warning,
      _StatusTone.error => theme.colorScheme.error,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

String _localeForCurrency(Currency currency) {
  switch (currency) {
    case Currency.brl:
      return 'pt_BR';
    case Currency.usd:
      return 'en_US';
  }
}

String _symbolForCurrency(Currency currency) {
  switch (currency) {
    case Currency.brl:
      return r'R$';
    case Currency.usd:
      return r'$';
  }
}

String _formatFiatFromCents(
  BigInt cents,
  Currency currency, {
  bool withSymbol = false,
}) {
  final value = cents.toDouble() / 100.0;
  final fmt = NumberFormat('#,##0.00', _localeForCurrency(currency));
  final body = fmt.format(value);
  return withSymbol ? '${_symbolForCurrency(currency)}$body' : body;
}

String _formatFiatFromDouble(
  double value,
  Currency currency, {
  bool withSymbol = false,
}) {
  final cents = BigInt.from((value * 100).round());
  return _formatFiatFromCents(cents, currency, withSymbol: withSymbol);
}

double _parseFiatToDouble(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0.0;
  final cents = BigInt.tryParse(digits) ?? BigInt.zero;
  return cents.toDouble() / 100.0;
}

/// Locale-aware thousands-separator formatter for integer sat amounts
/// (used when the From field is in asset mode and the asset is BTC or
/// LBTC). Strips non-digits from the buffer, re-formats with the
/// active locale, and collapses the cursor to the end so editing
/// remains predictable.
class _IntegerThousandsFormatter extends TextInputFormatter {
  final String locale;
  const _IntegerThousandsFormatter(this.locale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final value = int.tryParse(digits) ?? 0;
    final formatted = NumberFormat('#,##0', locale).format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _FiatCentInputFormatter extends TextInputFormatter {
  final Currency currency;

  const _FiatCentInputFormatter(this.currency);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final cents = BigInt.tryParse(digits) ?? BigInt.zero;
    final formatted = _formatFiatFromCents(cents, currency, withSymbol: true);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Shared decoration for the swap-screen From/To cards. Mirrors the
/// `_DealCard` in [ConfirmSwapBottomSheet] (rounded surface-elevated
/// container with theme-tuned border + per-theme shadow) so the two
/// screens read as a single design system.
BoxDecoration _swapCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    // Dark mode: drop one elevation step so the card lands close to the
    // scaffold tone — `surfaceContainerHighest` rendered as a too-bright
    // gray block against the near-black scaffold. Pair with a stronger
    // border to keep edges defined.
    // Light mode: keep the higher elevation; the contrast is correct.
    color: isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.75 : 0.55),
    ),
    // Light mode keeps a soft drop shadow; in dark mode shadows on a
    // dark scaffold are invisible, so the elevation cue lives in the
    // brighter border instead.
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
  );
}

/// Small uppercase label rendered at the top of a swap card (e.g.
/// "VOCÊ ENVIA"). Matches the `_AmountRow` label treatment in the
/// confirm sheet.
class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// "Saldo disponível · 3.120,96 USDT" row rendered at the bottom of a
/// swap card. Uses the centralized `Asset.formatAmount + displayUnit`
/// pair so light/dark themes and locales render consistently.
class _BalanceRow extends ConsumerWidget {
  final core.Asset asset;
  const _BalanceRow({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(balanceProvider(asset));
    final locale = Localizations.localeOf(context).toString();
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: context.colors.textTertiary,
    );
    final valueStyle = theme.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    String body(BigInt balance) =>
        '${asset.formatAmount(balance.toInt(), locale: locale)} ${asset.displayUnit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t.wallet_balance_available, style: labelStyle),
        balanceAsync.when(
          data:
              (either) => either.fold(
                (_) => Text('—', style: valueStyle),
                (balance) => Text(body(balance), style: valueStyle),
              ),
          loading: () => Text('—', style: valueStyle),
          error: (_, _) => Text('—', style: valueStyle),
        ),
      ],
    );
  }
}

/// Thin divider used inside swap cards. Tunes alpha per theme to land
/// at the same perceived weight in light and dark.
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alpha = theme.brightness == Brightness.dark ? 0.65 : 0.45;
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outline.withValues(alpha: alpha),
    );
  }
}

/// Tappable swap-direction toggle rendered between the From and To
/// cards. Uses the brand SVG icon (`assets/icons/menu/swap.svg`) inside
/// a generous tap target — preferred over Material's
/// `Icons.swap_vert_rounded` because it carries the app's visual
/// language.
/// Visual separator rendered between the From and To cards.
///
/// Layout mirrors the internal divider inside the bottom-sheet deal
/// card: a horizontal hairline on each side of a primary-tinted
/// circular chip that carries the brand SVG swap icon. Tapping the
/// whole strip swaps the asset direction — the chip itself is the
/// obvious affordance but the full row is the hit target so the user
/// doesn't have to aim precisely.
///
/// On every tap the chip bounces (scale 1.0 → 0.85 → 1.0) and the
/// inner icon rotates an additional 180°. Consecutive taps accumulate
/// turns so the spin keeps the same direction rather than snapping
/// back, which reinforces the "swap happened" gesture.
class _SwapDirectionChip extends StatefulWidget {
  final VoidCallback onTap;
  const _SwapDirectionChip({required this.onTap});

  @override
  State<_SwapDirectionChip> createState() => _SwapDirectionChipState();
}

class _SwapDirectionChipState extends State<_SwapDirectionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double> _turns = const AlwaysStoppedAnimation<double>(0);
  Animation<double> _scale = const AlwaysStoppedAnimation<double>(1);
  double _accumulatedTurns = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final start = _accumulatedTurns;
    _accumulatedTurns += 0.5;
    _turns = Tween<double>(begin: start, end: _accumulatedTurns).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
    _controller
      ..reset()
      ..forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = theme.colorScheme.outline.withValues(
      alpha: isDark ? 0.5 : 0.45,
    );

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(child: Divider(color: dividerColor, height: 1)),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.32),
                    width: 1,
                  ),
                ),
                child: RotationTransition(
                  turns: _turns,
                  child: const _SwapIcon(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: dividerColor, height: 1)),
          ],
        ),
      ),
    );
  }
}

class _SwapIcon extends StatelessWidget {
  const _SwapIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/menu/swap.svg',
      width: 18,
      height: 18,
    );
  }
}

class _FiatModeSwitch extends StatelessWidget {
  final bool isFiatMode;
  final String currencyIcon;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _FiatModeSwitch({
    required this.isFiatMode,
    required this.currencyIcon,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        !enabled
            ? context.colors.textTertiary
            : isFiatMode
            ? context.colors.primaryColor
            : context.colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
            child: Text(currencyIcon),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch.adaptive(
                value: isFiatMode,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
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
                      color: context.colors.backgroundColor,
                      child: Container(
                        width: dropdownWidth,
                        constraints: BoxConstraints(
                          maxHeight: maxHeight > 0 ? maxHeight + 10 : 100,
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
                                    padding: EdgeInsets.symmetric(
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
