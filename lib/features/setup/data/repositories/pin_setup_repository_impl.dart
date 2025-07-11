import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/key_management/pin_store.dart';

import '../../domain/repositories/pin_setup_repository.dart';

class PinSetupRepositoryImpl implements PinSetupRepository {
  final PinStore _pinStore;

  PinSetupRepositoryImpl({required PinStore pinStore}) : _pinStore = pinStore;

  @override
  TaskEither<String, Unit> savePin(String pin) {
    return _pinStore.save(pin);
  }

  @override
  TaskEither<String, bool> validatePin(String pin) {
    return _pinStore.validate(pin);
  }
}
