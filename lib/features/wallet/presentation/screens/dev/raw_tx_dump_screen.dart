import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart' as lwk;

import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2tx;
import 'package:mooze_mobile/infra/bdk/bitcoin_wallet_service_impl.dart'
    as bdk_impl;
import 'package:mooze_mobile/infra/breez/lightning_wallet_service_impl.dart'
    as breez_impl;
import 'package:mooze_mobile/infra/lwk/liquid_wallet_service_impl.dart'
    as lwk_impl;

/// Dev-only diagnostic surface that dumps the most recent transactions
/// straight out of each chain SDK plus the V2 transaction store. Use
/// this when the home tx list looks wrong — copy each section to a
/// chat and we can see *exactly* what the SDKs are giving us versus
/// how the unifier is collapsing them.
///
/// Route: `/dev/raw-tx-dump`. Compiled out of release builds via the
/// `kDebugMode` guard in `home_screen.dart`.
class RawTxDumpScreen extends ConsumerStatefulWidget {
  const RawTxDumpScreen({super.key});

  @override
  ConsumerState<RawTxDumpScreen> createState() => _RawTxDumpScreenState();
}

class _RawTxDumpScreenState extends ConsumerState<RawTxDumpScreen> {
  static const int _limit = 10;

  bool _loading = false;
  String? _error;
  String _bdkDump = '';
  String _lwkDump = '';
  String _breezDump = '';
  String _storeDump = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bdk = ref.read(v2.bitcoinWalletServiceProvider);
      final lwk = ref.read(v2.liquidWalletServiceProvider);
      final breez = ref.read(v2.lightningWalletServiceProvider);
      final store = await ref.read(v2.transactionStoreProvider.future);

      final results = await Future.wait([
        _dumpBdk(bdk),
        _dumpLwk(lwk),
        _dumpBreez(breez),
        _dumpStore(store),
      ]);

