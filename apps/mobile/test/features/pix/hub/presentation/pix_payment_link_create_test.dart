import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link_amount.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_payment_link_form_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_create_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';

typedef _Create = ({int amountInCents, Asset asset, bool singleUse});

/// The payment-link API. Each create waits for [answer].
class _FakeLinks implements PixPaymentLinkRepository {
  final List<_Create> creates = [];

  /// Made by the create, inside the fake time of the test: a completer made
  /// in `setUp` would answer only after the test ends.
  late Completer<Either<PixHubFailure, PixPaymentLink>> answer;

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) {
    creates.add((
      amountInCents: amountInCents,
      asset: asset,
      singleUse: singleUse,
    ));
    answer = Completer();
    return TaskEither(() => answer.future);
  }

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() =>
      throw UnimplementedError();

  @override
  TaskEither<PixHubFailure, Unit> revokeLink(String id) =>
      throw UnimplementedError();
}

/// The levels of an account, with its Pix receive limits in reais.
UserLevelsData _levels({
  int level = 1,
  double minimum = 20,
  double perTransaction = 500,
}) => UserLevelsData(
  spendingLevel: level,
  levelProgress: 0,
  allowedSpending: perTransaction,
  dailySpending: 0,
  currentLevelMinLimit: 0,
  currentLevelMaxLimit: perTransaction,
  absoluteMinLimit: minimum,
  absoluteMaxLimit: 3000,
  remainingLimit: 5000,
);

final _link = PixPaymentLink(
  id: 'link-1',
  url: 'https://pay.mooze.app/pay/tok',
  reference: '',
  status: PixPaymentLinkStatus.pending,
  createdAt: DateTime.utc(2026, 11, 11),
  singleUse: true,
  amountInCents: 4590,
  asset: Asset.depix,
);

