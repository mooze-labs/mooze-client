import 'package:shared_preferences/shared_preferences.dart';

class StoreModeHandler {
  Future<bool> isStoreMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isStoreMode = prefs.getBool("storeMode");

    return (isStoreMode ?? false);
  }

  Future<void> setStoreMode(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("storeMode", value);
  }
}
