import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';

final depositDataProvider = FutureProvider.autoDispose
    .family<Either<String, PixDeposit>, String>((ref, depositId) async {
      final controller = await ref.read(pixDepositControllerProvider.future);

      return await controller.fold(
        (err) => left("Falha ao acessar banco de dados: $err"),
        (controller) async => await controller
            .getDeposit(depositId)
            .run()
            .then(
              (maybeDeposit) => maybeDeposit.fold(
                (err) => left(err),
                (deposit) => right(deposit),
              ),
            ),
      );
    });
