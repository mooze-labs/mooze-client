import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart'
    show liquidWalletServiceProvider, refreshWalletProvider;
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/data/pix_api_log.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/api_pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/data/repositories/liquid_pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_api_log_sink.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// The real withdrawal API. The session token comes from mooze-core.
///
/// Its log lines carry [withdrawalLogKey], because the screens show a
/// generic text.
final pixWithdrawalRepositoryProvider = Provider<PixWithdrawalRepository>(
  (ref) => ApiPixWithdrawalRepository(
    dio: ApiPixWithdrawalRepository.createDio(),
    session: ref.watch(sessionManagerServiceProvider),
    log: pixApiLogSink(ref, withdrawalLogKey),
  ),
);

/// The Liquid wallet that funds the withdrawals.
final pixWithdrawalWalletProvider = Provider<PixWithdrawalWallet>(
  (ref) => LiquidPixWithdrawalWallet(ref.watch(liquidWalletServiceProvider)),
);

/// Local records of the withdrawals that the app tried to fund.
final pixWithdrawalRecordStoreProvider = Provider<PixWithdrawalRecordStore>(
  (ref) => PixWithdrawalRecordStore(ref.watch(sharedPreferencesProvider)),
);

/// State of the send flow.
///
/// The provider is kept alive on purpose: the draft and the withdrawal have
/// to survive while the user walks through the screens of the flow. The
/// dependencies are read once, so a rebuild of a dependency cannot drop a
/// flow in progress.
final pixSendControllerProvider =
    StateNotifierProvider<PixSendController, PixSendState>(
      (ref) => PixSendController(
        repository: ref.read(pixWithdrawalRepositoryProvider),
        wallet: ref.read(pixWithdrawalWalletProvider),
        records: ref.read(pixWithdrawalRecordStoreProvider),
        onFunded: () async {
          // The same light sync as the wallet send flow, so the balance and
          // the history show the deposit.
          final refresh = await ref.read(refreshWalletProvider.future);
          await refresh(strategy: SyncStrategy.light);
        },
      ),
    );

/// DePix balance of the wallet, in base units, for the amount step.
final pixDepixBalanceProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref
      .watch(pixWithdrawalWalletProvider)
      .depixBalanceSats();
  return result.getOrElse((failure) => throw failure);
});

/// Withdrawals whose funds may have left the wallet without a final status.
///
/// The result screen and the hub refresh invalidate it, so the list reads the
/// store again after a flow.
final pixPendingWithdrawalsProvider =
    Provider.autoDispose<List<PixWithdrawalRecord>>(
      (ref) => ref.watch(pixWithdrawalRecordStoreProvider).pending(),
    );
