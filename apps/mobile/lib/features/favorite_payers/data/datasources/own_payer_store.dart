import 'package:shared_preferences/shared_preferences.dart';

/// Which favorite payer is the user, kept on the device.
///
/// The mark names the holder of the bank account that pays the user's own
/// Pix deposits. It holds the payer id only: the document is read from the
/// payer each time, so an edit of the payer reaches the next deposit and
/// no other payer's document is ever reused.
class OwnPayerStore {
  static const String _key = 'favorite_payer_own_id';

  final SharedPreferences _prefs;

  OwnPayerStore(this._prefs);

  int? read() => _prefs.getInt(_key);

  Future<void> write(int id) => _prefs.setInt(_key, id);

  Future<void> clear() => _prefs.remove(_key);
}
