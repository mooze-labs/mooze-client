import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/conversion_strip.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/converting_details_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/converting_completed_view.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Price quotes without network or cache access.
class _FakeQuotes extends StateNotifier<PriceQuotes>
    implements PriceQuotesNotifier {
  _FakeQuotes() : super(PriceQuotes.initial(Currency.brl));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The pending swaps, without storage.
class _FakeSwaps extends PendingSwapsNotifier {
  _FakeSwaps(this.swaps);

  final List<PendingSwap> swaps;

  @override
  List<PendingSwap> build() => swaps;

  /// The reconciler retires every swap: their credits reached the wallet.
  void retireAll() => state = [];
}

/// A peg-in of 100 000 sats in [phase].
PendingSwap _swap(
  PendingSwapPhase phase, {
  String? txId,
  String? errorMessage,
}) => PendingSwap(
  localId: 'local-1',
  fromAsset: Asset.btc,
  toAsset: Asset.lbtc,
  sentAmount: BigInt.from(100000),
  estimatedReceivedAmount: BigInt.from(99000),
  destination: 'lq1qqdestination',
  phase: phase,
  createdAt: DateTime(2026, 11, 9, 14, 30),
  breezSwapId: 'swap-1',
  breezTxId: txId,
  errorMessage: errorMessage,
);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  late _FakeSwaps store;

  /// The details of `local-1` with [swaps] pending, in [locale].
  Future<void> pump(
    WidgetTester tester,
    List<PendingSwap> swaps, {
    Locale locale = const Locale('pt'),
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingSwapsProvider.overrideWith(() => store = _FakeSwaps(swaps)),
          priceQuotesProvider.overrideWith((ref) => _FakeQuotes()),
          currencySymbolProvider.overrideWithValue(r'R$'),
          localeStringProvider.overrideWithValue('pt_BR'),
        ],
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          routerConfig: GoRouter(
            initialLocation: '/details',
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const Text('home')),
              GoRoute(
                path: '/details',
                builder: (_, _) =>
                    const ConvertingDetailsScreen(localId: 'local-1'),
              ),
            ],
          ),
        ),
      ),
    );
    // The step in progress breathes, so the screen never settles.
    await tester.pump(const Duration(seconds: 2));
  }

  List<TxStepState> steps(WidgetTester tester) => [
    for (final step
        in tester.widget<TxStatusPanel>(find.byType(TxStatusPanel)).steps)
      step.state,
  ];

  testWidgets('a swap in progress has the layout of a transaction detail: '
      'the coins and the expected amount, the status track, the conversion, '
      'a note, and the identifiers', (tester) async {
    await pump(tester, [_swap(PendingSwapPhase.broadcasted, txId: 'tx-1')]);

    expect(find.byType(TxDetailScaffold), findsOneWidget);
    expect(find.text(t.converting_details_title), findsOneWidget);
    expect(find.byType(HeroSwapIcon), findsOneWidget);
    expect(find.text(t.tx_detail_expected), findsOneWidget);
    expect(
      tester.widget<TxStatusPanel>(find.byType(TxStatusPanel)).title,
      t.converting_details_phase_awaiting_confirmations,
    );
    expect(steps(tester), [
      TxStepState.done,
      TxStepState.done,
      TxStepState.active,
    ]);
    final strip = tester.widget<ConversionStrip>(find.byType(ConversionStrip));
    expect(strip.from.amountInSats, BigInt.from(100000));
    expect(strip.to.amountInSats, BigInt.from(99000));
    expect(
      find.text(t.converting_details_explanation_broadcasted_peg_in),
      findsOneWidget,
    );
    expect(find.text(t.converting_details_swap_id), findsOneWidget);
    expect(find.text(t.converting_details_bitcoin_send_tx), findsOneWidget);
    // The lockup of a peg-in is on Bitcoin.
    final explorer = tester.widget<InCardActionButton>(
      find.byType(InCardActionButton),
    );
    expect(explorer.subtitle, 'Bitcoin');
  });

  testWidgets('each phase moves the track', (tester) async {
    await pump(tester, [_swap(PendingSwapPhase.preparing)]);
    expect(steps(tester), [
      TxStepState.active,
      TxStepState.upcoming,
      TxStepState.upcoming,
    ]);
    // Without a lockup transaction there is nothing to open.
    expect(find.byType(InCardActionButton), findsNothing);

    // A new scope, so the swaps load again.
    await tester.pumpWidget(const SizedBox());
    await pump(tester, [_swap(PendingSwapPhase.broadcasting)]);
    expect(steps(tester), [
      TxStepState.done,
      TxStepState.active,
      TxStepState.upcoming,
    ]);
  });

  testWidgets('a failed swap shows the error and strikes the amount '
      'through', (tester) async {
    await pump(tester, [
      _swap(PendingSwapPhase.failed, errorMessage: 'Fee too low'),
    ]);

    expect(find.text('Fee too low'), findsOneWidget);
    expect(steps(tester)[1], TxStepState.failed);
    expect(
      tester.widget<HeroAmount>(find.byType(HeroAmount)).struckThrough,
      isTrue,
    );
  });

  testWidgets('a refundable swap explains the refund instead of the '
      'phase', (tester) async {
    await pump(tester, [_swap(PendingSwapPhase.refundable)]);

    expect(find.text(t.converting_details_refund_title), findsOneWidget);
    expect(find.text(t.converting_details_refund_message), findsOneWidget);
    expect(
      find.text(t.converting_details_explanation_refundable),
      findsNothing,
    );
    expect(steps(tester).last, TxStepState.failed);
    expect(
      tester.widget<HeroSwapIcon>(find.byType(HeroSwapIcon)).isRefund,
      isTrue,
    );
  });

  testWidgets('a swap that finishes while the screen is open turns into '
      'the scene of its two coins, and its button leads home', (tester) async {
    await pump(tester, [_swap(PendingSwapPhase.broadcasted, txId: 'tx-1')]);

    store.retireAll();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final completed = tester.widget<ConvertingCompletedView>(
      find.byType(ConvertingCompletedView),
    );
    expect(completed.fromAsset, Asset.btc);
    expect(completed.toAsset, Asset.lbtc);
    expect(find.byType(TxDetailScaffold), findsNothing);
    expect(find.text(t.converting_details_completed_title), findsOneWidget);
    expect(find.text(t.converting_details_completed_message), findsOneWidget);

    await tester.tap(find.text(t.converting_details_back_to_home));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  // Opened after the swap left, the screen knows neither of its coins.
  testWidgets('a swap already gone when the screen opens shows the '
      'completed state without the scene, and its button leads home', (
    tester,
  ) async {
    await pump(tester, []);

    expect(
      tester.widget<PixStatusView>(find.byType(PixStatusView)).kind,
      PixStatusKind.success,
    );
    expect(find.text(t.converting_details_completed_title), findsOneWidget);
    expect(find.byType(ConvertingCompletedView), findsNothing);

    await tester.tap(find.text(t.converting_details_back_to_home));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the screen speaks the language of the app', (tester) async {
    final en = lookupAppLocalizations(const Locale('en'));
    await pump(tester, [
      _swap(PendingSwapPhase.broadcasted),
    ], locale: const Locale('en'));

    expect(find.text(en.converting_details_title), findsOneWidget);
    expect(find.text(en.tx_detail_expected), findsOneWidget);
    expect(find.text(en.converting_details_help_footer), findsOneWidget);
  });
}
