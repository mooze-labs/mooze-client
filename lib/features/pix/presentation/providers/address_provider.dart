import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/di/providers/address_generator_repository_provider.dart';

import '../controllers/address_generation_controller.dart';

final addressProvider = FutureProvider.autoDispose<Either<String, String>>((ref) async {
    final repositoryResult = await ref.read(addressGeneratorRepositoryProvider.future);

    return await repositoryResult.fold(
      (error) async => left<String, String>(error),
      (repository) async {
        final controller = AddressGeneratorController(repository);
        return await controller.newLiquidAddress().run();
      }
    );
});