import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pix_send_fakes.dart';

/// Lets the queued futures and microtasks finish.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A funded withdrawal whose last read status is [lastStatus].
PixWithdrawalRecord _record(
  String id, {
  PixWithdrawalStatus? lastStatus = PixWithdrawalStatus.sending,
}) {
  return PixWithdrawalRecord(
    id: id,
    createdAt: testStart,
    payoutAmountInCents: 4590,
    depositAmountInCents: 4689,
    depositAmountSats: 4689000000,
    depositAddress: 'lq1qqdeposit',
    expiresAt: testStart.add(const Duration(minutes: 30)),
    maskedKey: 'a***@exemplo.com.br',
    fundingStatus: PixFundingStatus.sent,
    fundingTxid: 'txid-$id',
    lastStatus: lastStatus,
  );
}

/// The send flow stores `sent` while the hub reads the status, and the hub
/// read answers the older `sending`.
class _RacingRepository extends FakeWithdrawalRepository {
  final PixWithdrawalRecordStore store;

  _RacingRepository(this.store);

  @override
  TaskEither<PixHubFailure, List<PixWithdrawalDetails>> statuses(
    List<String> ids,
  ) {
    return TaskEither(() async {
      await store.save(_record('w-1', lastStatus: PixWithdrawalStatus.sent));
      return Right([testDetails('w-1', PixWithdrawalStatus.sending)]);
    });
  }
}

void main() {
  late SharedPreferences prefs;
  late PixWithdrawalRecordStore store;
  late FakeWithdrawalRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PixWithdrawalRecordStore(prefs);
    repository = FakeWithdrawalRepository();
  });

  ProviderContainer container({
    PixWithdrawalRepository? withdrawals,
    List<Override> overrides = const [],
  }) {
    final api = withdrawals ?? repository;
    final result = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pixWithdrawalRepositoryProvider.overrideWithValue(api),
        pixSendControllerProvider.overrideWith(
          (ref) => PixSendController(
            repository: api,
            wallet: FakeWithdrawalWallet(),
            records: store,
            schedule: (_, _) => FakeTimer(),
          ),
        ),
        ...overrides,
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test(
    'a withdrawal paid after the send flow stopped leaves the list',
    () async {
      await store.save(_record('w-1'));
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
      );
      final c = container();
      final list = c.listen(pixPendingWithdrawalsProvider, (_, _) {});
      expect(list.read().map((r) => r.id), ['w-1']);

      await c.read(pixPendingWithdrawalSyncProvider.future);

      expect(list.read(), isEmpty);
      expect(repository.statusReads, [
        ['w-1'],
      ]);
      expect(store.load().single.lastStatus, PixWithdrawalStatus.sent);
    },
  );

  test('a failed status read keeps the stored status', () async {
    await store.save(_record('w-1'));
    repository.statusAnswers.add(
      const Left(PixHubFailure(PixHubErrorCode.network)),
    );
    final c = container();
    final list = c.listen(pixPendingWithdrawalsProvider, (_, _) {});

    await c.read(pixPendingWithdrawalSyncProvider.future);

    expect(list.read().single.lastStatus, PixWithdrawalStatus.sending);
  });

  test('reads no status without a pending withdrawal', () async {
    await store.save(_record('w-1', lastStatus: PixWithdrawalStatus.sent));
    final c = container();
    c.listen(pixPendingWithdrawalsProvider, (_, _) {});

    await c.read(pixPendingWithdrawalSyncProvider.future);

    expect(repository.statusReads, isEmpty);
  });

  test(
    'keeps a final status that the send flow stored during the read',
    () async {
      await store.save(_record('w-1'));
      final c = container(withdrawals: _RacingRepository(store));

      await c.read(pixPendingWithdrawalSyncProvider.future);

      expect(store.load().single.lastStatus, PixWithdrawalStatus.sent);
    },
  );

  test('the list follows a status that the send flow stores', () async {
    await store.save(_record('w-1'));
    repository.statusAnswers.add(
      Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
    );
    final c = container(
      overrides: [
        // Only the send flow reads the status in this test.
        pixPendingWithdrawalSyncProvider.overrideWith((ref) async {}),
      ],
    );
    final list = c.listen(pixPendingWithdrawalsProvider, (_, _) {});
    // The hub read ends first, so only the send flow can change the list.
    await c.read(pixPendingWithdrawalSyncProvider.future);
    expect(list.read(), hasLength(1));

    c.read(pixSendControllerProvider.notifier).resume(_record('w-1'));
    await _settle();

    expect(list.read(), isEmpty);
  });
}
