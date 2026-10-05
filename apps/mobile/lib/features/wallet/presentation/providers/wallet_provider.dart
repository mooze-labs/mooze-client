import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/wallet/di/providers.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

import '../controllers/wallet_controller.dart';

final walletControllerProvider = FutureProvider.autoDispose<
  Either<WalletError, WalletController>
>((ref) async {
  // Use watch instead of read to ensure we get fresh data when wallet changes
  final walletRepository = await ref.watch(walletRepositoryProvider.future);

  return walletRepository.flatMap((repo) => right(WalletController(repo)));
});
