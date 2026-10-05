import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';

/// Dev-only playground for driving the optimistic peg-in / peg-out
/// row through every state without spending sats on a real Boltz
/// chain swap.
///
/// What you can do here:
///   - Start a fake peg-in or peg-out with a chosen amount.
///   - Step the phase: preparing → broadcasting → broadcasted → failed.
///   - Inject a synthetic destination credit (LBTC receive for peg-in,
///     BTC receive for peg-out) into `reconcileWith` so you can verify
///     the optimistic row actually retires when the reconciler sees it.
///   - Clear individual rows or wipe the whole pending state.
///
/// Route: `/dev/swap-simulator` (registered in `walletRoutes`).
class SwapSimulatorScreen extends ConsumerStatefulWidget {
  const SwapSimulatorScreen({super.key});

  @override
  ConsumerState<SwapSimulatorScreen> createState() =>
      _SwapSimulatorScreenState();
}

class _SwapSimulatorScreenState extends ConsumerState<SwapSimulatorScreen> {
  final _amountCtl = TextEditingController(text: '28000');

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingSwaps = ref.watch(pendingSwapsProvider);
    final notifier = ref.read(pendingSwapsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap simulator (dev)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Start a fake swap'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sent amount (sats)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _start(notifier, isPegIn: true),
                  icon: const Icon(Icons.south_west),
                  label: const Text('Peg-in (BTC → LBTC)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _start(notifier, isPegIn: false),
                  icon: const Icon(Icons.north_east),
                  label: const Text('Peg-out (LBTC → BTC)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Active pending swaps (${pendingSwaps.length})'),
          const SizedBox(height: 8),
          if (pendingSwaps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No active pending swaps. Start one above to see it appear '
                'in the home transaction list.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...pendingSwaps.map(
              (s) => _PendingSwapTile(
                swap: s,
                onMarkBroadcasting: () => notifier.markBroadcasting(s.localId),
                onMarkBroadcasted: () => notifier.markBroadcasted(
                  s.localId,
                  breezSwapId: 'fakeSwap_${s.localId}',
                  breezTxId: _fakeLeg64('a', s.localId.hashCode),
                ),
                onMarkFailed: () => notifier.markFailed(
                  s.localId,
                  error: 'Simulated failure',
                ),
                onSimulateDestCredit: () =>
                    _simulateDestinationCredit(notifier, s),
                onMarkRefundable: () => notifier.markRefundable(
                  s.localId,
                  swapAddress: 'simulated_swap_${s.localId}',
                ),
                onClear: () => notifier.clear(s.localId),
              ),
            ),
          if (pendingSwaps.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                for (final s in pendingSwaps) {
                  notifier.clear(s.localId);
                }
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Wipe all'),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const _SectionHeader('How this works'),
          const SizedBox(height: 8),
          const Text(
            '• "Start" inserts a pending row into the in-memory store '
            'exactly the way the real swap helper does it. The home '
            'transaction list will pick it up immediately.\n\n'
            '• "Mark broadcasting / broadcasted" drives the phase '
            'transitions you\'d see during a real Breez SDK call.\n\n'
            '• "Simulate destination credit" hands a synthetic receive '
            'transaction (LBTC for peg-in, BTC for peg-out) to '
            '`reconcileWith` — this is what retires the optimistic row '
            'in production.\n\n'
            '• "Mark failed" flips the row to the red error state. It '
            'auto-evicts after a few seconds.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _start(PendingSwapsNotifier notifier, {required bool isPegIn}) {
    final amount = int.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.warning(context, 'Enter a positive amount in sats');
      return;
    }
    notifier.start(
      fromAsset: isPegIn ? Asset.btc : Asset.lbtc,
      toAsset: isPegIn ? Asset.lbtc : Asset.btc,
      sentAmount: BigInt.from(amount),
      // Mimic a ~2% chain-swap fee so the rendered estimated-receive
      // amount looks realistic.
      estimatedReceivedAmount: BigInt.from((amount * 0.98).round()),
    );
  }

  void _simulateDestinationCredit(
    PendingSwapsNotifier notifier,
    PendingSwap swap,
  ) {
    // Build a synthetic receive of the destination asset on its rail,
    // dated just after the optimistic was created so it passes the
    // "must be after pending" guard the reconciler enforces.
    final synthetic = Transaction(
      id: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
      amount: swap.estimatedReceivedAmount,
      blockchain:
          swap.isPegIn ? Blockchain.liquid : Blockchain.bitcoin,
      asset: swap.toAsset,
      type: TransactionType.receive,
      status: TransactionStatus.pending,
      createdAt: swap.createdAt.add(const Duration(seconds: 30)),
    );
    // Pass it through the same matcher production uses. If the rules
    // line up, the optimistic row should disappear from the home list.
    notifier.reconcileWith([synthetic]);
  }

  String _fakeLeg64(String prefix, int seed) {
    // Build a 64-char lowercase hex string so it passes the unifier's
    // "looks like a real txid" check if/when you let it flow through.
    final body = (seed.abs().toRadixString(16) * 16).substring(0, 63);
    return (prefix + body).padRight(64, '0').substring(0, 64);
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PendingSwapTile extends StatelessWidget {
  final PendingSwap swap;
  final VoidCallback onMarkBroadcasting;
  final VoidCallback onMarkBroadcasted;
  final VoidCallback onMarkFailed;
  final VoidCallback onSimulateDestCredit;
  final VoidCallback onMarkRefundable;
  final VoidCallback onClear;

  const _PendingSwapTile({
    required this.swap,
    required this.onMarkBroadcasting,
    required this.onMarkBroadcasted,
    required this.onMarkFailed,
    required this.onSimulateDestCredit,
    required this.onMarkRefundable,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${swap.fromAsset.ticker} → ${swap.toAsset.ticker}'
                    '  ·  ${swap.sentAmount} sats',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(swap.phase.name),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'localId: ${swap.localId}\n'
              'breezSwapId: ${swap.breezSwapId ?? "(none)"}\n'
              'breezTxId: ${swap.breezTxId ?? "(none)"}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (swap.phase == PendingSwapPhase.preparing)
                  OutlinedButton(
                    onPressed: onMarkBroadcasting,
                    child: const Text('→ broadcasting'),
                  ),
                if (swap.phase == PendingSwapPhase.preparing ||
                    swap.phase == PendingSwapPhase.broadcasting)
                  OutlinedButton(
                    onPressed: onMarkBroadcasted,
                    child: const Text('→ broadcasted'),
                  ),
                if (swap.phase != PendingSwapPhase.failed &&
                    swap.phase != PendingSwapPhase.refundable)
                  OutlinedButton(
                    onPressed: onMarkRefundable,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                    ),
                    child: const Text('→ refundable'),
                  ),
                if (swap.phase != PendingSwapPhase.failed)
                  OutlinedButton(
                    onPressed: onMarkFailed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('→ failed'),
                  ),
                FilledButton.tonal(
                  onPressed: onSimulateDestCredit,
                  child: const Text('Simulate dest. credit (retire)'),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
