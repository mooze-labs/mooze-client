import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/di/providers/address_generator_repository_provider.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_repository_provider.dart';

import '../controllers/pix_deposit_controller.dart';

final pixDepositControllerProvider =
    FutureProvider.autoDispose<Either<String, PixDepositController>>((
      ref,
    ) async {
      final addressRepoResult = await ref.read(
        addressGeneratorRepositoryProvider.future,
      );

      return await addressRepoResult.fold(
        (error) async => left<String, PixDepositController>(error),
        (addressRepo) async {
          final pixRepo = ref.read(pixRepositoryProvider);
          return right<String, PixDepositController>(
            PixDepositController(pixRepo, addressRepo),
          );
        },
      );
    });
