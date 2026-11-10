import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_lifecycle_controller.dart';
import 'package:mooze_mobile/app/lifecycle/app_state.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/boot/domain/boot_state.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/wallet_import_loading/wallet_import_loading_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/wallet_import_loading/widgets/opening_scene.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

/// A lifecycle controller whose starts the test settles by hand.
class _FakeLifecycle implements AppLifecycleController {
  final _states = StreamController<AppState>.broadcast();
  AppState _current = const AppState(phase: AppPhase.uninitialized);

  /// One completer per call to [start].
  final starts = <Completer<Either<Failure, AppState>>>[];

  @override
  Stream<AppState> get state => _states.stream;

  @override
  AppState get currentState => _current;

  @override
  Future<Either<Failure, AppState>> start() {
    final start = Completer<Either<Failure, AppState>>();
    starts.add(start);
    return start.future;
  }

  void _emit(AppState state) {
    _current = state;
    _states.add(state);
  }

  /// The wallet opens.
  void open() {
    const ready = AppState(phase: AppPhase.ready);
    _emit(ready);
    starts.last.complete(const Right(ready));
  }

  /// The start fails with [message].
  void fail(String message) {
    final failure = BootFailure(message, phase: 'connectingServices');
    _emit(AppState(phase: AppPhase.error, failure: failure));
    starts.last.complete(Left(failure));
  }

  /// There is no phrase on the device.
  void needsSetup() {
    const state = AppState(phase: AppPhase.needsSetup);
    _emit(state);
    starts.last.complete(const Right(state));
  }

  @override
  Future<void> shutdown() async {}

  @override
  Future<Either<Failure, Unit>> deleteWalletAndReimport() async =>
      const Right(unit);

  @override
  Future<void> dispose() => _states.close();
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  late _FakeLifecycle lifecycle;
  late StreamController<BootState> boot;
  late StreamController<SyncState> sync;
  late OpenedRoutes opened;
  late List<String> haptics;

  setUp(() {
    lifecycle = _FakeLifecycle();
    boot = StreamController<BootState>.broadcast();
    sync = StreamController<SyncState>.broadcast();
    opened = OpenedRoutes();
    haptics = [];
  });

  tearDown(() async {
    await boot.close();
    await sync.close();
  });

