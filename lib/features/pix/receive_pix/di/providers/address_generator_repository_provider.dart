import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/address_generator_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/repositories/lwk_address_generator_repository_impl.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers.dart';

final addressGeneratorRepositoryProvider =
    FutureProvider<Either<String, AddressGeneratorRepository>>((ref) async {
      final liquidWallet = await ref.read(liquidDataSourceProvider.future);

      return liquidWallet.fold(
        (l) => left(l),
        (wallet) => right(LwkAddressGeneratorRepositoryImpl(wallet)),
      );
    });
