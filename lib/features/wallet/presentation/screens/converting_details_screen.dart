import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Detail surface for an in-progress peg-in / peg-out.
///
/// Reads the optimistic swap from [pendingSwapsProvider] by [localId]
/// and updates live as the notifier walks through its phase machine.
/// If the swap is reconciled or cleared while this screen is open,
/// the body switches to a "Completed" panel pointing the user back
/// home, where the unified swap row in the transaction list takes
/// over the narrative.
class ConvertingDetailsScreen extends ConsumerWidget {
  final String localId;

  const ConvertingDetailsScreen({super.key, required this.localId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swap = ref.watch(
      pendingSwapsProvider.select(
        (list) => list.where((s) => s.localId == localId).firstOrNull,
      ),
    );

    return PlatformSafeArea(
      child: Scaffold(
        backgroundColor: context.colors.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Conversion in progress'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: swap == null ? const _CompletedView() : _ActiveView(swap: swap),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  final PendingSwap swap;
  const _ActiveView({required this.swap});

  @override
  Widget build(BuildContext context) {
    // Refundable swaps suppress the "in progress" affordances
    // (timeline + animated explanation) and surface a refund CTA in
    // their place. The user's next action is no longer "wait" but
    // "claim", and the screen should reflect that.
    final isRefundable = swap.phase == PendingSwapPhase.refundable;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(swap: swap),
          const SizedBox(height: 16),
          if (isRefundable) ...[
            _RefundCallout(swap: swap),
            const SizedBox(height: 16),
          ] else ...[
            _PhaseTimeline(phase: swap.phase),
            const SizedBox(height: 16),
            _PhaseExplanation(swap: swap),
            const SizedBox(height: 16),
          ],
          _DetailsCard(swap: swap),
          const SizedBox(height: 24),
          const _HelpFooter(),
        ],
      ),
    );
  }
}

class _RefundCallout extends StatelessWidget {
  final PendingSwap swap;
  const _RefundCallout({required this.swap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.assignment_return,
                color: Colors.orangeAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Swap could not complete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Boltz flagged this swap as refundable. Your funds are '
            'safe — claim them back to your wallet using the refund '
            'flow below.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.south_east),
              label: const Text('Get refund'),
              onPressed: () => context.push('/transactions/refund'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.greenAccent[400]),
          const SizedBox(height: 16),
          Text(
            'Conversion completed',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'The funds have arrived on the destination chain. The full '
            'swap is now visible in your transaction history.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PendingSwap swap;
  const _HeaderCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    final isFailed = swap.phase == PendingSwapPhase.failed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DualAssetIcon(from: swap.fromAsset, to: swap.toAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Converting ${swap.fromAsset.ticker} → '
                      '${swap.toAsset.ticker}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      swap.isPegIn ? 'Peg-in' : 'Peg-out',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              _StatusBadge(phase: swap.phase),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _AmountColumn(
                    label: 'You sent',
                    asset: swap.fromAsset,
                    amount: swap.sentAmount,
                    approximate: false,
                  ),
                ),
              ),

              Center(child: Icon(Icons.arrow_forward, color: Colors.grey)),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _AmountColumn(
                    label: 'You\'ll receive',
                    asset: swap.toAsset,
                    amount: swap.estimatedReceivedAmount,
                    approximate: true,
                  ),
                ),
              ),
            ],
          ),
          if (isFailed && swap.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      swap.errorMessage!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final Asset asset;
  final BigInt amount;
  final bool approximate;

  const _AmountColumn({
    required this.label,
    required this.asset,
    required this.amount,
    required this.approximate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(
          '${approximate ? '~' : ''}${_formatAmount(asset, amount)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PendingSwapPhase phase;
  const _StatusBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (phase == PendingSwapPhase.failed) {
      color = Colors.redAccent;
    } else if (phase == PendingSwapPhase.refundable) {
      color = Colors.orangeAccent;
    } else {
      color = context.colors.primaryColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _phaseLabel(phase),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PhaseTimeline extends StatelessWidget {
  final PendingSwapPhase phase;
  const _PhaseTimeline({required this.phase});

  static const _steps = [
    (PendingSwapPhase.preparing, 'Preparing'),
    (PendingSwapPhase.broadcasting, 'Broadcasting'),
    (PendingSwapPhase.broadcasted, 'Awaiting confirmations'),
  ];

  @override
  Widget build(BuildContext context) {
    final isFailed = phase == PendingSwapPhase.failed;
    final currentIndex = _steps.indexWhere((s) => s.$1 == phase);
    final activeColor = context.colors.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _steps.length; i++)
            _TimelineRow(
              label: _steps[i].$2,
              isDone: !isFailed && (currentIndex > i || currentIndex == -1),
              isCurrent: !isFailed && currentIndex == i,
              isLast: i == _steps.length - 1,
              isFailed: isFailed,
              activeColor: activeColor,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final bool isFailed;
  final Color activeColor;

  const _TimelineRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.isFailed,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isFailed
            ? Colors.redAccent
            : (isDone || isCurrent ? activeColor : Colors.grey);
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child:
                    isDone
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : (isCurrent
                            ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            : null),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: color.withValues(alpha: 0.4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isCurrent ? color : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseExplanation extends StatelessWidget {
  final PendingSwap swap;
  const _PhaseExplanation({required this.swap});

  @override
  Widget build(BuildContext context) {
    final text = _explanation(swap);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: context.colors.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends ConsumerWidget {
  final PendingSwap swap;
  const _DetailsCard({required this.swap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Direction',
            value:
                swap.isPegIn
                    ? 'Peg-in (BTC on-chain → LBTC)'
                    : 'Peg-out (LBTC → BTC on-chain)',
          ),
          _DetailRow(
            label: 'Sent',
            value: _formatAmount(swap.fromAsset, swap.sentAmount),
          ),
          _DetailRow(
            label: 'Estimated receive',
            value:
                '~${_formatAmount(swap.toAsset, swap.estimatedReceivedAmount)}',
          ),
          _DetailRow(label: 'Started', value: dateFmt.format(swap.createdAt)),
          if (swap.destination != null)
            _DetailRow(
              label: 'Destination address',
              value: swap.destination!,
              copyable: true,
            ),
          if (swap.breezSwapId != null)
            _DetailRow(
              label: 'Swap ID',
              value: swap.breezSwapId!,
              copyable: true,
            ),
          if (swap.breezTxId != null)
            _DetailRow(
              label: swap.isPegIn ? 'Bitcoin send tx' : 'Liquid send tx',
              value: swap.breezTxId!,
              copyable: true,
              onTap: () => _openExplorer(swap),
              trailing: const Icon(Icons.open_in_new, size: 16),
            ),
          _DetailRow(label: 'Local ID', value: swap.localId, isLast: true),
        ],
      ),
    );
  }

  void _openExplorer(PendingSwap swap) {
    final txid = swap.breezTxId;
    if (txid == null) return;
    // Lockup tx lives on the SOURCE chain — BDK for peg-in, LWK for
    // peg-out. Blockstream Esplora covers both.
    final url =
        swap.isPegIn
            ? 'https://blockstream.info/tx/$txid'
            : 'https://blockstream.info/liquid/tx/$txid';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _DetailRow extends StatefulWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool isLast;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.isLast = false,
    this.onTap,
    this.trailing,
  });

  @override
  State<_DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<_DetailRow> {
  bool _justCopied = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ?? (widget.copyable ? _copy : null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border:
              widget.isLast
                  ? null
                  : Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            Expanded(
              child: Text(widget.value, style: const TextStyle(fontSize: 13)),
            ),
            if (widget.copyable && !_justCopied)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
            if (_justCopied)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check, size: 14, color: Colors.green),
              ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }
}

class _HelpFooter extends StatelessWidget {
  const _HelpFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Chain swaps move funds between Bitcoin and Liquid Bitcoin (L-BTC) '
        'and typically settle in 30 to 60 minutes after the lockup tx '
        'confirms. Your funds are not lost — they are temporarily locked '
        'in the swap contract while the destination chain catches up.',
        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
      ),
    );
  }
}

class _DualAssetIcon extends StatelessWidget {
  final Asset from;
  final Asset to;
  const _DualAssetIcon({required this.from, required this.to});

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
              child: SvgPicture.asset(from.iconPath, width: 31, height: 31),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.5),
              child: SvgPicture.asset(to.iconPath, width: 31, height: 31),
            ),
          ),
        ],
      ),
    );
  }
}

