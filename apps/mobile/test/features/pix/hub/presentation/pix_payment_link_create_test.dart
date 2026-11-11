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
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Create = ({int? amountInCents, Asset asset, bool singleUse});

/// The payment-link API. Each create waits for [answer].
class _FakeLinks implements PixPaymentLinkRepository {
  final List<_Create> creates = [];

  /// Made by the create, inside the fake time of the test: a completer made
  /// in `setUp` would answer only after the test ends.
  late Completer<Either<PixHubFailure, PixPaymentLink>> answer;

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createLink({
    int? amountInCents,
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
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() =>
      throw UnimplementedError();

  @override
  TaskEither<PixHubFailure, Unit> revokeLink(String id) =>
      throw UnimplementedError();
}

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

  Future<void> open(WidgetTester tester) async {
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

  testWidgets('the review stays off until the link has an identification '
      'and an amount within the limits', (tester) async {
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
    expect(reviewEnabled(), isFalse);

    await tester.enterText(find.byType(TextField).last, '   ');
    await settle(tester);
    expect(reviewEnabled(), isFalse);

    await tester.enterText(find.byType(TextField).last, 'Bolo de pote');
    await settle(tester);
    expect(reviewEnabled(), isTrue);
    expect(find.text(amountError), findsNothing);

    await tester.enterText(find.byType(TextField).first, '100');
    await settle(tester);
    expect(reviewEnabled(), isFalse);
    expect(find.text(amountError), findsOneWidget);

    await tester.tap(find.text(t.pix_hub_charge_open_amount));
    await settle(tester);
    expect(reviewEnabled(), isTrue);
    expect(find.text(amountError), findsNothing);
  });

  testWidgets('an open amount and a reusable link reach the API as such', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(t.pix_hub_charge_open_amount));
    await tester.tap(find.text(t.pix_hub_link_single_use));
    await tester.enterText(find.byType(TextField).last, 'Doações');
    await settle(tester);
    await tester.tap(find.widgetWithText(PrimaryButton, t.pix_hub_link_review));
    await settle(tester);

    await tester.drag(thumb(), const Offset(800, 0));
    await settle(tester);
    expect(links.creates, [
      (amountInCents: null, asset: Asset.depix, singleUse: false),
    ]);
    links.answer.complete(Right(_link));
    await settle(tester);
  });
}
