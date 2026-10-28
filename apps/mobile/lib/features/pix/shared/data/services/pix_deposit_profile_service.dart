import 'package:shared_preferences/shared_preferences.dart';

/// Stores what the user declared before their first Pix deposit.
///
/// Two pieces of state live here: the CPF the user informed, and the
/// acknowledgement of the bank account ownership notice.
///
/// The CPF is checked for format and check digits only. Mooze has no service
/// that proves the account behind a Pix payment belongs to that CPF, so this
/// record never means "verified owner".
class PixDepositProfileService {
  static const String _taxIdKey = 'pix_deposit_tax_id';
  static const String _noticeAcknowledgedKey = 'pix_deposit_ownership_notice';

  final SharedPreferences _prefs;

  PixDepositProfileService(this._prefs);

  /// The stored CPF digits, or null when the user never informed one.
  String? taxIdNumber() {
    final stored = _prefs.getString(_taxIdKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  bool hasTaxIdNumber() => taxIdNumber() != null;

  /// Stores [digits], the CPF without formatting characters.
  Future<void> saveTaxIdNumber(String digits) async {
    await _prefs.setString(_taxIdKey, digits);
  }

  /// True once the user confirmed that they read the ownership notice.
  bool hasAcknowledgedOwnershipNotice() {
    return _prefs.getBool(_noticeAcknowledgedKey) ?? false;
  }

  Future<void> acknowledgeOwnershipNotice() async {
    await _prefs.setBool(_noticeAcknowledgedKey, true);
  }

  /// True when the deposit flow can start without asking anything again.
  bool isReadyToDeposit() =>
      hasTaxIdNumber() && hasAcknowledgedOwnershipNotice();

  /// Clears the record. Used when the wallet is deleted.
  Future<void> clear() async {
    await _prefs.remove(_taxIdKey);
    await _prefs.remove(_noticeAcknowledgedKey);
  }
}
