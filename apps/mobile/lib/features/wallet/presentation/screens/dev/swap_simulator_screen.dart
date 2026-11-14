import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_qr_loading_overlay.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_success_screen.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/transaction_sent_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/converting_completed_view.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/values_to_receive_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';

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
/// It also opens the screens that only real events show, with sample
/// data: the confirmation of a received transaction and the end of a send
/// for each asset, the end of a peg-in and a peg-out, a level up, a level
/// down, the pending DePix receipts of the holdings screen, and the scene
/// that covers a screen while a Pix QR code is created.
///
/// Route: `/dev/swap-simulator` (registered in `walletRoutes`).
class SwapSimulatorScreen extends ConsumerStatefulWidget {
  const SwapSimulatorScreen({super.key});

  /// How long the live peg preview waits before its credit lands.
  static const pegLiveWait = Duration(seconds: 4);

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
          _SectionHeader('Preview screens'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // A new ID each time, so the entrance plays again.
              for (final (asset, amount) in [
                (Asset.btc, 25400),
                (Asset.lbtc, 25400),
                (Asset.depix, 15000000000),
                (Asset.usdt, 2550000000),
              ])
                OutlinedButton.icon(
                  onPressed: () => TransactionConfirmedScreen.show(
                    context,
                    asset: asset,
                    amount: BigInt.from(amount),
                    transactionId: _fakeLeg64(
                      'c',
                      DateTime.now().microsecondsSinceEpoch,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Received ${asset.ticker}'),
                ),
              // The end of a send to a sample destination. Its button closes
              // the preview: it neither clears the send form nor goes home.
              for (final (asset, amount) in [
                (Asset.btc, 25400),
                (Asset.lbtc, 25400),
                (Asset.depix, 15000000000),
                (Asset.usdt, 2550000000),
              ])
                OutlinedButton.icon(
                  onPressed: () => TransactionSentScreen.show(
                    context,
                    asset: asset,
                    amount: BigInt.from(amount),
                    destinationAddress: _sampleAddress(asset),
                    transactionId: _fakeLeg64(
                      'e',
                      DateTime.now().microsecondsSinceEpoch,
                    ),
                    onDone: () => Navigator.of(context).pop(),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: Text('Sent ${asset.ticker}'),
                ),
              // The end of a swap: the coin of the sent asset turns into
              // the coin of the received one. Nothing is sent.
              for (final (from, to, sent, received) in [
                (Asset.depix, Asset.lbtc, 500.0, 0.001135),
                (Asset.lbtc, Asset.usdt, 0.0005, 48.72),
                (Asset.usdt, Asset.depix, 20.0, 108.4),
                (Asset.btc, Asset.lbtc, 0.001, 0.000998),
                (Asset.lbtc, Asset.btc, 0.001, 0.000995),
              ])
                OutlinedButton.icon(
                  onPressed: () => SwapSuccessScreen.show(
                    context,
                    fromAsset: from,
                    toAsset: to,
                    amountSent: sent,
                    amountReceived: received,
                    txid: _fakeLeg64(
                      's',
                      DateTime.now().microsecondsSinceEpoch,
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text('Swap ${from.ticker} → ${to.ticker}'),
                ),
              // The end of a peg, as its details show it once its credit
              // lands. Its button closes the preview.
              for (final (from, to) in _pegs)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (route) => ConvertingCompletedView(
                        fromAsset: from,
                        toAsset: to,
                        onDone: () => Navigator.of(route).pop(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.currency_exchange),
                  label: Text('Peg done ${from.ticker} → ${to.ticker}'),
                ),
              // The same end, live: the details of a fake peg open, and its
              // credit lands a few seconds later.
              for (final (from, to) in _pegs)
                OutlinedButton.icon(
                  onPressed: () => _previewPegLive(from, to),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text('Peg live ${from.ticker} → ${to.ticker}'),
                ),
              // Every medal, up and down.
              for (final (from, to) in [
                (0, 1),
                (1, 2),
                (2, 3),
                (3, 2),
                (2, 1),
                (1, 0),
              ])
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/level-${to > from ? 'upgrade' : 'downgrade'}'
                    '?oldLevel=$from&newLevel=$to',
                  ),
                  icon: Icon(
                    to > from ? Icons.trending_up : Icons.trending_down,
                  ),
                  label: Text(
                    'Level ${to > from ? 'up' : 'down'} → '
                    '${const ['Bronze', 'Silver', 'Gold', 'Diamond'][to]}',
                  ),
                ),
              // The preview closes at the end: it neither marks the
              // onboarding as done nor opens the wallet setup.
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (route) => OnboardingScreen(
                      onDone: () => Navigator.of(route).pop(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Onboarding'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _PendingReceiptsPreview(),
                  ),
                ),
                icon: const Icon(Icons.hourglass_bottom),
                label: const Text('Pending DePix receipts'),
              ),
              // The scene that covers a screen while a Pix QR code is
              // created, ended as a request would end it. Nothing is
              // charged.
              for (final (label, wait, created) in [
                ('Pix QR: created', const Duration(milliseconds: 2500), true),
                ('Pix QR: slow', const Duration(seconds: 17), true),
                ('Pix QR: failed', const Duration(seconds: 2), false),
              ])
                OutlinedButton.icon(
                  onPressed: () =>
                      _previewQrLoading(wait: wait, created: created),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(label),
                ),
            ],
          ),
          const SizedBox(height: 24),
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

  /// Covers the simulator with the scene of a Pix QR code being created,
  /// then ends it after [wait]: with a sample charge when [created], else
  /// with an error.
  Future<void> _previewQrLoading({
    required Duration wait,
    required bool created,
  }) async {
    final loading = PixQrLoadingOverlay.show(
      context,
      text: AppLocalizations.of(context).pix_generating_qr,
    );
    await Future<void>.delayed(wait);
    if (!mounted) {
      loading.cancel();
      return;
    }
    if (created) {
      loading.succeed(
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _SampleChargePreview()),
        ),
      );
    } else {
      loading.fail();
      AppSnackBar.error(context, 'Simulated failure');
    }
  }

  /// The two pegs: in, then out.
  static const _pegs = [(Asset.btc, Asset.lbtc), (Asset.lbtc, Asset.btc)];

  /// Starts a fake peg from [from] to [to], opens its details, and retires
  /// it after [SwapSimulatorScreen.pegLiveWait], as the reconciler does
  /// when its credit lands: the details then turn into their completed
  /// view. Nothing is sent.
  void _previewPegLive(Asset from, Asset to) {
    final notifier = ref.read(pendingSwapsProvider.notifier);
    final localId = notifier.start(
      fromAsset: from,
      toAsset: to,
      sentAmount: BigInt.from(28000),
      estimatedReceivedAmount: BigInt.from(27440),
    );
    notifier.markBroadcasted(
      localId,
      breezSwapId: 'fakeSwap_$localId',
      breezTxId: _fakeLeg64('a', localId.hashCode),
    );
    context.push('/swap/converting/$localId');
    Timer(SwapSimulatorScreen.pegLiveWait, () => notifier.clear(localId));
  }

  /// A destination on the network of [asset], for the previews. It is not
  /// a real address.
  String _sampleAddress(Asset asset) =>
      asset == Asset.btc ? 'bc1q${'0' * 38}' : 'lq1qq${'0' * 75}';

  String _fakeLeg64(String prefix, int seed) {
    // Build a 64-char lowercase hex string so it passes the unifier's
    // "looks like a real txid" check if/when you let it flow through.
    final body = (seed.abs().toRadixString(16) * 16).substring(0, 63);
    return (prefix + body).padRight(64, '0').substring(0, 64);
  }
}

