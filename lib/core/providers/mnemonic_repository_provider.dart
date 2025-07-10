import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/repositories/mnemonic_repository.dart';

final mnemonicRepositoryProvider = Provider<MnemonicRepository>((ref) {
  return MnemonicRepositoryImpl();
});
