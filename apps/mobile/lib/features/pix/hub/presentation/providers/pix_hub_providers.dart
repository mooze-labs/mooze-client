import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart'
    show liquidWalletServiceProvider;
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_api_log_sink.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_history_entries.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

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

/// References of the payment links, kept on the device.
final pixPaymentLinkReferenceStoreProvider =
    Provider<PixPaymentLinkReferenceStore>(
      (ref) =>
          PixPaymentLinkReferenceStore(ref.watch(sharedPreferencesProvider)),
    );

/// Reads a new receive address of the Liquid wallet.
///
/// The address is bare: the payment-link API expects an Elements address,
/// not a `liquidnetwork:` URI.
final pixReceiveAddressProvider =
    Provider<Future<Either<String, String>> Function()>((ref) {
      final wallet = ref.read(liquidWalletServiceProvider);
      return () async {
        // No asset id: the service returns a bare address.
        final result = await wallet.nextReceiveAddress();
        return result.fold((failure) => Left(failure.message), (receive) {
          final address = receive.address;
          return address == null || address.isEmpty
              ? const Left('empty receive address')
              : Right(address);
        });
      };
    });

/// Every Pix movement, newest first.
///
/// The backend lists neither the withdrawals nor the deposits of a user, so
/// the sends come from the records of the device and the deposits from the
/// deposit store of mooze-core. The list reads the records again when the
/// status read of the pending sends ends.
final pixHubTransactionsProvider =
    FutureProvider.autoDispose<List<PixTransaction>>((ref) async {
      ref.watch(pixPendingWithdrawalSyncProvider);
      final records = ref.watch(pixWithdrawalRecordStoreProvider).load();
      final deposits = await ref.watch(pixDepositHistoryProvider.future);
      final received = deposits.getOrElse(
        (message) => throw PixHubFailure(
          PixHubErrorCode.loadFailed,
          rawMessage: message,
        ),
      );
      return [
        ...records.map(pixTransactionFromWithdrawal).nonNulls,
        ...received.map(pixTransactionFromDeposit),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

/// Payment links owned by the user, with the references of the device.
class PixPaymentLinksController
    extends AutoDisposeAsyncNotifier<List<PixPaymentLink>> {
  @override
  Future<List<PixPaymentLink>> build() async {
    final repository = ref.watch(pixPaymentLinkRepositoryProvider);
    final links = _unwrap(await repository.listLinks().run());
    final references = ref.watch(pixPaymentLinkReferenceStoreProvider).load();
    return [
      for (final link in links) link.withReference(references[link.id] ?? ''),
    ];
  }

  /// Turns the link [id] off.
  ///
  /// Once the API confirms, the link shows as revoked at once: a full list
  /// read can take several pages. The list then reloads, after a failure
  /// too, so it ends with what the API holds.
  Future<Either<PixHubFailure, Unit>> revoke(String id) async {
    // The screen that asked can close during the request. The list must
    // still take the result.
    final keepAlive = ref.keepAlive();
    try {
      final result = await ref
          .read(pixPaymentLinkRepositoryProvider)
          .revokeLink(id)
          .run();
      final links = state.valueOrNull;
      if (result.isRight() && links != null) {
        state = AsyncData([
          for (final link in links)
            // The API keeps a paid link paid after a revoke.
            link.id == id && link.isActive
                ? link.withStatus(PixPaymentLinkStatus.revoked)
                : link,
        ]);
      }
      ref.invalidateSelf();
      return result;
    } finally {
      keepAlive.close();
    }
  }
}

final pixHubPaymentLinksProvider =
    AsyncNotifierProvider.autoDispose<
      PixPaymentLinksController,
      List<PixPaymentLink>
    >(PixPaymentLinksController.new);

/// Rebuilds every hub list after a flow records a new movement.
void refreshPixHub(WidgetRef ref) {
  ref.invalidate(pixHubTransactionsProvider);
  ref.invalidate(pixHubPaymentLinksProvider);
}

/// Turns the repository result into a value, or raises the failure so the
/// screens read it from an [AsyncValue].
T _unwrap<T>(Either<PixHubFailure, T> result) =>
    result.getOrElse((failure) => throw failure);
