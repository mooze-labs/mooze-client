import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_data_provider.dart';
import 'user_service_provider.dart';
import 'package:mooze_mobile/features/wallet_level/infra/models/wallet_levels_response_model.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';

class UserLevelsData {
  final int spendingLevel; // 0-3 (bronze, silver, gold, diamond)
  final double levelProgress; // 0.0 - 1.0
  final double allowedSpending; // limit per transaction (varies by level)
  final double dailySpending; // amount already spent today (in cents/100)
  final double currentLevelMinLimit; // minimum limit of the current level
  final double currentLevelMaxLimit; // maximum limit of the current level
  final double absoluteMinLimit; // lowest possible limit (all levels)
  final double absoluteMaxLimit; // highest possible limit (top level)
  final double remainingLimit; // how much can still be spent today
  static const double dailyLimit = 5000.0; // Fixed daily limit in BRL

  const UserLevelsData({
    required this.spendingLevel,
    required this.levelProgress,
    required this.allowedSpending,
    required this.dailySpending,
    required this.currentLevelMinLimit,
    required this.currentLevelMaxLimit,
    required this.absoluteMinLimit,
    required this.absoluteMaxLimit,
    required this.remainingLimit,
  });

  /// Returns the name of the current level
  String get currentLevelName {
    switch (spendingLevel) {
      case 0:
        return 'Bronze';
      case 1:
        return 'Silver';
      case 2:
        return 'Gold';
      case 3:
        return 'Diamond';
      default:
        return 'Bronze';
    }
  }

  /// Returns the name of the next level
  String? get nextLevelName {
    if (spendingLevel >= 3) return null;
    switch (spendingLevel + 1) {
      case 1:
        return 'Silver';
      case 2:
        return 'Gold';
      case 3:
        return 'Diamond';
      default:
        return null;
    }
  }

  /// Calculates the progress within the daily limit (0.0 - 1.0)
  double get dailyLimitProgress {
    if (dailyLimit <= 0) return 0.0;
    final progress = dailySpending / dailyLimit;
    return progress.clamp(0.0, 1.0);
  }

  /// Checks if it is at the maximum level
  bool get isMaxLevel => spendingLevel >= 3;
}

/// The table of the level limits.
final walletLevelsRemoteProvider =
    AsyncNotifierProvider<WalletLevelsTableNotifier, WalletLevelsResponseModel>(
      WalletLevelsTableNotifier.new,
    );

class WalletLevelsTableNotifier
    extends AsyncNotifier<WalletLevelsResponseModel> {
  /// False once this build is replaced or disposed.
  bool Function() _isCurrent = () => false;

  @override
  FutureOr<WalletLevelsResponseModel> build() {
    ref.watch(walletLevelsDataSourceProvider);
    ref.watch(walletLevelsCacheServiceProvider);
    var current = true;
    ref.onDispose(() => current = false);
    _isCurrent = () => current;

    final saved = ref.read(walletLevelsCacheServiceProvider).read();
    if (saved == null) return _fetch();
    unawaited(refresh());
    return saved;
  }

  /// Fetches the table and saves it.
  Future<WalletLevelsResponseModel> _fetch() async {
    final table = await ref
        .read(walletLevelsDataSourceProvider)
        .getWalletLevels();
    await ref.read(walletLevelsCacheServiceProvider).save(table);
    return table;
  }

  /// Fetches the table now and waits for it, for a pull to refresh. A
  /// failure keeps what shows.
  Future<void> refresh() async {
    final isCurrent = _isCurrent;
    try {
      final table = await _fetch();
      if (isCurrent()) state = AsyncData(table);
    } catch (_) {
      // The saved table stays. The next build fetches again.
    }
  }
}

/// The value of [value] once it has settled. Null while it loads or after
/// an error, so a wallet change never shows the data of the old wallet.
T? _settled<T>(AsyncValue<T> value) =>
    value.isLoading || value.hasError ? null : value.valueOrNull;

