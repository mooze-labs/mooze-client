import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/address_generator_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/repositories/lwk_address_generator_repository_impl.dart';

final addressGeneratorRepositoryProvider =
    FutureProvider<AddressGeneratorRepository>((ref) async {
  final walletRepo = await ref.read(walletRepositoryProvider.future);
  return LwkAddressGeneratorRepositoryImpl(walletRepo);
});
