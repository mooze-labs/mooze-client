import 'dart:convert';

import 'package:mooze_mobile/features/wallet_level/infra/models/wallet_levels_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the last table of the level limits.
///
/// The table is public and the same for every wallet. The level screen
/// opens with the saved table at once, and a fetch in the background
/// replaces it.
class WalletLevelsCacheService {
  static const String _tableKey = 'wallet_levels_cache';

  final SharedPreferences _prefs;

  WalletLevelsCacheService(this._prefs);

  /// The saved table, or null when there is none or it no longer reads.
  WalletLevelsResponseModel? read() {
    final raw = _prefs.getString(_tableKey);
    if (raw == null) return null;
    try {
      return WalletLevelsResponseModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WalletLevelsResponseModel table) async {
    await _prefs.setString(_tableKey, jsonEncode(table.toJson()));
  }
}
