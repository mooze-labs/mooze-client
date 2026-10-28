import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// In-progress peg-in / peg-out row. Visually mirrors the swap row in
/// [HomeTransactionItem] (two-asset icon overlay, sent/received
/// amounts, time on the right) but drives its subtitle off
/// [PendingSwap.phase] so the user gets continuous feedback while the
/// Breez SDK works through the chain swap.
class PendingSwapItem extends ConsumerWidget {
  final PendingSwap swap;

  const PendingSwapItem({super.key, required this.swap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = AppLocalizations.of(context);
    final isVisible = ref.watch(isVisibleProvider);
    final isFailed = swap.phase == PendingSwapPhase.failed;
    final isRefundable = swap.phase == PendingSwapPhase.refundable;
    // The icon and the live dot carry the status color. The status text
    // stays readable: on the panels, the brand pink and the error red fail
    // 4.5:1 as small text.
    final statusColor =
        isFailed
            ? context.colorScheme.error
            : (isRefundable ? context.appColors.warning : colors.primaryColor);
    final statusTextColor =
        isFailed ? context.colorScheme.onErrorContainer : colors.textSecondary;
    final secondaryStyle = context.textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final route = '/swap/converting/${swap.localId}';

    return InkWell(
      onTap: () => context.push(route),
      child: Container(
        color: Colors.transparent,
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _SwapIcon(fromAsset: swap.fromAsset, toAsset: swap.toAsset),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(t, swap),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isFailed)
                        Icon(Icons.error_outline, size: 12, color: statusColor)
                      else if (isRefundable)
                        Icon(
                          Icons.assignment_return,
                          size: 14,
                          color: statusColor,
                        )
                      else
                        _LiveDot(color: statusColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isFailed
                              ? (swap.errorMessage ??
                                  t.pending_swap_status_failed)
                              : _subtitle(t, swap.phase),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: statusTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!isRefundable) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isVisible
                              ? '•••••••'
                              : _formatAmount(swap.fromAsset, swap.sentAmount),
                          style: secondaryStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          'assets/icons/menu/navigation/swap.svg',
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(
                            statusColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVisible
                              ? '•••••••'
                              : '~${_formatAmount(swap.toAsset, swap.estimatedReceivedAmount)}',
                          style: secondaryStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      isVisible
                          ? '•••••••'
                          : t.pending_swap_refundable_amount(
                            _formatAmount(swap.fromAsset, swap.sentAmount),
                          ),
                      style: secondaryStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_shortTime(swap.createdAt), style: secondaryStyle),
                if (isRefundable) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 18, color: statusColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _title(AppLocalizations t, PendingSwap swap) {
  if (swap.phase == PendingSwapPhase.refundable) {
    return t.pending_swap_refund_available;
  }
  return t.converting_details_converting_label(
    swap.fromAsset.ticker,
    swap.toAsset.ticker,
  );
}

String _subtitle(AppLocalizations t, PendingSwapPhase phase) {
  switch (phase) {
    case PendingSwapPhase.preparing:
      return t.pending_swap_status_preparing;
    case PendingSwapPhase.broadcasting:
      return t.pending_swap_status_broadcasting;
    case PendingSwapPhase.broadcasted:
      return t.pending_swap_status_broadcasted;
    case PendingSwapPhase.failed:
      return t.pending_swap_status_failed;
    case PendingSwapPhase.refundable:
      return t.pending_swap_status_refundable;
  }
}

String _formatAmount(Asset asset, BigInt amount) {
  if (asset == Asset.btc || asset == Asset.lbtc) {
    return asset.formatBalance(amount);
  }
  if (asset == Asset.usdt) {
    final v = amount.toDouble() / 100000000;
    return '\$${v.toStringAsFixed(2)}';
  }
  if (asset == Asset.depix) {
    final v = amount.toDouble() / 100000000;
    return 'R\$${v.toStringAsFixed(2)}';
  }
  return asset.formatBalance(amount);
}

String _shortTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _SwapIcon extends StatelessWidget {
  final Asset fromAsset;
  final Asset toAsset;
  const _SwapIcon({required this.fromAsset, required this.toAsset});

  @override
  Widget build(BuildContext context) {
    // Same metrics as the swap icon of the transaction rows.
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: ClipOval(
              child: SvgPicture.asset(fromAsset.iconPath, width: 27, height: 27),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 1,
            child: ClipOval(
              child: SvgPicture.asset(toAsset.iconPath, width: 27, height: 27),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

/// The dot pulses while the swap runs: it shows live progress, like a
/// progress indicator. With reduced motion, it stays still.
class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: Motion.durationCelebrate,
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.isReduced(context)) _ctl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_ctl),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
