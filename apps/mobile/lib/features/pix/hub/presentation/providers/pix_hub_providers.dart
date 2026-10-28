import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_demo_store.dart';
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/demo_pix_hub_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_overview.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_hub_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_api_log_sink.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';

/// Holds the demonstration records for the whole session.
///
/// The store lives outside the screens so a payment created in one flow shows
/// up in the history of another.
final pixDemoStoreProvider = Provider<PixDemoStore>((ref) => PixDemoStore());

/// The repository behind every Pix hub screen.
///
/// Replace this single line once Mooze has real Pix services; the screens read
/// the [PixHubRepository] contract only.
final pixHubRepositoryProvider = Provider<PixHubRepository>(
  (ref) => DemoPixHubRepository(ref.watch(pixDemoStoreProvider)),
);

/// The real payment-link API. The session token comes from mooze-core.
///
/// Its log lines carry [paymentLinkLogKey].
final pixPaymentLinkRepositoryProvider = Provider<PixPaymentLinkRepository>(
  (ref) => ApiPixPaymentLinkRepository(
    dio: ApiPixPaymentLinkRepository.createDio(),
    session: ref.watch(sessionManagerServiceProvider),
    log: pixApiLogSink(ref, paymentLinkLogKey),
  ),
);

/// True while the hub answers with empty lists, so the empty states of every
/// screen can be reviewed without changing the dataset.
final pixHubEmptyPreviewProvider = StateProvider<bool>((ref) => false);

/// Sections of the hub home screen.
final pixHubOverviewProvider = FutureProvider.autoDispose<PixHubOverview>((
  ref,
) async {
  final repository = ref.watch(pixHubRepositoryProvider);
  ref.watch(pixHubEmptyPreviewProvider);
  return _unwrap(await repository.loadOverview().run());
});

/// Pix keys presented as the user's own.
final pixHubKeysProvider = FutureProvider.autoDispose<List<PixKey>>((
  ref,
) async {
  final repository = ref.watch(pixHubRepositoryProvider);
  ref.watch(pixHubEmptyPreviewProvider);
  return _unwrap(await repository.listKeys().run());
});

/// Recipients paid recently.
final pixHubRecipientsProvider = FutureProvider.autoDispose<List<PixRecipient>>(
  (ref) async {
    final repository = ref.watch(pixHubRepositoryProvider);
    ref.watch(pixHubEmptyPreviewProvider);
    return _unwrap(await repository.listRecentRecipients().run());
  },
);

/// Every Pix movement, newest first.
final pixHubTransactionsProvider =
    FutureProvider.autoDispose<List<PixTransaction>>((ref) async {
      final repository = ref.watch(pixHubRepositoryProvider);
      ref.watch(pixHubEmptyPreviewProvider);
      return _unwrap(await repository.listTransactions().run());
    });

/// Payment links owned by the user.
final pixHubPaymentLinksProvider =
    FutureProvider.autoDispose<List<PixPaymentLink>>((ref) async {
      final repository = ref.watch(pixHubRepositoryProvider);
      ref.watch(pixHubEmptyPreviewProvider);
      return _unwrap(await repository.listPaymentLinks().run());
    });

/// Rebuilds every hub list after a flow records a new movement.
void refreshPixHub(WidgetRef ref) {
  ref.invalidate(pixHubOverviewProvider);
  ref.invalidate(pixHubTransactionsProvider);
  ref.invalidate(pixHubRecipientsProvider);
  ref.invalidate(pixHubPaymentLinksProvider);
}

/// Turns the repository result into a value, or raises the failure so the
/// screens read it from an [AsyncValue].
T _unwrap<T>(Either<PixHubFailure, T> result) =>
    result.getOrElse((failure) => throw failure);
