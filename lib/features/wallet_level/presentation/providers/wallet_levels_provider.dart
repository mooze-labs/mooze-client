import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Fetches all wallet levels via the use case.
/// Consumed by the WalletLevelsScreen to display tier data.
final walletLevelsProvider =
    FutureProvider.autoDispose<List<WalletLevelEntity>>((ref) async {
      final useCase = ref.watch(getAllWalletLevelsUseCaseProvider);
      final result = await useCase.call();
      return result.fold(
        (levels) => levels,
        (error) => throw Exception(error),
      );
    });

/// Fetches a specific wallet level by type.
final walletLevelByTypeProvider = FutureProvider.autoDispose
    .family<WalletLevelEntity, WalletLevelType>((ref, type) async {
      final useCase = ref.watch(getWalletLevelByTypeUseCaseProvider);
      final result = await useCase.call(type);
      return result.fold(
        (level) => level,
        (error) => throw Exception(error),
      );
    });
