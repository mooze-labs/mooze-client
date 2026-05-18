import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/swap_controller.dart' as sc;
import 'package:mooze_mobile/features/swap/data/models.dart' show SideswapQuote;
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/info_row.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../screens/swap_success_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class ConfirmSwapBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ConfirmSwapBottomSheet({super.key, this.onSuccess, this.onError});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              ConfirmSwapBottomSheet(onSuccess: onSuccess, onError: onError),
    );
  }

  @override
  ConsumerState<ConfirmSwapBottomSheet> createState() =>
      _ConfirmSwapBottomSheetState();
}

class _ConfirmSwapBottomSheetState
    extends ConsumerState<ConfirmSwapBottomSheet> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(sc.swapControllerProvider);
    final controller = ref.read(sc.swapControllerProvider.notifier);
    final quote = state.currentQuote?.quote;
    final millisecondsRemaining =
        state.millisecondsRemaining ?? state.ttlMilliseconds;
    final isLoadingQuote = quote == null;

    return PlatformSafeArea(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.swap_confirm_title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Center(
              child: _TimerChip(
                millisecondsRemaining: millisecondsRemaining,
                isLoading: isLoadingQuote,
                formatted:
                    millisecondsRemaining != null
                        ? _formatDuration(millisecondsRemaining)
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            _fromToSummary(context, state, isLoadingQuote),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  state.error!.localize(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _feesSection(context, state, quote, isLoadingQuote, t),
            const SizedBox(height: 24),
            SlideToConfirmButton(
              text:
                  _isConfirming || state.loading
                      ? t.common_confirming
                      : t.swap_confirm_title,
              isLoading: _isConfirming || state.loading || isLoadingQuote,
              onSlideComplete:
                  _isConfirming || state.loading || isLoadingQuote
                      ? () {}
                      : () => _confirmSwap(context, controller),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _feesSection(
    BuildContext context,
    sc.SwapState state,
    SideswapQuote? quote,
    bool isLoadingQuote,
    AppLocalizations t,
  ) {
    if (isLoadingQuote) {
      return Column(
        children: [
          const Divider(),
          const SizedBox(height: 4),
          ShimmerInfoRow(label: t.swap_confirm_server_fee, shimmerWidth: 90),
          const SizedBox(height: 6),
          ShimmerInfoRow(label: t.swap_confirm_fixed_fee, shimmerWidth: 80),
          const SizedBox(height: 6),
          ShimmerInfoRow(
            label: t.swap_confirm_total_fees_short,
            labelFontWeight: FontWeight.w600,
            shimmerWidth: 100,
          ),
        ],
      );
    }

    final q = quote!;
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 4),
        InfoRow(
          label: t.swap_confirm_server_fee,
          value: _formatFee(state, q.serverFee),
        ),
        const SizedBox(height: 6),
        InfoRow(
          label: t.swap_confirm_fixed_fee,
          value: _formatFee(state, q.fixedFee),
        ),
        const SizedBox(height: 6),
        InfoRow(
          label: t.swap_confirm_total_fees_short,
          value: _formatFee(state, q.serverFee + q.fixedFee),
          valueFontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  String _formatFee(sc.SwapState state, int feeSats) {
    final feeId = state.feeAssetId;
    final asset = feeId != null ? core.Asset.fromId(feeId) : core.Asset.btc;
    if (asset == core.Asset.btc || asset == core.Asset.lbtc) {
      return '$feeSats SATS';
    } else {
      final value = feeSats / 100000000;
      return '${value.toStringAsFixed(4)} ${asset.ticker}';
    }
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

  String _formatDuration(int millis) {
    if (millis <= 0) return '00:00';
    final totalSeconds = (millis / 1000).ceil();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _fromToSummary(
    BuildContext context,
    sc.SwapState state,
    bool isLoadingQuote,
  ) {
    final t = AppLocalizations.of(context);
    final sendId = state.lastSendAssetId;
    final receiveId = state.lastReceiveAssetId;
    final sendAsset =
        sendId != null ? core.Asset.fromId(sendId) : core.Asset.btc;
    final receiveAsset =
        receiveId != null ? core.Asset.fromId(receiveId) : core.Asset.usdt;

    String formatAmount(int amountSats) {
      final v = amountSats.toDouble() / 100000000;
      return v.toStringAsFixed(8);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerLowest,
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SummaryColumn(
                  label: t.swap_you_send,
                  asset: sendAsset,
                  amount:
                      state.lastAmount != null
                          ? formatAmount(state.lastAmount!.toInt())
                          : '0',
                  showShimmer: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/menu/arrow.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              Expanded(
                child: _SummaryColumn(
                  label: t.swap_you_receive,
                  asset: receiveAsset,
                  amount:
                      state.receiveAmount != null
                          ? formatAmount(state.receiveAmount!)
                          : '0',
                  showShimmer: isLoadingQuote || state.receiveAmount == null,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final core.Asset asset;
  final String amount;
  final bool showShimmer;
  final bool alignEnd;

  const _SummaryColumn({
    required this.label,
    required this.asset,
    required this.amount,
    required this.showShimmer,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cross = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    final labelRowChildren = <Widget>[
      Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      const SizedBox(width: 8),
      SvgPicture.asset(asset.iconPath, width: 15, height: 15),
    ];

    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignEnd
              ? labelRowChildren.reversed.toList()
              : labelRowChildren,
        ),
        const SizedBox(height: 6),
        showShimmer
            ? _ShimmerBlock(width: 96, height: 18)
            : Text(
                amount,
                textAlign: textAlign,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
        const SizedBox(height: 2),
        Text(
          asset.name.toLowerCase(),
          textAlign: textAlign,
          style: textTheme.labelSmall?.copyWith(
            color: context.colors.textTertiary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  final int? millisecondsRemaining;
  final bool isLoading;
  final String? formatted;

  const _TimerChip({
    required this.millisecondsRemaining,
    required this.isLoading,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: primary),
          const SizedBox(width: 6),
          if (isLoading || formatted == null)
            const _ShimmerBlock(width: 44, height: 14)
          else
            Text(
              formatted!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
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
