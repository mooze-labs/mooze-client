import 'dart:convert';

import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the withdrawals that the app tried to fund, newest first.
///
/// The send flow writes a record before the broadcast. So if the app stops
/// during the broadcast, the next start still knows the withdrawal ID and can
/// read its status.
class PixWithdrawalRecordStore {
  static const String _key = 'pix_withdrawal_records';

  /// Records kept. The oldest records are removed first.
  static const int maxRecords = 20;

  final SharedPreferences _prefs;

  PixWithdrawalRecordStore(this._prefs);

  /// Every readable record, newest first. Unreadable entries are skipped.
  List<PixWithdrawalRecord> load() {
    final text = _prefs.getString(_key);
    if (text == null || text.isEmpty) return const [];
    try {
      final list = jsonDecode(text);
      if (list is! List) return const [];
      return list.map(PixWithdrawalRecord.fromJson).nonNulls.toList();
    } on FormatException {
      return const [];
    }
  }

  /// The records whose funds may have left the wallet without a final status.
  List<PixWithdrawalRecord> pending() =>
      load().where((r) => r.needsAttention).toList();

  /// Inserts [record] first, or replaces the record with the same ID in place.
  Future<void> save(PixWithdrawalRecord record) async {
    final current = load();
    final index = current.indexWhere((r) => r.id == record.id);
    final records = index == -1
        ? [record, ...current].take(maxRecords).toList()
        : ([...current]..[index] = record);
    await _prefs.setString(
      _key,
      jsonEncode([for (final r in records) r.toJson()]),
    );
  }

  /// Removes every record. Used when the wallet is deleted.
  Future<void> clear() => _prefs.remove(_key);
}
