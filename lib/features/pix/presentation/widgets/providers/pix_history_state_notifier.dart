import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/providers/pix_history_paging_state.dart';

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