/// A sample charge with its QR code, where the Pix QR preview ends. The
/// code holds no payment.
class _SampleChargePreview extends StatelessWidget {
  const _SampleChargePreview();

  @override
  Widget build(BuildContext context) {
    return const BackdropPageScaffold(
      title: 'Sample charge',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(BackdropPageScaffold.gutter),
        child: PixQrPanel(data: 'mooze-preview-sample-charge'),
      ),
    );
  }
}

/// The pending DePix card of the holdings screen with two sample payments,
/// on the app backdrop.
class _PendingReceiptsPreview extends StatelessWidget {
  const _PendingReceiptsPreview();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        valuesToReceiveProvider.overrideWith(
          (ref) async => right(const [
            AssetToReceive(
              asset: Asset.depix,
              valueInCents: 5000,
              formattedValue: 'R\$ 50,00',
              displayValue: 50,
            ),
            AssetToReceive(
              asset: Asset.depix,
              valueInCents: 12990,
              formattedValue: 'R\$ 129,90',
              displayValue: 129.9,
            ),
          ]),
        ),
        totalValueToReceiveProvider.overrideWith((ref) async => 179.9),
      ],
      child: const BackdropPageScaffold(
        title: 'Pending DePix receipts',
        body: SingleChildScrollView(
          padding: EdgeInsets.all(BackdropPageScaffold.gutter),
          child: ValuesToReceiveCard(),
        ),
      ),
    );
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
