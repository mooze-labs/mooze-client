import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_service_provider.dart';

/// Provider that returns complete user information
final userInfoProvider = FutureProvider.autoDispose<Either<String, User>>((
  ref,
) async {
  final userService = ref.read(userServiceProvider);
  final result = await userService.getUser().run();
  return result;
});

/// Provider that returns only the user's spending level
final userSpendingLevelProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final userInfo = ref.watch(userInfoProvider);
  return userInfo.when(
    data:
        (result) => result.fold(
          (error) => AsyncValue.error(error, StackTrace.current),
          (user) => AsyncValue.data(user.spendingLevel),
        ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider that returns the user's level progress
final userLevelProgressProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final userInfo = ref.watch(userInfoProvider);
  return userInfo.when(
    data:
        (result) => result.fold(
          (error) => AsyncValue.error(error, StackTrace.current),
          (user) => AsyncValue.data(user.levelProgress),
        ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider that returns allowed spending information
final userSpendingInfoProvider =
    Provider.autoDispose<AsyncValue<({double allowed, double daily})>>((ref) {
      final userInfo = ref.watch(userInfoProvider);
      return userInfo.when(
        data:
            (result) => result.fold(
              (error) => AsyncValue.error(error, StackTrace.current),
              (user) => AsyncValue.data((
                allowed: user.allowedSpending,
                daily: user.dailySpending,
              )),
            ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });
