import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/swap_controller.dart' as sc;
import 'package:mooze_mobile/features/swap/data/models.dart' show SideswapQuote;
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../screens/swap_success_screen.dart';
import 'swap_deal_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class ConfirmSwapBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ConfirmSwapBottomSheet({super.key, this.onSuccess, this.onError});

  /// Sheet-open guard. We only allow one confirm-swap sheet to be visible
  /// at any time — a rapid double-tap on the Swap button would otherwise
  /// stack modal routes and confuse the controller's lifecycle. The flag
  /// is module-private and cleared once the bottom sheet's future resolves.
  static bool _isOpen = false;

  /// Returns `true` if the sheet was actually opened, `false` if a second
  /// call collided with an already-open sheet (which we suppress). Callers
  /// can use the return value to skip post-dismiss work that shouldn't run
  /// when no sheet ever opened — e.g. the background-refresh step in the
  /// Swap-button handler.
  static Future<bool> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (_isOpen) return false;
    _isOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) =>
                ConfirmSwapBottomSheet(onSuccess: onSuccess, onError: onError),
      );
      return true;
    } finally {
      _isOpen = false;
    }
  }

  @override
  ConsumerState<ConfirmSwapBottomSheet> createState() =>
      _ConfirmSwapBottomSheetState();
}