void main() {
  useCoreSyncHelpers();

  final t = lookupAppLocalizations(const Locale('pt'));
  late _FakeLinks links;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    links = _FakeLinks();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Opens the screen for an account with [levels]. By default the account
  /// is Silver, with R\$ 20,00 to R\$ 500,00 per Pix received.
  Future<void> open(
    WidgetTester tester, {
    Future<UserLevelsData> Function()? levels,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/pix/links/new',
      routes: [
        GoRoute(
          path: '/pix/links/new',
          builder: (_, _) => const PixPaymentLinkCreateScreen(),
        ),
        GoRoute(
          path: '/wallet-levels',
          builder: (_, _) => const Scaffold(body: Text('wallet levels')),
        ),
        GoRoute(
          path: '/pix/links/detail',
          builder: (_, state) => Scaffold(
            body: Text('detail ${(state.extra as PixPaymentLink).id}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          levelsProvider.overrideWith(
            (ref) => levels?.call() ?? Future.value(_levels()),
          ),
          pixPaymentLinkFormControllerProvider.overrideWith(
            (ref) => PixPaymentLinkFormController(
              repository: links,
              references: PixPaymentLinkReferenceStore(prefs),
              receiveAddress: () async => const Right('lq1qqaddress'),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
      ),
    );
    await settle(tester);
  }

  /// Fills the form with R$ 45,90 and a reference, and opens the review.
  Future<void> review(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, '4590');
    await tester.enterText(find.byType(TextField).last, 'Bolo de pote');
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, t.pix_hub_link_review));
    await settle(tester);
  }

  Finder thumb() => find.descendant(
    of: find.byType(SlideToConfirmButton),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector && widget.onHorizontalDragEnd != null,
    ),
  );

  testWidgets('the review generates the link with a slide, not a tap, and '
      'waits on it until the link exists', (tester) async {
    await open(tester);
    await review(tester);

    expect(
      find.widgetWithText(PrimaryButton, t.pix_hub_link_confirm),
      findsNothing,
    );
    final slide = find.byType(SlideToConfirmButton);
    expect(
      tester.widget<SlideToConfirmButton>(slide).text,
      t.pix_hub_link_confirm,
    );

    await tester.tap(slide);
    await settle(tester);
    expect(links.creates, isEmpty);

    await tester.drag(thumb(), const Offset(800, 0));
    await settle(tester);
    expect(links.creates, [
      (amountInCents: 4590, asset: Asset.depix, singleUse: true),
    ]);
    expect(tester.widget<SlideToConfirmButton>(slide).isLoading, isTrue);
    final cancel = find.widgetWithText(TextButton, t.common_cancel);
    expect(tester.widget<TextButton>(cancel).onPressed, isNull);

    links.answer.complete(Right(_link));
    await settle(tester);

    expect(find.text('detail link-1'), findsOneWidget);
    expect(find.byType(SlideToConfirmButton), findsNothing);
  });

  testWidgets('a failed link closes the review and shows why, and the form '
      'keeps what was typed', (tester) async {
    await open(tester);
    await review(tester);

    await tester.drag(thumb(), const Offset(800, 0));
    await settle(tester);
    links.answer.complete(
      const Left(PixHubFailure(PixHubErrorCode.serviceUnavailable)),
    );
    await settle(tester);

    expect(find.byType(SlideToConfirmButton), findsNothing);
    expect(find.text(t.pix_hub_failure_unavailable), findsOneWidget);
    expect(find.text('Bolo de pote'), findsOneWidget);
  });

  // The identification only organizes the links of the owner, so the
  // review waits for the amount alone.
  testWidgets('the review waits only for an amount within the limits: the '
      'identification is optional', (tester) async {
    await open(tester);
    bool reviewEnabled() => tester
        .widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, t.pix_hub_link_review),
        )
        .isEnabled;
    final amountError = t.pix_hub_link_amount_error(
      formatBrlCents(PaymentLinkAmount.minAmountInCents),
      formatBrlCents(PaymentLinkAmount.maxAmountInCents),
    );

    expect(reviewEnabled(), isFalse);

    await tester.enterText(find.byType(TextField).first, '4590');
    await settle(tester);
    expect(reviewEnabled(), isTrue);
    expect(find.text(amountError), findsNothing);

    await tester.enterText(find.byType(TextField).first, '100');
    await settle(tester);
    expect(reviewEnabled(), isFalse);
    expect(
      find.text(t.pix_receive_validation_below_min('20,00')),
      findsOneWidget,
    );
  });

  testWidgets('the identification says that it is optional', (tester) async {
    await open(tester);

    expect(find.text(t.pix_hub_link_reference_caption), findsOneWidget);
  });

  // The API no longer takes links whose payer chooses the amount.
  testWidgets('no option lets the payer choose the amount', (tester) async {
    await open(tester);

    expect(find.text('Quem paga escolhe o valor'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('a link with no identification is named "Link de pagamento" '
      'and keeps no name on the device', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, '4590');
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, t.pix_hub_link_review));
    await settle(tester);

    expect(find.text(t.pix_hub_link_no_reference), findsOneWidget);

    await tester.drag(thumb(), const Offset(800, 0));
    await settle(tester);
    links.answer.complete(Right(_link));
    await settle(tester);

    expect(find.text('detail link-1'), findsOneWidget);
    expect(PixPaymentLinkReferenceStore(prefs).load(), isEmpty);
  });

  bool reviewEnabled(WidgetTester tester) => tester
      .widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, t.pix_hub_link_review),
      )
      .isEnabled;

  Future<void> typeAmount(WidgetTester tester, String cents) async {
    await tester.enterText(find.byType(TextField).first, cents);
    await tester.enterText(find.byType(TextField).last, 'Bolo de pote');
    await settle(tester);
  }

  // A link receives a Pix, so its amount follows the same limits as a Pix
  // received on the deposit screen.
  testWidgets('a fixed amount follows the Pix receive limits of the account', (
    tester,
  ) async {
    await open(
      tester,
      levels: () async => _levels(minimum: 25, perTransaction: 500),
    );

    await typeAmount(tester, '60000');
    expect(reviewEnabled(tester), isFalse);
    expect(
      find.text(t.pix_receive_validation_above_transaction('500,00')),
      findsOneWidget,
    );

    await typeAmount(tester, '2100');
    expect(reviewEnabled(tester), isFalse);
    expect(
      find.text(t.pix_receive_validation_below_min('25,00')),
      findsOneWidget,
    );

    await typeAmount(tester, '50000');
    expect(reviewEnabled(tester), isTrue);
    expect(find.textContaining('Limite por transação'), findsNothing);
    expect(find.textContaining('Valor mínimo'), findsNothing);
  });

  testWidgets('the bounds of the API still apply under a larger receive '
      'limit', (tester) async {
    await open(tester, levels: () async => _levels(perTransaction: 10000));

    await typeAmount(tester, '600000');
    expect(reviewEnabled(tester), isFalse);
    expect(
      find.text(
        t.pix_hub_link_amount_error(
          formatBrlCents(PaymentLinkAmount.minAmountInCents),
          formatBrlCents(PaymentLinkAmount.maxAmountInCents),
        ),
      ),
      findsOneWidget,
    );
  });

  // Until the limits arrive the app cannot tell them, as on the deposit
  // screen. The API checks the amount again when it creates the link.
  testWidgets('while the limits load, only the bounds of the API apply, and '
      'the amount is checked again when they arrive', (tester) async {
    final levels = Completer<UserLevelsData>();
    await open(tester, levels: () => levels.future);

    await typeAmount(tester, '60000');
    expect(reviewEnabled(tester), isTrue);

    levels.complete(_levels(perTransaction: 500));
    await settle(tester);
    expect(reviewEnabled(tester), isFalse);
    expect(
      find.text(t.pix_receive_validation_above_transaction('500,00')),
      findsOneWidget,
    );
  });

  // Payment links start at the Silver level. A Bronze account learns it
  // before it fills a form it cannot send.
  testWidgets('a Bronze account sees that links start at Silver, instead of '
      'the form', (tester) async {
    await open(tester, levels: () async => _levels(level: 0));

    expect(find.text(t.pix_hub_link_level_locked_title), findsOneWidget);
    expect(find.text(t.pix_hub_link_level_locked_body), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.widgetWithText(PrimaryButton, t.pix_hub_link_review),
      findsNothing,
    );

    await tester.tap(
      find.widgetWithText(PrimaryButton, t.pix_hub_link_level_view),
    );
    await settle(tester);
    expect(find.text('wallet levels'), findsOneWidget);
  });

  testWidgets('a Silver account sees the form and no level notice', (
    tester,
  ) async {
    await open(tester);

    expect(find.text(t.pix_hub_link_level_locked_title), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('a reusable link reaches the API as such', (tester) async {
    await open(tester);
    await tester.tap(find.text(t.pix_hub_link_single_use));
    await typeAmount(tester, '4590');
    await tester.tap(find.widgetWithText(PrimaryButton, t.pix_hub_link_review));
    await settle(tester);

    await tester.drag(thumb(), const Offset(800, 0));
    await settle(tester);
    expect(links.creates, [
      (amountInCents: 4590, asset: Asset.depix, singleUse: false),
    ]);
    links.answer.complete(Right(_link));
    await settle(tester);
  });
}
