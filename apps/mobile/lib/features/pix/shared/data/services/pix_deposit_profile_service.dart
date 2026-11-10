import 'package:shared_preferences/shared_preferences.dart';

/// Stores what the user declared before their first Pix deposit: the
/// acknowledgement of the bank account ownership notice.
///
/// The payer document is not here. It comes from the favorite payer marked
/// as "my user", read again at each deposit.
class PixDepositProfileService {
  /// Where older versions kept a copy of the deposit CPF. Deleting the
  /// favorite payer did not reach that copy, so the deposit kept filling a
  /// document the user had removed.
  static const String _legacyTaxIdKey = 'pix_deposit_tax_id';
  static const String _noticeAcknowledgedKey = 'pix_deposit_ownership_notice';

  final SharedPreferences _prefs;

  PixDepositProfileService(this._prefs);

  /// True once the user confirmed that they read the ownership notice.
  bool hasAcknowledgedOwnershipNotice() {
    return _prefs.getBool(_noticeAcknowledgedKey) ?? false;
  }

  Future<void> acknowledgeOwnershipNotice() async {
    await _prefs.setBool(_noticeAcknowledgedKey, true);
  }

  /// Deletes the CPF copy of older versions. Nothing reads it, and it may
  /// hold a document the user removed.
  Future<void> forgetLegacyTaxId() async {
    await _prefs.remove(_legacyTaxIdKey);
  }

  /// Clears the record. Used when the wallet is deleted.
  Future<void> clear() async {
    await forgetLegacyTaxId();
    await _prefs.remove(_noticeAcknowledgedKey);
  }
}
