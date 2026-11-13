import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/entities.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:mooze_mobile/shared/user/widgets/user_data_auto_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An answer of `/users/me`, with [toReceive] in BRL cents per asset id.
User _user({Map<String, int> toReceive = const {}}) => User.fromJson({
  'data': {
    'user_id': 'u-1',
    'verification_level': 1,
    'allowed_spending': 50000,
    'daily_spending': 0,
    'spending_level': 1,
    'level_progress': 0.0,
    'to_receive': toReceive,
  },
});

/// The user API. It counts the calls and answers [next].
class _Users implements UserService {
  int calls = 0;
  User next = _user();

  @override
  TaskEither<String, User> getUser() {
    calls++;
    return TaskEither.right(next);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The Pix deposits, whose status changes the test pushes.
class _Pix implements PixRepository {
  final updates = StreamController<PixStatusEvent>.broadcast();

  @override
  Stream<PixStatusEvent> get statusUpdates => updates.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SyncState _synced(DateTime? at, {SyncPhase phase = SyncPhase.idle}) =>
    SyncState(phase: phase, perChain: const {}, lastSuccessAt: at);

void main() {
  late _Users users;
  late _Pix pix;
  late StreamController<SyncState> sync;
  late ProviderContainer container;

  /// The clock of the widget. [wait] moves it with the timers.
  late DateTime now;

  Future<void> wait(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
  }

  /// Shows the main screens. With [readsUser], a screen reads the user, as
  /// the card of the values to receive does.
  Future<void> show(WidgetTester tester, {bool readsUser = true}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    users = _Users();
    pix = _Pix();
    sync = StreamController<SyncState>.broadcast();
    now = DateTime(2026, 11, 13, 10);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userServiceProvider.overrideWithValue(users),
        pixRepositoryProvider.overrideWithValue(pix),
        syncStateProvider.overrideWith((ref) => sync.stream),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(sync.close);
    addTearDown(pix.updates.close);
    if (readsUser) await container.read(userDataProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: UserDataAutoRefresh(now: () => now, child: const SizedBox()),
      ),
    );
  }

  Map<String, int> shownToReceive() =>
      container.read(userDataProvider).requireValue.getOrElse((l) {
        throw StateError(l);
      }).valuesToReceive;

  Future<void> pixStatus(WidgetTester tester, DepositStatus status) async {
    pix.updates.add(PixStatusEvent(depositId: 'd1', status: status));
    await tester.pump();
  }

  Future<void> synced(WidgetTester tester, DateTime at) async {
    sync.add(_synced(at));
    await tester.pump();
  }

  // The app polls a Pix deposit after it shows the QR code. Once the payer
  // pays, the API lists the amount in `to_receive` until the asset arrives.
  // Each new status of a deposit is a moment where that list may change.
  group('a Pix deposit', () {
    testWidgets('a new status brings the values to receive at once', (
      tester,
    ) async {
      await show(tester);
      expect(shownToReceive(), isEmpty);

      users.next = _user(toReceive: {Asset.depix.id: 10000});
      await pixStatus(tester, DepositStatus.processing);

      expect(shownToReceive(), {Asset.depix.id: 10000});
    });

    // `/users/me` runs the XP check on the server, so the app asks at most
    // once per 30 s. A status inside that gap is not lost: the statuses of
    // the gap become one request at its end.
    testWidgets('statuses inside 30 s become one request at its end', (
      tester,
    ) async {
      await show(tester);
      final before = users.calls;

      await pixStatus(tester, DepositStatus.processing);
      expect(users.calls - before, 1);

      await wait(tester, const Duration(seconds: 5));
      users.next = _user(toReceive: {Asset.depix.id: 10000});
      await pixStatus(tester, DepositStatus.fundsPrepared);
      await pixStatus(tester, DepositStatus.depixSent);
      expect(users.calls - before, 1);

      await wait(tester, const Duration(seconds: 24));
      expect(users.calls - before, 1);
      await wait(tester, const Duration(seconds: 1));
      expect(users.calls - before, 2);
      expect(shownToReceive(), {Asset.depix.id: 10000});

      // Nothing new came: the gap ends with no request.
      await wait(tester, const Duration(seconds: 60));
      expect(users.calls - before, 2);
    });

    testWidgets('statuses 30 s apart each ask at once', (tester) async {
      await show(tester);
      final before = users.calls;

      await pixStatus(tester, DepositStatus.processing);
      await wait(tester, const Duration(seconds: 30));
      await pixStatus(tester, DepositStatus.finished);

      expect(users.calls - before, 2);
    });
  });

  // A payment link, or a deposit made on another phone, has no poll here.
  // The wallet sync ends every minute.
  group('the wallet sync', () {
    // While an amount waits, each sync asks: the card leaves soon after the
    // asset arrives.
    testWidgets('with an amount to receive, each finished sync asks', (
      tester,
    ) async {
      await show(tester);
      users.next = _user(toReceive: {Asset.depix.id: 10000});
      await container.read(userDataProvider.notifier).refresh();
      final before = users.calls;
      final first = now;

      sync.add(_synced(null, phase: SyncPhase.running));
      await tester.pump();
      expect(users.calls - before, 0);

      await synced(tester, first);
      expect(users.calls - before, 1);

      // The same sync, now cooling: nothing new.
      sync.add(_synced(first, phase: SyncPhase.cooling));
      await tester.pump();
      expect(users.calls - before, 1);

      await wait(tester, const Duration(minutes: 1));
      await synced(tester, now);
      expect(users.calls - before, 2);
    });

    // Nothing waits: the sync only looks for a payment that came from
    // elsewhere, every 5 minutes.
    testWidgets('with nothing to receive, a sync asks every 5 minutes', (
      tester,
    ) async {
      await show(tester);
      final before = users.calls;

      await synced(tester, now);
      expect(users.calls - before, 1);

      for (var minute = 1; minute < 5; minute++) {
        await wait(tester, const Duration(minutes: 1));
        await synced(tester, now);
      }
      expect(users.calls - before, 1);

      await wait(tester, const Duration(minutes: 1));
      await synced(tester, now);
      expect(users.calls - before, 2);
    });
  });

  // The payer often pays in the bank app and comes back.
  testWidgets('coming back to the app asks again', (tester) async {
    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final before = users.calls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(users.calls - before, 1);
  });

  // Nothing shows the user yet: the screen that reads it asks for it.
  testWidgets('before any screen reads the user, nothing asks', (tester) async {
    await show(tester, readsUser: false);

    await pixStatus(tester, DepositStatus.processing);
    await synced(tester, now);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await wait(tester, const Duration(minutes: 1));

    expect(users.calls, 0);
  });

  // The main screens close with a request waiting for the end of its gap.
  testWidgets('a request that waits is dropped with the screens', (
    tester,
  ) async {
    await show(tester);
    await pixStatus(tester, DepositStatus.processing);
    await pixStatus(tester, DepositStatus.depixSent);
    final before = users.calls;

    await tester.pumpWidget(const SizedBox());
    await wait(tester, const Duration(seconds: 30));

    expect(users.calls - before, 0);
  });
}
