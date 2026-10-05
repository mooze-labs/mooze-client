import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart' as core;

import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2tx;

/// Dev-only diagnostic surface that dumps the most recent transactions
/// straight out of mooze-core plus the V2 transaction store. Use
/// this when the home tx list looks wrong — copy each section to a
/// chat and we can see *exactly* what the core is giving us versus
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
  String _btcDump = '';
  String _liquidDump = '';
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
      final store = await ref.read(v2.transactionStoreProvider.future);
      // The core owns both wallets: dump its transaction DTOs.
      final moozeCore = await ref.read(v2.moozeCoreProvider.future);
      final results = await Future.wait([
        _dumpCore('BTC', moozeCore.bitcoinTransactions),
        _dumpCore('L-BTC/Liquid', moozeCore.liquidTransactions),
        _dumpStore(store),
      ]);

      if (!mounted) return;
      setState(() {
        _btcDump = results[0];
        _liquidDump = results[1];
        _storeDump = results[2];
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

  /// Dumps the newest [_limit] core transactions of one chain.
  Future<String> _dumpCore(
    String label,
    Future<List<core.TransactionDto>> Function() load,
  ) async {
    try {
      final all = await load();
      // The core returns newest first.
      final pick = all.take(_limit).toList();
      final buf = StringBuffer();
      buf.writeln('-- core $label (n=${pick.length}/${all.length}) --');
      for (final t in pick) {
        buf.writeln(_formatCore(t));
      }
      return buf.toString();
    } catch (e) {
      final detail = e is core.CoreError ? '${e.kind.name}: ${e.message}' : '$e';
      return '(core $label dump failed: $detail)';
    }
  }

  String _formatCore(core.TransactionDto t) {
    final ts = DateTime.fromMillisecondsSinceEpoch(t.timestampMs.toInt())
        .toIso8601String();
    return [
      'id=${t.id}',
      '  chain=${t.chain.name} dir=${t.direction.name} status=${t.status.name}',
      '  amountSat=${t.amountSat} feeSat=${t.feeSat} conf=${t.confirmations}',
      '  assetId=${_short(t.assetId)} source=${t.source?.name}',
      '  ts=$ts',
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
    return [_btcDump, _liquidDump, _storeDump]
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
                    AppSnackBar.info(context, 'All dumps copied to clipboard');
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
                    _section('Core BTC (core.bitcoinTransactions)', _btcDump),
                    _section(
                      'Core Liquid (core.liquidTransactions)',
                      _liquidDump,
                    ),
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
                    AppSnackBar.info(context, '"$title" copied');
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
