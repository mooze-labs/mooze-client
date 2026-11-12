import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// All wallet levels, for the WalletLevelsScreen.
///
/// They come from the table of [walletLevelsRemoteProvider], which is saved
/// on the device and refreshed in the background. With a saved table, the
/// levels show at once, with no loading state.
final walletLevelsProvider =
    FutureProvider.autoDispose<List<WalletLevelEntity>>((ref) {
      final table = ref.watch(walletLevelsRemoteProvider);
      if (!table.isLoading && !table.hasError) {
        if (table.valueOrNull case final saved?) return saved.toEntities();
      }
      return ref
          .watch(walletLevelsRemoteProvider.future)
          .then((table) => table.toEntities());
    });

/// Fetches a specific wallet level by type.
final walletLevelByTypeProvider = FutureProvider.autoDispose
    .family<WalletLevelEntity, WalletLevelType>((ref, type) async {
      final useCase = ref.watch(getWalletLevelByTypeUseCaseProvider);
      final result = await useCase.call(type);
      return result.fold((level) => level, (error) => throw Exception(error));
    });
