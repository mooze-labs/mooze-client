import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/events/sync_outcome.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/onboarding_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/services/onboarding_service.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_success_screen.dart';
import 'package:mooze_mobile/features/sync/domain/sync_orchestrator.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/usecases/refresh_wallet.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/dev/swap_simulator_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/transaction_sent_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/values_to_receive_card.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_downgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_upgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/routes.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// No pending swaps, without storage.
class _NoSwaps extends PendingSwapsNotifier {
  @override
  List<PendingSwap> build() => const [];
}

/// Records the end of the onboarding, without storage.
class _FakeOnboardingService extends OnboardingService {
  bool completed = false;

  @override
  Future<void> setOnboardingCompleted() async => completed = true;
}

/// Counts the refreshes that the end of a send asks for, without a wallet.
class _FakeSync extends Fake implements SyncOrchestrator {
  int refreshes = 0;

  @override
  Future<Either<SyncFailure, SyncOutcome>> refresh({
    SyncStrategy strategy = SyncStrategy.light,
  }) {
    refreshes++;
    return Completer<Either<SyncFailure, SyncOutcome>>().future;
  }
}

void main() {
  late _FakeOnboardingService onboarding;
  late _FakeSync sync;

  setUp(() {
    onboarding = _FakeOnboardingService();
    sync = _FakeSync();
  });

  /// Scrolls the preview button with [label] into view and taps it.
  Future<void> tapPreview(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    // The scroll lays out on the next frame.
    await tester.pump();
    await tester.tap(button);
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingSwapsProvider.overrideWith(_NoSwaps.new),
          currencySymbolProvider.overrideWithValue(r'R$'),
          onboardingServiceProvider.overrideWithValue(onboarding),
          refreshWalletProvider.overrideWith(
            (ref) => RefreshWalletUseCase(sync),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          routerConfig: GoRouter(
            initialLocation: '/dev/swap-simulator',
            routes: [
              GoRoute(
                path: '/dev/swap-simulator',
                builder: (_, _) => const SwapSimulatorScreen(),
              ),
              ...walletLevelsRoutes,
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the confirmation of a received transaction opens with '
      'sample data, once per asset', (tester) async {
    await pump(tester);

    await tapPreview(tester, 'Received L-BTC');
    await tester.pumpAndSettle();

    expect(find.byType(TransactionConfirmedScreen), findsOneWidget);
    expect(find.textContaining('25.400', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Voltar para Dashboard'));
    await tester.pumpAndSettle();

    for (final ticker in ['BTC', 'Depix', 'USDT']) {
      expect(find.text('Received $ticker'), findsOneWidget);
    }
  });

  testWidgets('every send preview opens the end of a send with sample data, '
      'and its button returns to the simulator', (tester) async {
    await pump(tester);

    for (final ticker in ['BTC', 'L-BTC', 'Depix', 'USDT']) {
      await tapPreview(tester, 'Sent $ticker');
      await tester.pumpAndSettle();
      final screen = tester.widget<TransactionSentScreen>(
        find.byType(TransactionSentScreen),
      );
      expect(screen.asset.ticker, ticker);
      expect(screen.destinationAddress, isNotEmpty);
      expect(screen.transactionId, hasLength(64));

      await tester.tap(find.text('Voltar para Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionSentScreen), findsNothing);
      expect(find.byType(SwapSimulatorScreen), findsOneWidget);
    }
    // Each preview stays long enough to ask for its refresh, as a real send
    // does. The fake answers it, so no wallet syncs.
    expect(sync.refreshes, 4);
  });

  testWidgets('every swap preview opens the end of a swap and closes', (
    tester,
  ) async {
    await pump(tester);

    for (final (from, to) in [
      ('Depix', 'L-BTC'),
      ('L-BTC', 'USDT'),
      ('USDT', 'Depix'),
      ('BTC', 'L-BTC'),
      ('L-BTC', 'BTC'),
    ]) {
      await tapPreview(tester, 'Swap $from → $to');
      await tester.pumpAndSettle();
      final screen = tester.widget<SwapSuccessScreen>(
        find.byType(SwapSuccessScreen),
      );
      expect(screen.fromAsset.ticker, from);
      expect(screen.toAsset.ticker, to);

      await tester.tap(find.text('Voltar para Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(SwapSuccessScreen), findsNothing);
    }
  });

  testWidgets('every level up and level down opens', (tester) async {
    await pump(tester);

    for (final level in ['Silver', 'Gold', 'Diamond']) {
      await tapPreview(tester, 'Level up → $level');
      await tester.pumpAndSettle();
      expect(find.byType(LevelUpgradeScreen), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }

    for (final level in ['Gold', 'Silver', 'Bronze']) {
      await tapPreview(tester, 'Level down → $level');
      await tester.pumpAndSettle();
      expect(find.byType(LevelDowngradeScreen), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(SwapSimulatorScreen), findsOneWidget);
  });

  testWidgets('the onboarding preview closes at the end, without marking '
      'the onboarding as done', (tester) async {
    await pump(tester);

    await tapPreview(tester, 'Onboarding');
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(SwapSimulatorScreen), findsOneWidget);
    expect(onboarding.completed, isFalse);
  });

  testWidgets('the pending DePix receipts show two sample payments', (
    tester,
  ) async {
    await pump(tester);

    await tapPreview(tester, 'Pending DePix receipts');
    await tester.pumpAndSettle();

    expect(find.byType(ValuesToReceiveCard), findsOneWidget);
    expect(find.text(r'R$ 50,00'), findsOneWidget);
    expect(find.text(r'R$ 129,90'), findsOneWidget);
    expect(find.text(r'Total: R$ 179,90'), findsOneWidget);
  });
}