/// Centralized provider that combines user data with level limits.
///
/// With the saved user and table, it gives the levels at once, with no
/// loading state. Otherwise it waits for them.
final levelsProvider = FutureProvider.autoDispose<UserLevelsData>((ref) {
  final user = _settled(ref.watch(userDataProvider));
  final table = _settled(ref.watch(walletLevelsRemoteProvider));
  if (user == null || table == null) return _loadLevels(ref);
  try {
    return _levelsOf(user, table);
  } catch (error) {
    throw UserFriendlyException.fromError(error);
  }
});

Future<UserLevelsData> _loadLevels(Ref ref) async {
  try {
    final user = await ref.watch(userDataProvider.future);
    final table = await ref.watch(walletLevelsRemoteProvider.future);
    return _levelsOf(user, table);
  } catch (error) {
    // Converts any error into a user-friendly exception
    throw UserFriendlyException.fromError(error);
  }
}

UserLevelsData _levelsOf(
  Either<String, User> userResult,
  WalletLevelsResponseModel walletLevelsResponse,
) {
  final user = userResult.fold(
    (error) => throw Exception('Error fetching user data: $error'),
    (user) => user,
  );

  // Convert values from cents to currency (divide by 100)
  final allowedSpending = user.allowedSpending / 100.0;
  final dailySpending = user.dailySpending / 100.0;

  // Determine current level limits
  String currentLevelKey;
  switch (user.spendingLevel) {
    case 0:
      currentLevelKey = 'bronze';
      break;
    case 1:
      currentLevelKey = 'silver';
      break;
    case 2:
      currentLevelKey = 'gold';
      break;
    case 3:
      currentLevelKey = 'diamond';
      break;
    default:
      currentLevelKey = 'bronze';
  }

  final currentLevelData = walletLevelsResponse.data[currentLevelKey];
  if (currentLevelData == null) {
    throw Exception('Data for level $currentLevelKey not found');
  }

  final currentLevelMinLimit = currentLevelData.minLimit / 100.0;
  final currentLevelMaxLimit = currentLevelData.maxLimit / 100.0;

  // Fetch absolute maximum limit (diamond)
  final diamondData = walletLevelsResponse.data['diamond'];
  if (diamondData == null) {
    throw Exception('Data for diamond level not found');
  }
  final absoluteMaxLimit = diamondData.maxLimit / 100.0;

  // Fetch absolute minimum limit (bronze)
  final bronzeData = walletLevelsResponse.data['bronze'];
  if (bronzeData == null) {
    throw Exception('Data for bronze level not found');
  }
  final absoluteMinLimit = bronzeData.minLimit / 100.0;

  // Calculate remaining limit based on the fixed daily limit
  final remainingLimit = (UserLevelsData.dailyLimit - dailySpending).clamp(
    0.0,
    UserLevelsData.dailyLimit,
  );

  return UserLevelsData(
    spendingLevel: user.spendingLevel,
    levelProgress: user.levelProgress,
    allowedSpending: allowedSpending,
    dailySpending: dailySpending,
    currentLevelMinLimit: currentLevelMinLimit,
    currentLevelMaxLimit: currentLevelMaxLimit,
    absoluteMinLimit: absoluteMinLimit,
    absoluteMaxLimit: absoluteMaxLimit,
    remainingLimit: remainingLimit,
  );
}

/// Provider that returns only the spending level
final userCurrentLevelProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final levelsData = ref.watch(levelsProvider);
  return levelsData.when(
    data: (data) => AsyncValue.data(data.spendingLevel),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider that returns the level progress
final userCurrentProgressProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final levelsData = ref.watch(levelsProvider);
  return levelsData.when(
    data: (data) => AsyncValue.data(data.levelProgress),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider that returns daily limits
final userDailyLimitsProvider = Provider.autoDispose<
  AsyncValue<({double allowed, double spent, double remaining})>
>((ref) {
  final levelsData = ref.watch(levelsProvider);
  return levelsData.when(
    data:
        (data) => AsyncValue.data((
          allowed: data.allowedSpending,
          spent: data.dailySpending,
          remaining: data.remainingLimit,
        )),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
