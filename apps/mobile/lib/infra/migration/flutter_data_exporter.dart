import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:mooze_mobile/database/database.dart';

/// Builds the one-time migration snapshot that mooze-core imports.
///
/// The Rust core keeps its data in its own key-value store. This class
/// reads the Flutter app's local data and writes it as one JSON document.
/// The core's `migration::import_flutter_data` reads that document. The
/// field names here are the contract with `mooze-core/src/migration.rs`.
///
/// Sources:
/// - [AppDatabase] (drift): swaps, pegs, deposits, products, sync metadata
///   and favorite payers.
/// - `mooze_v2.db`: transactions, notified transaction ids and notifier
///   metadata.
/// - [SharedPreferences]: every flag and setting.
///
/// Not exported:
/// - Secrets. The core reads them from the same secure storage entries.
/// - App logs, the legacy drift `Transactions` table and wallet caches.
///   See the core module docs for the reasons.
///
/// All times are milliseconds since the Unix epoch.
class FlutterDataExporter {
  FlutterDataExporter({
    required AppDatabase appDatabase,
    required sqlite.Database transactionDatabase,
    required SharedPreferences preferences,
  })  : _appDatabase = appDatabase,
        _transactionDatabase = transactionDatabase,
        _preferences = preferences;

  final AppDatabase _appDatabase;
  final sqlite.Database _transactionDatabase;
  final SharedPreferences _preferences;

  /// Snapshot format. Must match `SNAPSHOT_VERSION` in the core.
  static const int snapshotVersion = 1;

  /// Preference keys never exported, even if present.
  ///
  /// These secrets live in secure storage. The guard stops a secret that
  /// was stored in the wrong place from leaving the device in a snapshot.
  static const Set<String> secretKeys = {
    'mnemonic_mainWallet',
    'jwt',
    'refresh_token',
    'hashedPin',
    'pinSalt',
  };

  /// Builds the snapshot as a JSON-ready map.
  Future<Map<String, Object?>> buildSnapshot() async {
    return {
      'version': snapshotVersion,
      'transactions': _transactions(),
      'notified_tx_ids': _notifiedTxIds(),
      'notification_meta': _notificationMeta(),
      'swaps': await _swaps(),
      'pegs': await _pegs(),
      'deposits': await _deposits(),
      'products': await _products(),
      'sync_metadata': await _syncMetadata(),
      'favorite_payers': await _favoritePayers(),
      'preferences': _preferenceValues(),
    };
  }

  /// Builds the snapshot as a JSON string.
  Future<String> exportJson() async => jsonEncode(await buildSnapshot());

  List<Map<String, Object?>> _transactions() {
    final rows = _transactionDatabase.select('SELECT * FROM transactions');
    return [
      for (final r in rows)
        {
          'id': r['id'],
          'chain': r['chain'],
          'direction': r['direction'],
          'status': r['status'],
          'amount_sat': r['amount_sat'],
          'fee_sat': r['fee_sat'],
          'timestamp_ms': r['timestamp_ms'],
          'confirmations': r['confirmations'],
          'asset_id': r['asset_id'],
          'address': r['address'],
          'label': r['label'],
          'from_asset_id': r['from_asset_id'],
          'to_asset_id': r['to_asset_id'],
          'sent_amount_sat': r['sent_amount_sat'],
          'received_amount_sat': r['received_amount_sat'],
          'source': r['source'],
          'swap_lockup_tx_id': r['swap_lockup_tx_id'],
          'swap_claim_tx_id': r['swap_claim_tx_id'],
          'breez_swap_id': r['breez_swap_id'],
        },
    ];
  }

  List<Map<String, Object?>> _notifiedTxIds() {
    final rows = _transactionDatabase.select(
      'SELECT chain, tx_id, notified_at_ms FROM notified_tx_ids',
    );
    return [
      for (final r in rows)
        {
          'chain': r['chain'],
          'tx_id': r['tx_id'],
          'notified_at_ms': r['notified_at_ms'],
        },
    ];
  }

  Map<String, String> _notificationMeta() {
    final rows = _transactionDatabase.select(
      'SELECT meta_key, meta_value FROM notification_meta',
    );
    return {
      for (final r in rows) r['meta_key'] as String: r['meta_value'] as String,
    };
  }

  Future<List<Map<String, Object?>>> _swaps() async {
    final rows = await _appDatabase.select(_appDatabase.swaps).get();
    return [
      for (final s in rows)
        {
          'id': s.id,
          'send_asset': s.sendAsset,
          'receive_asset': s.receiveAsset,
          'send_amount': s.sendAmount.toInt(),
          'receive_amount': s.receiveAmount.toInt(),
          'created_at_ms': s.createdAt.millisecondsSinceEpoch,
          'provider': s.provider,
          'status': s.status,
          'direction': s.direction,
          'tx_id': s.txId,
          'metadata': s.metadata,
          'wallet_id': s.walletId,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _pegs() async {
    final rows = await _appDatabase.select(_appDatabase.pegs).get();
    return [
      for (final p in rows)
        {
          'order_id': p.orderId,
          'peg_in': p.pegIn,
          'sideswap_address': p.sideswapAddress,
          'payout_address': p.payoutAddress,
          'amount': p.amount,
          'created_at_ms': p.createdAt.millisecondsSinceEpoch,
          'wallet_id': p.walletId,
          'status': p.status,
          'provider': p.provider,
          'funding_tx_id': p.fundingTxId,
          'payout_tx_id': p.payoutTxId,
          'error_message': p.errorMessage,
          'updated_at_ms': p.updatedAt?.millisecondsSinceEpoch,
          'metadata': p.metadata,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _deposits() async {
    final rows = await _appDatabase.select(_appDatabase.deposits).get();
    return [
      for (final d in rows)
        {
          'deposit_id': d.depositId,
          'asset_id': d.assetId,
          'amount_in_cents': d.amountInCents,
          'created_at_ms': d.createdAt.millisecondsSinceEpoch,
          'status': d.status,
          'asset_amount': d.assetAmount?.toInt(),
          'blockchain_txid': d.blockchainTxid,
          'pix_key': d.pixKey,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _products() async {
    final rows = await _appDatabase.select(_appDatabase.products).get();
    return [
      for (final p in rows)
        {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'created_at_ms': p.createdAt.millisecondsSinceEpoch,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _syncMetadata() async {
    final rows = await _appDatabase.select(_appDatabase.syncMetadata).get();
    return [
      for (final m in rows)
        {
          'datasource': m.datasource,
          'last_sync_time_ms': m.lastSyncTime.millisecondsSinceEpoch,
          'transaction_count': m.transactionCount,
          'sync_status': m.syncStatus,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _favoritePayers() async {
    final rows =
        await _appDatabase.select(_appDatabase.favoritePayerEntries).get();
    return [
      for (final f in rows)
        {
          'id': f.id,
          'label': f.label,
          'cpf': f.cpf,
          'created_at_ms': f.createdAt.millisecondsSinceEpoch,
        },
    ];
  }

  Map<String, Object?> _preferenceValues() {
    return {
      for (final key in _preferences.getKeys())
        if (!secretKeys.contains(key)) key: _preferences.get(key),
    };
  }
}
