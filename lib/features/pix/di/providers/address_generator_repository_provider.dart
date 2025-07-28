import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/repositories.dart';
import 'package:mooze_mobile/features/pix/data/repositories/lwk_address_generator_repository_impl.dart';
import 'package:mooze_mobile/shared/infra/lwk/provider.dart';

final addressGeneratorRepositoryProvider = FutureProvider<Either<String, AddressGeneratorRepository>>((ref) async {
    final liquidWallet = await ref.read(liquidDataSourceProvider.future);

    return liquidWallet.fold(
              (l) => left(l),
              (wallet) => right(LwkAddressGeneratorRepositoryImpl(wallet)
            )
    );
});