      if (!mounted) return;
      setState(() {
        _bdkDump = results[0];
        _lwkDump = results[1];
        _breezDump = results[2];
        _storeDump = results[3];
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = '$e\n$st';
        _loading = false;
      });
    }
  }

  Future<String> _dumpBdk(Object service) async {
    if (service is! bdk_impl.BitcoinWalletServiceImpl) {
      return '(BDK service is wrong type: ${service.runtimeType})';
    }
    final w = service.sdkClient;
    if (w == null || !service.currentState.isOperational) {
      return '(BDK not operational)';
    }
    try {
      final all = w.listTransactions(includeRaw: false);
      all.sort((a, b) {
        final at = a.confirmationTime?.timestamp.toInt() ?? 0;
        final bt = b.confirmationTime?.timestamp.toInt() ?? 0;
        return bt.compareTo(at);
      });
      final pick = all.take(_limit).toList();
      final buf = StringBuffer();
      buf.writeln('-- BDK (n=${pick.length}/${all.length}) --');
      for (final t in pick) {
        buf.writeln(_formatBdk(t));
      }
      return buf.toString();
    } catch (e) {
      return '(BDK dump failed: $e)';
    }
  }

  String _formatBdk(bdk.TransactionDetails t) {
    final ts = t.confirmationTime == null
        ? 'unconfirmed'
        : DateTime.fromMillisecondsSinceEpoch(
            t.confirmationTime!.timestamp.toInt() * 1000,
          ).toIso8601String();
    final h = t.confirmationTime?.height ?? -1;
    return [
      'txid=${t.txid}',
      '  sent=${t.sent} received=${t.received} fee=${t.fee ?? 0}',
      '  height=$h ts=$ts',
    ].join('\n');
  }

  Future<String> _dumpLwk(Object service) async {
    if (service is! lwk_impl.LiquidWalletServiceImpl) {
      return '(LWK service is wrong type: ${service.runtimeType})';
    }
    final w = service.sdkClient;
    if (w == null || !service.currentState.isOperational) {
      return '(LWK not operational)';
    }
    try {
      final all = await w.txs();
      all.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      final pick = all.take(_limit).toList();
      final buf = StringBuffer();
      buf.writeln('-- LWK (n=${pick.length}/${all.length}) --');
      for (final t in pick) {
        buf.writeln(_formatLwk(t));
      }
      return buf.toString();
    } catch (e) {
      return '(LWK dump failed: $e)';
    }
  }

  String _formatLwk(lwk.Tx t) {
    final ts = t.timestamp == null
        ? 'unconfirmed'
        : DateTime.fromMillisecondsSinceEpoch(t.timestamp! * 1000)
            .toIso8601String();
    final bs = t.balances
        .map((b) => '${_short(b.assetId)}:${b.value}')
        .join(', ');
    return [
      'txid=${t.txid}',
      '  kind=${t.kind} fee=${t.fee} height=${t.height ?? -1} ts=$ts',
      '  balances=[$bs]',
    ].join('\n');
  }

  Future<String> _dumpBreez(Object service) async {
    if (service is! breez_impl.LightningWalletServiceImpl) {
      return '(Breez service is wrong type: ${service.runtimeType})';
    }
    final c = service.sdkClient;
    if (c == null || !service.currentState.isOperational) {
      return '(Breez not operational)';
    }
    try {
      final all = await c.listPayments(
        req: const breez.ListPaymentsRequest(),
      );
      // Breez returns newest first already; just take the first N.
      final pick = all.take(_limit).toList();
      final buf = StringBuffer();
      buf.writeln('-- Breez (n=${pick.length}/${all.length}) --');
      for (final p in pick) {
        buf.writeln(_formatBreez(p));
      }
      return buf.toString();
    } catch (e) {
      return '(Breez dump failed: $e)';
    }
  }

  String _formatBreez(breez.Payment p) {
    final ts = DateTime.fromMillisecondsSinceEpoch(p.timestamp * 1000)
        .toIso8601String();
    final details = p.details;
    final detailsStr = switch (details) {
      breez.PaymentDetails_Liquid d =>
        'Liquid(assetId=${_short(d.assetId)}, dest=${_short(d.destination)})',
      breez.PaymentDetails_Bitcoin d =>
        'Bitcoin(swapId=${d.swapId}, lockup=${_short(d.lockupTxId)}, '
            'claim=${_short(d.claimTxId)}, addr=${_short(d.bitcoinAddress)})',
      breez.PaymentDetails_Lightning d =>
        'Lightning(swapId=${d.swapId}, '
            'destPubkey=${_short(d.destinationPubkey)}, '
            'claim=${_short(d.claimTxId)})',
    };
    return [
      'txId=${p.txId ?? "(null)"}',
      '  paymentType=${p.paymentType.name} status=${p.status.name}',
      '  amountSat=${p.amountSat} feesSat=${p.feesSat} ts=$ts',
      '  details=$detailsStr',
    ].join('\n');
  }

  Future<String> _dumpStore(Object store) async {
    try {
      // ignore: avoid_dynamic_calls
      final result = await (store as dynamic).list(limit: _limit);
      final list = (result as dynamic).getOrElse(
        (_) => const <v2tx.Transaction>[],
      ) as List<v2tx.Transaction>;
      final buf = StringBuffer();
      buf.writeln('-- V2 store (n=${list.length}) --');
      for (final t in list) {
        buf.writeln(_formatStore(t));
      }
      return buf.toString();
    } catch (e) {
      return '(Store dump failed: $e)';
    }
  }

  String _formatStore(v2tx.Transaction t) {
    return [
      'id=${t.id}',
      '  chain=${t.chain.name} dir=${t.direction.name} status=${t.status.name}',
      '  amountSat=${t.amountSat} feeSat=${t.feeSat} conf=${t.confirmations}',
      '  assetId=${_short(t.assetId)} source=${t.source?.name}',
      '  fromAssetId=${_short(t.fromAssetId)} toAssetId=${_short(t.toAssetId)}',
      '  sentAmount=${t.sentAmountSat} receivedAmount=${t.receivedAmountSat}',
      '  swapLockupTxId=${_short(t.swapLockupTxId)} '
          'swapClaimTxId=${_short(t.swapClaimTxId)}',
      '  ts=${t.timestamp.toIso8601String()}',
    ].join('\n');
  }

  String _short(String? s) {
    if (s == null) return 'null';
    if (s.length <= 16) return s;
    return '${s.substring(0, 8)}…${s.substring(s.length - 4)}';
  }

  String _allDumps() {
    return [_bdkDump, _lwkDump, _breezDump, _storeDump]
        .where((s) => s.isNotEmpty)
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug screen disabled in release builds')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw tx dump (dev)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all',
            onPressed: _loading
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: _allDumps()),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All dumps copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _section('BDK (sdkClient.listTransactions)', _bdkDump),
                    _section('LWK (sdkClient.txs)', _lwkDump),
                    _section('Breez (sdkClient.listPayments)', _breezDump),
                    _section('V2 store (transactionStore.list)', _storeDump),
                  ],
                ),
    );
  }

  Widget _section(String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy section',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: body));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$title" copied'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              body.isEmpty ? '(empty)' : body,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
