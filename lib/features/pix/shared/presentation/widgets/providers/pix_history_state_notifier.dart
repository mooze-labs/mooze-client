import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_history_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/providers/pix_history_paging_state.dart';

const int pageSize = 50;

class PixDepositsPageState {
  final List<PixDeposit> items;

  const PixDepositsPageState({required this.items});

  bool get hasMore =>
      items.length ==
      pageSize; // items are limited to pageSize, so we're checking if it has 50 entries
}

class PixHistoryNotifier extends AsyncNotifier<PixDepositsPageState> {
  @override
  FutureOr<PixDepositsPageState> build() async {
    final offset = ref.watch(pixHistoryPagingNotifier);
    final controller = ref.watch(pixHistoryControllerProvider);

    // Auto-refresh on status change or new deposit
    final repository = ref.read(pixRepositoryProvider);
    final subscription = repository.statusUpdates.listen((_) {
      Future.microtask(refresh);
    });
    ref.onDispose(subscription.cancel);

    final Either<String, List<PixDeposit>> deposits =
        await controller.getPixHistory(limit: pageSize, offset: offset).run();

    return deposits.fold(
      (error) => throw Exception(error),
      (depositsList) => PixDepositsPageState(items: depositsList),
    );
  }

  Future<void> loadNextPage() async {
    if (state is AsyncLoading) {
      if (kDebugMode) debugPrint("[PixHistory] Already loading next page.");
      return;
    }

    if (!state.requireValue.hasMore) {
      if (kDebugMode) debugPrint("[PixHistory] No more items to fetch.");
      return;
    }
    ref.watch(pixHistoryPagingNotifier.notifier).nextPage();

    final offset = ref.watch(pixHistoryPagingNotifier);
    final controller = ref.watch(pixHistoryControllerProvider);
    state = const AsyncValue.loading();

    final deposits =
        await controller.getPixHistory(limit: pageSize, offset: offset).run();

    deposits.fold((error) => throw Exception(error), (deposits) {
      state = AsyncValue.data(PixDepositsPageState(items: deposits));
    });
  }

  Future<void> refresh() async {
    if (state is AsyncLoading) {
      if (kDebugMode) debugPrint("[PixHistory] Currently fetching data.");
      return;
    }

    ref.watch(pixHistoryPagingNotifier.notifier).reset();
    final controller = ref.watch(pixHistoryControllerProvider);
    state = const AsyncValue.loading();

    final deposits =
        await controller.getPixHistory(limit: pageSize, offset: 0).run();

    deposits.fold((error) => throw Exception(error), (deposits) {
      state = AsyncValue.data(PixDepositsPageState(items: deposits));
    });
  }
}

final pixHistoryNotifierProvider =
    AsyncNotifierProvider<PixHistoryNotifier, PixDepositsPageState>(
      PixHistoryNotifier.new,
    );
