import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/di/providers.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../controllers/wallet_controller.dart';

final walletControllerProvider =
    FutureProvider<Either<WalletError, WalletController>>((ref) async {
      final walletRepository = await ref.read(walletRepositoryProvider.future);

      return walletRepository.flatMap((repo) => right(WalletController(repo)));
    });