String _phaseLabel(PendingSwapPhase phase) {
  switch (phase) {
    case PendingSwapPhase.preparing:
      return 'Preparing';
    case PendingSwapPhase.broadcasting:
      return 'Broadcasting';
    case PendingSwapPhase.broadcasted:
      return 'Awaiting confirmations';
    case PendingSwapPhase.failed:
      return 'Failed';
    case PendingSwapPhase.refundable:
      return 'Refundable';
  }
}

String _explanation(PendingSwap swap) {
  switch (swap.phase) {
    case PendingSwapPhase.preparing:
      return 'Building the lockup transaction and reserving the swap '
          'with the chain-swap service.';
    case PendingSwapPhase.broadcasting:
      return 'Signing and broadcasting the lockup transaction to the '
          '${swap.isPegIn ? "Bitcoin" : "Liquid"} network.';
    case PendingSwapPhase.broadcasted:
      return swap.isPegIn
          ? 'Your Bitcoin lockup has been broadcast. Once it confirms, '
              'the chain-swap service will claim it and send LBTC to '
              'your wallet.'
          : 'Your LBTC has been sent to the chain-swap service. Once '
              'it processes, you\'ll receive BTC on the Bitcoin network.';
    case PendingSwapPhase.failed:
      return 'The swap could not be completed. Any funds reserved for '
          'the swap will be refunded automatically.';
    case PendingSwapPhase.refundable:
      return 'Boltz flagged the swap as refundable. Tap "Get refund" to '
          'send the locked funds back to your wallet.';
  }
}

String _formatAmount(Asset asset, BigInt amount) {
  if (asset == Asset.btc || asset == Asset.lbtc) {
    return asset.formatBalance(amount);
  }
  if (asset == Asset.usdt) {
    return '\$${(amount.toDouble() / 100000000).toStringAsFixed(2)}';
  }
  if (asset == Asset.depix) {
    return 'R\$${(amount.toDouble() / 100000000).toStringAsFixed(2)}';
  }
  return asset.formatBalance(amount);
}
