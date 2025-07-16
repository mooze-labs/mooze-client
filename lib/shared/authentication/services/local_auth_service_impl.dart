import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/shared/key_management/pin_store.dart';

import 'local_auth_service.dart';

const _authenticationTimeout = Duration(minutes: 5);
const _lastAuthenticationTimestampKey = 'last_authentication_timestamp';

class LocalAuthServiceImpl implements LocalAuthenticationService {
  final PinStore _pinStore;

  LocalAuthServiceImpl({required PinStore pinStore}) : _pinStore = pinStore;

  @override
  TaskEither<String, Unit> savePin(String pin) {
    return _pinStore.save(pin);
  }

  @override
  TaskEither<String, bool> validatePin(String pin) {
    final validation = _pinStore.validate(pin);

    return validation.flatMap((isValid) {
      if (!isValid) {
        return TaskEither.right(false);
      }

      return TaskEither.tryCatch(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _lastAuthenticationTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return true;
      }, (error, stackTrace) => error.toString());
    });
  }

  @override
  Task<bool> isAuthenticated() {
    return Task(() async {
      final prefs = await SharedPreferences.getInstance();
      final lastAuthenticationTimestamp = prefs.getInt(
        _lastAuthenticationTimestampKey,
      );

      if (lastAuthenticationTimestamp == null) {
        return false;
      }

      return lastAuthenticationTimestamp + _authenticationTimeout.inSeconds >
          DateTime.now().millisecondsSinceEpoch;
    });
  }
}
