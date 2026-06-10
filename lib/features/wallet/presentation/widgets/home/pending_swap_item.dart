import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
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
    final subtitleColor =
        isFailed
            ? Colors.redAccent
            : (isRefundable ? Colors.orangeAccent : colors.primaryColor);
    // Refundable rows skip the converting screen and route straight
    // into the existing refund flow — the user's next step is to
    // claim, not to inspect.
    final route =
        isRefundable
            ? '/transactions/refund'
            : '/swap/converting/${swap.localId}';

    return GestureDetector(
      onTap: () => context.push(route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 5),
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
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFailed)
                        const Icon(
                          Icons.error_outline,
                          size: 12,
                          color: Colors.redAccent,
                        )
                      else if (isRefundable)
                        const Icon(
                          Icons.assignment_return,
                          size: 14,
                          color: Colors.orangeAccent,
                        )
                      else
                        _LiveDot(color: subtitleColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isFailed
                              ? (swap.errorMessage ??
                                  t.pending_swap_status_failed)
                              : _subtitle(t, swap.phase),
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
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
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          'assets/icons/menu/navigation/swap.svg',
                          width: 12,
                          height: 12,
                          colorFilter: ColorFilter.mode(
                            subtitleColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVisible
                              ? '•••••••'
                              : '~${_formatAmount(swap.toAsset, swap.estimatedReceivedAmount)}',
                          style: const TextStyle(fontSize: 12),
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
                      style: const TextStyle(fontSize: 12),
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
                Text(
                  _shortTime(swap.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
                if (isRefundable) ...[
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.orangeAccent,
                  ),
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
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.5),
              child: SvgPicture.asset(
                fromAsset.iconPath,
                width: 31,
                height: 31,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.5),
              child: SvgPicture.asset(toAsset.iconPath, width: 31, height: 31),
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

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
