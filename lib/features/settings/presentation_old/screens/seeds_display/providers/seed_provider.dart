import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/key_management/store.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';

final seedProvider = FutureProvider<Either<String, Option<String>>>((
  ref,
) async {
  final MnemonicStore mnemonicStore = ref.read(mnemonicStoreProvider);
  final Either<String, Option<String>> seed =
      await mnemonicStore.getMnemonic().run();

  return seed;
});