  Future<void> open(WidgetTester tester) async {
    usePhoneSize(tester);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      setupTestApp(
        router: GoRouter(
          initialLocation: '/setup/wallet-import-loading',
          routes: [
            GoRoute(
              path: '/setup/wallet-import-loading',
              builder: (_, _) => const WalletImportLoadingScreen(),
            ),
            opened.stub('/home'),
            opened.stub('/setup/first-access'),
          ],
        ),
        overrides: [
          appLifecycleControllerProvider.overrideWith((ref) async => lifecycle),
          bootStateProvider.overrideWith((ref) => boot.stream),
          syncStateProvider.overrideWith((ref) => sync.stream),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> bootPhase(WidgetTester tester, BootPhase phase) async {
    boot.add(BootState(phase: phase));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> synced(WidgetTester tester, Set<ChainId> chains) async {
    sync.add(
      SyncState(
        phase: SyncPhase.running,
        perChain: const {},
        firstSyncedChains: chains,
      ),
    );
    await tester.pump();
  }

  OpeningMotion motion(WidgetTester tester) =>
      tester.widget<OpeningScene>(find.byType(OpeningScene)).motion;

  /// Pumps small steps until the home opens. Returns the last motion of
  /// the scene, the time it took, when the burst ended, and whether the
  /// burst ever played while a coin was still flying in.
  Future<
    ({
      OpeningMotion last,
      Duration elapsed,
      Duration? burstEnd,
      bool burstBeforeLanding,
    })
  >
  untilHome(WidgetTester tester) async {
    const step = Duration(milliseconds: 50);
    var last = motion(tester);
    var elapsed = Duration.zero;
    Duration? burstEnd;
    var burstBeforeLanding = false;
    while (opened.last != '/home' && elapsed < const Duration(seconds: 10)) {
      if (find.byType(OpeningScene).evaluate().isNotEmpty) {
        last = motion(tester);
        if (last.finale > 0 &&
            Asset.values.any((asset) => (last.arrivals[asset] ?? 0) < 1)) {
          burstBeforeLanding = true;
        }
        if (last.finale == 1) burstEnd ??= elapsed;
      }
      await tester.pump(step);
      elapsed += step;
    }
    expect(opened.last, '/home');
    return (
      last: last,
      elapsed: elapsed,
      burstEnd: burstEnd,
      burstBeforeLanding: burstBeforeLanding,
    );
  }

  testWidgets('the steps show as a caption and a track, with no technical '
      'text', (tester) async {
    await open(tester);
    expect(find.text(t.wallet_open_step_opening), findsOneWidget);
    expect(lifecycle.starts, hasLength(1));

    await bootPhase(tester, BootPhase.initializingDatabase);
    await bootPhase(tester, BootPhase.loadingCredentials);
    expect(find.text(t.wallet_open_step_opening), findsOneWidget);

    await bootPhase(tester, BootPhase.connectingServices);
    expect(find.text(t.wallet_open_step_connecting), findsOneWidget);
    expect(motion(tester).ring, greaterThan(0));

    for (final technical in [
      t.wallet_import_phase_platform,
      t.wallet_import_phase_database,
      t.wallet_import_phase_credentials,
      t.wallet_import_phase_authenticating,
    ]) {
      expect(find.text(technical), findsNothing);
    }
  });

  testWidgets('the coins fly in as their chains sync, and the home opens '
      'once Liquid has synced', (tester) async {
    await open(tester);
    await bootPhase(tester, BootPhase.connectingServices);
    lifecycle.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(t.wallet_open_step_syncing), findsOneWidget);

    await synced(tester, {ChainId.bitcoin});
    // The coin starts on the next frame, then flies.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(motion(tester).arrivals[Asset.btc], greaterThan(0));
    expect(motion(tester).arrivals[Asset.usdt] ?? 0, 0);
    // Bitcoin alone does not end the opening: it waits for Liquid.
    expect(find.text(t.wallet_open_step_syncing), findsOneWidget);
    expect(find.text(t.wallet_open_step_done), findsNothing);
    expect(opened.last, isNull);

    await synced(tester, {ChainId.bitcoin, ChainId.liquid});
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(t.wallet_open_step_done), findsOneWidget);
    expect(motion(tester).arrivals[Asset.usdt], greaterThan(0));
    expect(opened.last, isNull);

    final ending = await untilHome(tester);
    expect(ending.last.finale, 1);
    // One haptic, with the burst.
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a fast opening still plays its whole ending: every coin '
      'lands and the burst plays before the home opens', (tester) async {
    await open(tester);
    lifecycle.open();
    await tester.pump();
    await synced(tester, {ChainId.bitcoin, ChainId.liquid});
    await tester.pump();

    final ending = await untilHome(tester);
    for (final asset in Asset.values) {
      expect(ending.last.arrivals[asset], 1, reason: asset.name);
    }
    expect(ending.last.finale, 1);
    expect(ending.burstBeforeLanding, isFalse);
    // The screen opened about two frames before the wallet did.
    expect(
      ending.elapsed,
      greaterThanOrEqualTo(
        WalletImportLoadingScreen.minimumShow -
            const Duration(milliseconds: 100),
      ),
    );
  });

  testWidgets('a failed start retries by itself, and says so', (tester) async {
    await open(tester);

    lifecycle.fail('all chain services failed: liquid connect timeout');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(t.wallet_open_retrying), findsOneWidget);
    expect(find.text(t.wallet_open_error_title), findsNothing);

    await tester.pump(WalletImportLoadingScreen.retryDelay);
    expect(lifecycle.starts, hasLength(2));

    lifecycle.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(t.wallet_open_step_syncing), findsOneWidget);
  });

  testWidgets('after three failed starts, a panel explains a connection '
      'problem, and its button starts again', (tester) async {
    await open(tester);
    for (var attempt = 1; attempt <= 3; attempt++) {
      lifecycle.fail('all chain services failed: liquid connect timeout');
      await tester.pump();
      if (attempt < 3) {
        await tester.pump(WalletImportLoadingScreen.retryDelay * attempt);
      }
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(lifecycle.starts, hasLength(3));
    expect(find.text(t.wallet_open_error_title), findsOneWidget);
    expect(find.text(t.wallet_open_error_connection), findsOneWidget);

    await tester.tap(find.text(t.common_retry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(lifecycle.starts, hasLength(4));
    expect(find.text(t.wallet_open_error_title), findsNothing);
  });

  testWidgets('another failure gets the general message', (tester) async {
    await open(tester);
    for (var attempt = 1; attempt <= 3; attempt++) {
      lifecycle.fail('database open failed: disk full');
      await tester.pump();
      if (attempt < 3) {
        await tester.pump(WalletImportLoadingScreen.retryDelay * attempt);
      }
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(t.wallet_open_error_generic), findsOneWidget);
  });

  testWidgets('a missing phrase sends the user to import the wallet again', (
    tester,
  ) async {
    await open(tester);
    lifecycle.needsSetup();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(lifecycle.starts, hasLength(1));
    expect(find.text(t.wallet_open_error_missing), findsOneWidget);
    await tester.tap(find.text(t.wallet_open_import_again));
    await tester.pump();
    await tester.pump();
    expect(opened.last, '/setup/first-access');
  });

  testWidgets('when the balances take too long, the home opens anyway', (
    tester,
  ) async {
    await open(tester);
    lifecycle.open();
    await tester.pump();

    await tester.pump(WalletImportLoadingScreen.syncPatience);
    final ending = await untilHome(tester);
    expect(ending.last.finale, 1);
    expect(ending.burstBeforeLanding, isFalse);
    // Long past the least time of the screen, "All set" still stays for
    // a beat after the burst.
    expect(
      ending.elapsed - ending.burstEnd!,
      greaterThanOrEqualTo(
        WalletImportLoadingScreen.doneHold - const Duration(milliseconds: 50),
      ),
    );
  });

  testWidgets('a long first opening says that it takes longer the first '
      'time', (tester) async {
    await open(tester);
    await tester.pump(WalletImportLoadingScreen.slowAfter);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(t.wallet_open_hint_slow), findsOneWidget);
  });

  testWidgets('with reduced motion, nothing moves, and the home opens at '
      'once', (tester) async {
    reduceMotion(tester);
    await open(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);

    lifecycle.open();
    await tester.pump();
    await synced(tester, {ChainId.liquid});
    await tester.pump();
    expect(motion(tester).arrivals[Asset.lbtc], 1);
    expect(opened.last, '/home');
  });
}