class _ConfirmSwapBottomSheetState
    extends ConsumerState<ConfirmSwapBottomSheet> {
  bool _isConfirming = false;
  bool _feesExpanded = false;

  @override
  void initState() {
    super.initState();
    // If the cached quote is about to die (< 5s remaining) when the user
    // opens the sheet, preempt immediately so we don't show "00:02 →
    // expired" right after the modal lands.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sc.swapControllerProvider.notifier).preemptIfLowTtl();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(sc.swapControllerProvider);
    final controller = ref.read(sc.swapControllerProvider.notifier);
    final quote = state.currentQuote?.quote;
    final status = state.status;

    final isFetching = status == sc.QuoteStatus.fetching;
    final isRefreshing = status == sc.QuoteStatus.refreshing;
    final isStale = status == sc.QuoteStatus.stale;
    final canConfirm =
        status == sc.QuoteStatus.valid &&
        !_isConfirming &&
        !state.loading &&
        quote != null;

    final millisecondsRemaining =
        state.millisecondsRemaining ?? state.ttlMilliseconds;

    return PlatformSafeArea(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(),
              const SizedBox(height: 16),
              _Header(t: t),
              const SizedBox(height: 20),
              AnimatedOpacity(
                opacity: isRefreshing ? 0.55 : 1.0,
                duration: const Duration(milliseconds: 220),
                child: Column(
                  children: [
                    SwapDealCard(
                      sendAsset:
                          state.lastSendAssetId != null
                              ? core.Asset.fromId(state.lastSendAssetId!)
                              : core.Asset.btc,
                      sendAmountSats: state.lastAmount?.toInt(),
                      receiveAsset:
                          state.lastReceiveAssetId != null
                              ? core.Asset.fromId(state.lastReceiveAssetId!)
                              : core.Asset.usdt,
                      receiveAmountSats: state.receiveAmount,
                      isLoadingReceive: isFetching,
                      sendLabel: t.swap_you_send,
                      receiveLabel: t.swap_you_receive,
                    ),
                    const SizedBox(height: 14),
                    _ExchangeRateRow(state: state, t: t),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final alpha =
                      theme.brightness == Brightness.dark ? 0.45 : 0.4;
                  return Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: alpha),
                  );
                },
              ),
              const SizedBox(height: 4),
              _FeesSection(
                state: state,
                quote: quote,
                isLoadingQuote: isFetching,
                expanded: _feesExpanded,
                onToggle: () => setState(() => _feesExpanded = !_feesExpanded),
                t: t,
              ),
              if (isStale) ...[
                const SizedBox(height: 14),
                _StaleBanner(t: t, onRetry: controller.requestFreshQuote),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 14),
                _ErrorCard(
                  message: state.error!.localize(context),
                  onRetry: controller.requestFreshQuote,
                  t: t,
                ),
              ],
              const SizedBox(height: 12),
              _ExpirationIndicator(
                remainingMs: millisecondsRemaining,
                totalMs: state.ttlMilliseconds,
                showShimmer: isFetching || isRefreshing,
                onTap: controller.requestFreshQuote,
                t: t,
              ),
              const SizedBox(height: 12),
              SlideToConfirmButton(
                text:
                    _isConfirming || state.loading
                        ? t.common_confirming
                        : t.swap_confirm_title,
                isLoading: _isConfirming || state.loading || isFetching,
                onSlideComplete:
                    canConfirm
                        ? () => _confirmSwap(context, controller)
                        : () {},
              ),
              const SizedBox(height: 14),
              _PoweredBy(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSwap(
    BuildContext context,
    sc.SwapController controller,
  ) async {
    setState(() => _isConfirming = true);

    final currentState = ref.read(sc.swapControllerProvider);
    final sendId = currentState.lastSendAssetId;
    final receiveId = currentState.lastReceiveAssetId;
    final sendAmount = currentState.sendAmount;
    final receiveAmount = currentState.receiveAmount;

    try {
      final result = await controller.confirmSwap();
      if (!mounted) return;
      result.match(
        (err) {
          Navigator.of(context).pop();
          widget.onError?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.localize(context)),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        },
        (txid) {
          Navigator.of(context).pop();

          Future<void>.microtask(() async {
            try {
              final useCase = await ref.read(refreshWalletProvider.future);
              await useCase(strategy: SyncStrategy.light);
            } catch (_) {
              // Swallowed by design.
            }
          });

          widget.onSuccess?.call();

          final sendAsset =
              sendId != null ? core.Asset.fromId(sendId) : core.Asset.btc;
          final receiveAsset =
              receiveId != null
                  ? core.Asset.fromId(receiveId)
                  : core.Asset.usdt;

          if (sendAmount != null && receiveAmount != null) {
            final amountSent = sendAmount.toDouble() / 100000000;
            final amountReceived = receiveAmount.toDouble() / 100000000;
            SwapSuccessScreen.show(
              context,
              fromAsset: sendAsset,
              toAsset: receiveAsset,
              amountSent: amountSent,
              amountReceived: amountReceived,
              txid: txid,
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppLocalizations t;
  const _Header({required this.t});

  @override
  Widget build(BuildContext context) {
    return Text(
      t.swap_confirm_title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Timer chip — tone escalates with remaining time, tap to refresh
// ─────────────────────────────────────────────────────────────────────

/// Minimal expiration indicator: small circular progress ring that fills
/// up as the quote's TTL drains, alongside a tone-colored "expires in Ns"
/// label. The whole row is tappable to manually refresh the quote.
class _ExpirationIndicator extends StatelessWidget {
  final int? remainingMs;
  final int? totalMs;
  final bool showShimmer;
  final Future<void> Function() onTap;
  final AppLocalizations t;

  const _ExpirationIndicator({
    required this.remainingMs,
    required this.totalMs,
    required this.showShimmer,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(
      remainingMs,
      theme.colorScheme,
      context.appColors.warning,
    );

    // Fills up as time runs out: 0.0 at the start of the cycle,
    // approaching 1.0 at expiry.
    final progress =
        (remainingMs == null || totalMs == null || totalMs == 0)
            ? null
            : (1.0 - (remainingMs! / totalMs!)).clamp(0.0, 1.0);

    final isLoading = showShimmer || remainingMs == null;
    final seconds = ((remainingMs ?? 0) / 1000).ceil();

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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: isLoading ? null : progress,
                    strokeWidth: 2,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoading)
                  Text(
                    t.swap_quote_refreshing,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    t.swap_expires_in(seconds),
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

  /// Tone color derives from theme tokens so both light and dark themes
  /// pick up appropriate contrast levels:
  /// - success      → [ColorScheme.tertiary]
  /// - warning      → [AppExtraColors.warning]
  /// - urgent / red → [ColorScheme.error]
  static Color _toneColor(int? remainingMs, ColorScheme cs, Color warning) {
    final r = remainingMs ?? 0;
    if (r >= 10000) return cs.tertiary;
    if (r >= 5000) return warning;
    return cs.error;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Exchange-rate row
// ─────────────────────────────────────────────────────────────────────

class _ExchangeRateRow extends StatelessWidget {
  final sc.SwapState state;
  final AppLocalizations t;

  const _ExchangeRateRow({required this.state, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sendId = state.lastSendAssetId;
    final receiveId = state.lastReceiveAssetId;
    final rate = state.exchangeRate;

    if (sendId == null || receiveId == null || rate == null) {
      return const SizedBox.shrink();
    }
    final sendAsset = core.Asset.fromId(sendId);
    final receiveAsset = core.Asset.fromId(receiveId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swap_horiz, size: 14, color: context.colors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '${t.swap_rate_label} · ${t.swap_rate_line(sendAsset.ticker, _formatRate(rate), receiveAsset.ticker)}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  static String _formatRate(double rate) {
    if (rate == 0) return '0';
    if (rate < 0.0001) return rate.toStringAsFixed(8);
    if (rate < 1) return rate.toStringAsFixed(6);
    return rate.toStringAsFixed(4);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Fees — one row by default, tap to expand breakdown
// ─────────────────────────────────────────────────────────────────────

class _FeesSection extends StatelessWidget {
  final sc.SwapState state;
  final SideswapQuote? quote;
  final bool isLoadingQuote;
  final bool expanded;
  final VoidCallback onToggle;
  final AppLocalizations t;

  const _FeesSection({
    required this.state,
    required this.quote,
    required this.isLoadingQuote,
    required this.expanded,
    required this.onToggle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLabel = t.swap_confirm_total_fees_short;

    final Widget totalValue;
    if (isLoadingQuote || quote == null) {
      totalValue = _ShimmerBlock(width: 80, height: 16);
    } else {
      final q = quote!;
      totalValue = Text(
        _formatFee(context, state, q.serverFee + q.fixedFee),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isLoadingQuote || quote == null) ? null : onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  totalValue,
                  const SizedBox(width: 4),
                  if (quote != null)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child:
                    (expanded && quote != null)
                        ? Padding(
                          padding: const EdgeInsets.only(top: 10, left: 24),
                          child: Column(
                            children: [
                              _SubFeeRow(
                                label: t.swap_confirm_server_fee,
                                value: _formatFee(
                                  context,
                                  state,
                                  quote!.serverFee,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _SubFeeRow(
                                label: t.swap_confirm_fixed_fee,
                                value: _formatFee(
                                  context,
                                  state,
                                  quote!.fixedFee,
                                ),
                              ),
                            ],
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubFeeRow extends StatelessWidget {
  final String label;
  final String value;
  const _SubFeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Stale-quote banner + error card — both surface an explicit retry
// ─────────────────────────────────────────────────────────────────────

class _StaleBanner extends StatelessWidget {
  final AppLocalizations t;
  final Future<void> Function() onRetry;

  const _StaleBanner({required this.t, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = context.appColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.swap_quote_outdated_title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.swap_quote_outdated_body,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => onRetry(),
            style: TextButton.styleFrom(
              foregroundColor: warning,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(t.swap_refresh_action),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final AppLocalizations t;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: error),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => onRetry(),
            style: TextButton.styleFrom(
              foregroundColor: error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(t.common_retry),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Footer + shimmer block
// ─────────────────────────────────────────────────────────────────────

class _PoweredBy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Powered by sideswap.io',
      style: theme.textTheme.labelSmall?.copyWith(
        color: context.colors.textTertiary,
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final base = context.colors.baseColor;
    final highlight = context.colors.highlightColor;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Locale + fee formatting
//
// Asset-native amount formatting and unit suffixes live on the Asset
// enum itself (`Asset.formatAmount` / `Asset.displayUnit`) so display
// rules are centralized. This file only owns the bottom-sheet–specific
// composition: locale resolution + the fee row's lowercase "sats" style.
// ─────────────────────────────────────────────────────────────────────

/// Resolves the active app locale in the `intl`-compatible underscore
/// form (`pt_BR`, `en_US`). `Locale.toString()` already produces this
/// shape; we avoid `Intl.getCurrentLocale()` because that returns the
/// package default (`en_US`) unless someone called `Intl.defaultLocale = …`.
String _localeStringFor(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// Formats a fee value. Bitcoin-flavored fees get the lowercase "sats"
/// presentation used by financial UIs; token-flavored fees fall through
/// to the asset's native formatting + ticker.
String _formatFee(BuildContext context, sc.SwapState state, int feeSats) {
  final feeId = state.feeAssetId;
  final asset = feeId != null ? core.Asset.fromId(feeId) : core.Asset.btc;
  final locale = _localeStringFor(context);
  if (asset == core.Asset.btc || asset == core.Asset.lbtc) {
    return '${NumberFormat('#,##0', locale).format(feeSats)} sats';
  }
  return '${asset.formatAmount(feeSats, locale: locale)} ${asset.ticker}';
}
