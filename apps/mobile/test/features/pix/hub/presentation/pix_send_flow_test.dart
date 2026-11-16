import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_amount_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_copy_paste_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_key_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_result_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_review_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_send_scene.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_underline_field.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../../../../shared/widgets/motion/motion_test_helpers.dart';
import '../check_digit_core_sync_helpers.dart';
import '../pix_send_fakes.dart';

const _cpf = '52998224725';
const _email = 'ana@exemplo.com.br';

/// 10,000 DePix.
const int _richBalance = 10000 * 100 * PixWithdrawal.depixUnitsPerCent;

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  late FakeWithdrawalRepository repository;
  late FakeWithdrawalWallet wallet;
  late PixWithdrawalRecordStore store;
  late DateTime now;
  late List<void Function()> scheduled;
  late PixSendController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PixWithdrawalRecordStore(await SharedPreferences.getInstance());
    repository = FakeWithdrawalRepository();
    wallet = FakeWithdrawalWallet();
    // The review screen counts down on the device clock.
    now = DateTime.now();
    repository.onCreate = (payout) =>
        Right(testWithdrawal(payout: payout, now: now));
    scheduled = [];
    controller = PixSendController(
      repository: repository,
      wallet: wallet,
      records: store,
      now: () => now,
      schedule: (delay, callback) {
        scheduled.add(callback);
        return FakeTimer();
      },
    );
  });

  // The ProviderScope of each test owns the controller and disposes it.

  Widget host({
    required String initial,
    int balance = _richBalance,
    Locale locale = const Locale('en'),
  }) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/pix',
          builder: (_, _) => const Scaffold(body: Text('hub')),
        ),
        GoRoute(
          path: '/pix/send/key',
          builder: (_, _) => const PixSendKeyScreen(),
        ),
        // The camera screen needs a device, so a placeholder stands in.
        GoRoute(
          path: '/pix/send/scan',
          builder: (_, _) => const Scaffold(body: Text('scanner')),
        ),
        GoRoute(
          path: '/pix/send/code',
          builder: (_, _) => const PixSendCopyPasteScreen(),
        ),
        GoRoute(
          path: '/pix/send/amount',
          builder: (_, _) => const PixSendAmountScreen(),
        ),
        GoRoute(
          path: '/pix/send/review',
          builder: (_, _) => const PixSendReviewScreen(),
        ),
        GoRoute(
          path: '/pix/send/result',
          builder: (_, _) => const PixSendResultScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        pixSendControllerProvider.overrideWith((ref) => controller),
        pixDepixBalanceProvider.overrideWith((ref) async => balance),
        pixPendingWithdrawalsProvider.overrideWith((ref) => const []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
      ),
    );
  }

  /// Pumps frames without waiting for the review countdown to stop.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> quoted({PixKeyType type = PixKeyType.cpf, String key = _cpf}) {
    controller.startFromKey(type, key);
    if (type != PixKeyType.cpf) controller.setTaxId(_cpf);
    controller.setAmount(4590);
    return controller.requestQuote();
  }

  /// Slides the thumb of the review to its end, as a user confirms.
  Future<void> slideToPay(WidgetTester tester) => tester.drag(
    find.descendant(
      of: find.byType(SlideToConfirmButton),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onHorizontalDragEnd != null,
      ),
    ),
    const Offset(800, 0),
  );

  /// A tall view keeps every row of the screens built.
  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('key and amount', () {
    String? fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller?.text;

    testWidgets('masks a CPF and keeps the digits for the payment', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      await tester.enterText(find.byType(TextField), '52998224725');
      await tester.pump();

      expect(fieldText(tester), '529.982.247-25');
      expect(find.text('Format recognised: CPF.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(controller.state.draft?.keyType, PixKeyType.cpf);
      expect(controller.state.draft?.pixKey, _cpf);
    });

    testWidgets('masks a mobile number and sends it with +55', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      await tester.enterText(find.byType(TextField), '11999998888');
      await tester.pump();

      expect(fieldText(tester), '(11) 99999-8888');
      expect(find.text('Format recognised: Phone.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(controller.state.draft?.keyType, PixKeyType.phone);
      expect(controller.state.draft?.pixKey, '+5511999998888');
    });

    /// Types [text] in the destination field and lets the screen rebuild.
    Future<void> typeDestination(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      // The button and the feedback line read the text on the next frame.
      await tester.pump();
    }

    testWidgets('one field detects an email key', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      expect(find.text('Who do you want to send to?'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      await typeDestination(tester, _email);
      expect(find.text('Format recognised: Email.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('CPF or CNPJ of the key owner'), findsOneWidget);
      expect(controller.state.draft?.pixKey, _email);
      expect(controller.state.draft?.keyType, PixKeyType.email);
    });

    testWidgets('a number that is a CPF and a phone asks which one', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      await typeDestination(tester, '11954736800');
      expect(find.text('Is this number a CPF or a phone?'), findsOneWidget);
      // The CPF reading is the default, so the CPF mask shows first.
      expect(fieldText(tester), '119.547.368-00');

      await tester.tap(find.widgetWithText(ChoiceChip, 'Phone'));
      await tester.pump();
      expect(fieldText(tester), '(11) 95473-6800');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Phone'))
            .selected,
        isTrue,
      );

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(controller.state.draft?.keyType, PixKeyType.phone);
      expect(controller.state.draft?.pixKey, '+5511954736800');
    });

    testWidgets('a pasted Pix code goes to the amount step', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      await typeDestination(
        tester,
        PixBrCodeParser.build(
          pixKey: _email,
          merchantName: 'Padaria',
          merchantCity: 'Rio',
          amountInCents: 8450,
        ),
      );
      expect(find.text('Pix Copy and Paste code recognised.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(controller.state.draft?.amountInCents, 8450);
      expect(controller.state.draft?.amountIsFixed, isTrue);
      expect(find.text('CPF or CNPJ of the key owner'), findsOneWidget);
    });

    testWidgets('an invalid entry shows its error after continue', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      String? errorText() => tester
          .widget<TextField>(find.byType(TextField))
          .decoration
          ?.errorText;

      await typeDestination(tester, '111.444.777-30');
      // No error while the user types.
      expect(errorText(), isNull);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(controller.state.draft, isNull);
      expect(find.text('Who do you want to send to?'), findsOneWidget);
      expect(errorText(), isNotNull);
    });

    testWidgets('the QR icon opens the scanner', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/key'));
      await settle(tester);

      await tester.tap(find.byTooltip('Scan QR Code'));
      await settle(tester);

      expect(find.text('scanner'), findsOneWidget);
    });

    Finder amountField() => find.descendant(
      of: find.byType(PixAmountField),
      matching: find.byType(TextField),
    );
    Finder taxIdField() => find.descendant(
      of: find.byType(PixUnderlineField),
      matching: find.byType(TextField),
    );

    testWidgets('puts the amount first and keeps continue off at zero', (
      tester,
    ) async {
      useTallView(tester);
      controller.startFromKey(PixKeyType.email, _email);
      await tester.pumpWidget(host(initial: '/pix/send/amount'));
      await settle(tester);

      expect(find.text('How much do you want to send?'), findsOneWidget);
      expect(
        tester.getTopLeft(amountField()).dy,
        lessThan(tester.getTopLeft(taxIdField()).dy),
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled,
        isFalse,
      );

      await tester.enterText(amountField(), '4590');
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled,
        isTrue,
      );
    });

    testWidgets('marks a valid document with a check', (tester) async {
      useTallView(tester);
      controller.startFromKey(PixKeyType.email, _email);
      await tester.pumpWidget(host(initial: '/pix/send/amount'));
      await settle(tester);

      expect(find.bySemanticsLabel('Valid document'), findsNothing);

      await tester.enterText(taxIdField(), _cpf);
      await tester.pump();

      expect(find.bySemanticsLabel('Valid document'), findsOneWidget);
    });

    testWidgets('validates the document and the amount', (tester) async {
      useTallView(tester);
      controller.startFromKey(PixKeyType.email, _email);
      await tester.pumpWidget(host(initial: '/pix/send/amount'));
      await settle(tester);

      await tester.enterText(amountField(), '150');
      await tester.pump();
      // Too low is not an error while the user may still be typing.
      expect(
        find.text('The minimum amount is ${formatBrlCents(200)}.'),
        findsNothing,
      );

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('Enter the CPF or CNPJ.'), findsOneWidget);

      await tester.enterText(taxIdField(), '11111111112');
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('Invalid CPF or CNPJ.'), findsOneWidget);
      expect(
        find.text('The minimum amount is ${formatBrlCents(200)}.'),
        findsOneWidget,
      );
      expect(repository.creates, isEmpty);
    });

    testWidgets('an amount above the DePix balance is refused', (tester) async {
      useTallView(tester);
      controller.startFromKey(PixKeyType.cpf, _cpf);
      await tester.pumpWidget(
        host(
          initial: '/pix/send/amount',
          balance: 10 * 100 * PixWithdrawal.depixUnitsPerCent,
        ),
      );
      await settle(tester);

      expect(find.text('Available balance: 10,00 DEPIX'), findsOneWidget);

      await tester.enterText(amountField(), '4590');
      await tester.pump();

      // A too high amount shows its error while the user types.
      expect(
        find.text('Your DePix balance does not cover this amount.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(repository.creates, isEmpty);
    });

    testWidgets('continue creates the quote and opens the review', (
      tester,
    ) async {
      useTallView(tester);
      controller.startFromKey(PixKeyType.cpf, _cpf);
      await tester.pumpWidget(host(initial: '/pix/send/amount'));
      await settle(tester);

      // A CPF key is its own document, so the step asks for no tax ID.
      expect(taxIdField(), findsNothing);

      await tester.enterText(amountField(), '4590');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(repository.creates.single['payout'], 4590);
      expect(find.text('Review payment'), findsOneWidget);
    });

    testWidgets('a refusal of the provider stays on the amount step', (
      tester,
    ) async {
      useTallView(tester);
      repository.onCreate = (_) => const Left(
        PixHubFailure(PixHubErrorCode.dailyLimitExceeded, limitInCents: 600000),
      );
      controller.startFromKey(PixKeyType.cpf, _cpf);
      await tester.pumpWidget(host(initial: '/pix/send/amount'));
      await settle(tester);

      await tester.enterText(amountField(), '4590');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await settle(tester);

      final warning = find.text(
        'This transfer goes over the daily limit of '
        '${formatBrlCents(600000)} that the Pix provider accepts for this '
        'key. No funds left your wallet. Try a lower amount or send it '
        'tomorrow.',
      );
      expect(warning, findsOneWidget);
      expect(find.text('Review payment'), findsNothing);

      // The warning outlasts a snack bar, so the user can lower the amount
      // while reading it. The frames after the wait let a snack bar leave.
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
      expect(warning, findsOneWidget);
    });
  });

  group('review', () {
    testWidgets('shows the payout, the fees and the DePix debit', (
      tester,
    ) async {
      useTallView(tester);
      await quoted();
      await tester.pumpWidget(host(initial: '/pix/send/review'));
      await settle(tester);

      expect(find.text('The recipient receives'), findsOneWidget);
      expect(find.text(formatBrlCents(4590)), findsOneWidget);
      expect(find.text('Pix provider fee'), findsOneWidget);
      expect(find.text(formatBrlCents(99)), findsOneWidget);
      expect(find.text('46,89 DEPIX'), findsOneWidget);
      expect(find.text('152 sats (L-BTC)'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
      expect(find.text('Confirm and pay'), findsOneWidget);
    });

    testWidgets('an expired quote offers a new quote, not a payment', (
      tester,
    ) async {
      useTallView(tester);
      // The quote was made 40 minutes ago on the device clock.
      now = DateTime.now().subtract(const Duration(minutes: 40));
      await quoted();
      now = DateTime.now();
      await tester.pumpWidget(host(initial: '/pix/send/review'));
      await settle(tester);

      expect(find.text('This quote expired.'), findsOneWidget);
      expect(find.text('Confirm and pay'), findsNothing);

      await tester.tap(find.text('Get a new quote'));
      await settle(tester);

      expect(repository.creates, hasLength(2));
      expect(find.text('Confirm and pay'), findsOneWidget);
      expect(wallet.sends, isEmpty);
    });

    testWidgets('a quote the wallet cannot fund stays blocked', (tester) async {
      useTallView(tester);
      wallet.balance = 4600 * PixWithdrawal.depixUnitsPerCent;
      await quoted();
      await tester.pumpWidget(host(initial: '/pix/send/review'));
      await settle(tester);

      expect(
        find.text(
          'Your DePix balance does not cover this transfer and its fee.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SlideToConfirmButton>(find.byType(SlideToConfirmButton))
            .isEnabled,
        isFalse,
      );
      await slideToPay(tester);
      await settle(tester);

      expect(wallet.sends, isEmpty);
    });

    testWidgets('a tap pays nothing; a slide sends once and opens the result', (
      tester,
    ) async {
      useTallView(tester);
      await quoted();
      await tester.pumpWidget(host(initial: '/pix/send/review'));
      await settle(tester);

      await tester.tap(find.text('Confirm and pay'));
      await settle(tester);
      expect(wallet.sends, isEmpty);

      await slideToPay(tester);
      await settle(tester);

      expect(wallet.sends, hasLength(1));
      expect(find.text('Pix in progress'), findsOneWidget);
      expect(find.text('Waiting for the deposit'), findsNothing);
    });

    testWidgets('during the broadcast the slide waits at its end, and the '
        'screen cannot pay twice', (tester) async {
      useTallView(tester);
      wallet.sendGate = Completer<PixFundingResult>();
      await quoted();
      await tester.pumpWidget(host(initial: '/pix/send/review'));
      await settle(tester);

      await slideToPay(tester);
      await settle(tester);
      expect(
        tester
            .widget<SlideToConfirmButton>(find.byType(SlideToConfirmButton))
            .isLoading,
        isTrue,
      );
      await slideToPay(tester);
      await settle(tester);
      expect(wallet.sends, hasLength(1));

      wallet.sendGate!.complete(const PixFundingSent(txid: 'txid-1'));
      await settle(tester);
      expect(find.text('Pix in progress'), findsOneWidget);
    });
  });

  group('result', () {
    Future<void> fund(PixFundingResult result) async {
      wallet.sendResult = result;
      await quoted();
      await controller.confirmAndFund();
    }

    testWidgets('the status sent shows the delivered Pix', (tester) async {
      useTallView(tester);
      repository.statusAnswers.add(
        Right([
          PixWithdrawalDetails(
            id: 'w-1',
            status: PixWithdrawalStatus.sent,
            createdAt: testStart,
            receiverName: 'Ana Souza',
            receiptUrl: 'https://eulen.app/receipt/1',
          ),
        ]),
      );
      await fund(const PixFundingSent(txid: 'txid-1'));
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await settle(tester);

      expect(find.text('Pix delivered'), findsNWidgets(2));
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Open receipt'), findsOneWidget);
    });

    testWidgets('an open status keeps the payment in progress', (tester) async {
      useTallView(tester);
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.unsent)]),
      );
      await fund(const PixFundingSent(txid: 'txid-1'));
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await settle(tester);

      expect(find.text('Pix in progress'), findsOneWidget);
      expect(find.text('Waiting for the deposit'), findsOneWidget);
      expect(find.text('Refresh status'), findsOneWidget);
      expect(find.text('Open receipt'), findsNothing);
    });

    testWidgets('an uncertain broadcast warns against paying again', (
      tester,
    ) async {
      useTallView(tester);
      await fund(const PixFundingUncertain(rawMessage: 'timeout'));
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await settle(tester);

      expect(find.text('Result not confirmed'), findsOneWidget);
      expect(find.textContaining('Do not pay again.'), findsOneWidget);
      // The request ID for support shows in a field that copies it.
      expect(find.widgetWithText(PixCopyField, 'Request ID'), findsOneWidget);
    });

    testWidgets('a refund ends the payment as not completed', (tester) async {
      useTallView(tester);
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.refunded)]),
      );
      await fund(const PixFundingSent(txid: 'txid-1'));
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await settle(tester);

      expect(find.text('Pix not completed'), findsOneWidget);
      expect(
        find.text('The provider returned the deposit to your refund address.'),
        findsOneWidget,
      );
      expect(find.text('Refresh status'), findsNothing);
    });
  });

  group('result scene', () {
    const step = Duration(milliseconds: 16);
    const light = 'HapticFeedbackType.lightImpact';
    const heavy = 'HapticFeedbackType.heavyImpact';
    late List<(String, Duration)> haptics;
    late Duration clock;

    /// Funds a payment whose first status read finds it open, and opens
    /// the result, recording the haptics.
    Future<void> open(WidgetTester tester) async {
      useTallView(tester);
      haptics = [];
      clock = Duration.zero;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add((call.arguments as String, clock));
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.unsent)]),
      );
      wallet.sendResult = const PixFundingSent(txid: 'txid-1');
      await quoted();
      await controller.confirmAndFund();
      await tester.pumpWidget(host(initial: '/pix/send/result'));
    }

    Future<void> advance(WidgetTester tester, Duration time) async {
      final end = clock + time;
      while (clock < end) {
        await tester.pump(step);
        clock += step;
      }
    }

    /// The next status read finds [status].
    Future<void> answer(WidgetTester tester, PixWithdrawalStatus status) async {
      repository.statusAnswers.add(Right([testDetails('w-1', status)]));
      scheduled.last();
      await tester.pump();
    }

    PixSendMotion motion(WidgetTester tester) =>
        tester.widget<PixSendScene>(find.byType(PixSendScene)).motion;

    /// Whether the title of the result tells [text]. The status in the
    /// details tells the backend status at once.
    bool titled(String text) => find
        .descendant(of: find.byType(PixStatusView), matching: find.text(text))
        .evaluate()
        .isNotEmpty;

    test('the coin is edge-on as it becomes the Pix token, wherever the '
        'wait stopped, and rests at its yaw', () {
      for (var wait = 0.0; wait <= 1; wait += 0.05) {
        PixSendMotion at(double delivered) =>
            PixSendMotion(wait: wait, delivered: delivered);
        final edge = PixSendScene.poseAt(at(PixSendScene.revealAt));
        expect(edge.turn, 2.5 * math.pi);
        expect(edge.showsPix, isTrue);
        // No jump: the turn comes to edge-on smoothly.
        final before = PixSendScene.poseAt(at(PixSendScene.revealAt - 1e-6));
        expect(before.showsPix, isFalse);
        expect(before.turn, closeTo(2.5 * math.pi, 1e-3));
        for (final delivered in [PixSendScene.landAt, 1.0]) {
          expect(
            StageToken.faceYaw(PixSendScene.poseAt(at(delivered)).turn),
            closeTo(PixSendScene.restYaw, 1e-9),
          );
          expect(PixSendScene.poseAt(at(delivered)).lift, closeTo(0, 1e-9));
        }
      }
    });

    test('the wait wraps with no jump, and a Pix not paid never shows the '
        'Pix token', () {
      final start = PixSendScene.poseAt(const PixSendMotion(wait: 0));
      final end = PixSendScene.poseAt(const PixSendMotion(wait: 1));
      expect(end.turn, closeTo(start.turn, 1e-9));
      for (var r = 0.0; r <= 1; r += 0.05) {
        final pose = PixSendScene.poseAt(PixSendMotion(wait: 0.3, returned: r));
        expect(pose.showsPix, isFalse);
      }
      final rest = PixSendScene.poseAt(
        const PixSendMotion(wait: 0.3, returned: 1),
      );
      expect(rest.turn, PixSendScene.restYaw);
      expect(rest.lift, greaterThan(0));
    });

    testWidgets('the DePix coin comes in, then waits while the provider '
        'pays', (tester) async {
      await open(tester);
      expect(motion(tester).entrance, lessThan(0.1));
      await advance(tester, Motion.durationPixSendEntrance);
      expect(motion(tester).entrance, 1);
      final wait = motion(tester).wait;
      await advance(tester, const Duration(milliseconds: 500));
      expect(motion(tester).wait, isNot(wait));
      expect(motion(tester).delivered, 0);
      expect(titled('Pix in progress'), isTrue);
    });

    testWidgets('the status sent turns the coin into the Pix token, with a '
        'haptic as it spins, as it turns, and as it lands; the title tells '
        'it as the Pix token shows', (tester) async {
      await open(tester);
      await advance(tester, const Duration(seconds: 2));
      await answer(tester, PixWithdrawalStatus.sent);

      Duration? start, titledAt;
      var titleBeforePix = false;
      final waits = <double>{};
      while (clock < const Duration(seconds: 5)) {
        await tester.pump(step);
        clock += step;
        final m = motion(tester);
        if (m.delivered > 0) {
          start ??= clock;
          waits.add(m.wait);
        }
        final pix = PixSendScene.poseAt(m).showsPix;
        if (titled('Pix delivered')) {
          titledAt ??= clock;
          if (!pix) titleBeforePix = true;
        }
      }

      final duration = Motion.durationPixDelivered;
      expect(motion(tester).delivered, 1);
      // The wait holds still while the coin turns.
      expect(waits, hasLength(1));
      expect(titleBeforePix, isFalse);
      expect(
        (titledAt! - start! - duration * PixSendScene.revealAt).abs(),
        lessThanOrEqualTo(step * 2),
      );
      expect([for (final (type, _) in haptics) type], [light, heavy, light]);
      for (final ((_, at), share) in [
        (haptics[1], PixSendScene.revealAt),
        (haptics[2], PixSendScene.landAt),
      ]) {
        expect(
          (at - start - duration * share).abs(),
          lessThanOrEqualTo(step * 2),
        );
      }
    });

    testWidgets('a status sent before the coin is in place waits for it', (
      tester,
    ) async {
      await open(tester);
      await advance(tester, const Duration(milliseconds: 200));
      await answer(tester, PixWithdrawalStatus.sent);
      Duration? start;
      while (start == null && clock < const Duration(seconds: 4)) {
        await tester.pump(step);
        clock += step;
        if (motion(tester).delivered > 0) start = clock;
      }
      // The entrance, then a moment in place.
      expect(start, greaterThanOrEqualTo(const Duration(milliseconds: 1600)));
      expect(titled('Pix delivered'), isFalse);
    });

    testWidgets('a refund lets the coin sink, with one light haptic and no '
        'Pix token', (tester) async {
      await open(tester);
      await advance(tester, const Duration(seconds: 2));
      await answer(tester, PixWithdrawalStatus.refunded);
      await advance(tester, Motion.durationPixReturned);

      expect(motion(tester).returned, 1);
      expect(motion(tester).delivered, 0);
      expect(PixSendScene.poseAt(motion(tester)).showsPix, isFalse);
      expect([for (final (type, _) in haptics) type], [light]);
      expect(titled('Pix not completed'), isTrue);
    });

    testWidgets('opened after the outcome, the scene rests on it, with no '
        'haptic', (tester) async {
      useTallView(tester);
      haptics = [];
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
      );
      wallet.sendResult = const PixFundingSent(txid: 'txid-1');
      await quoted();
      await controller.confirmAndFund();
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add((call.arguments as String, Duration.zero));
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await tester.pump();

      expect(motion(tester).delivered, 1);
      expect(motion(tester).entrance, 1);
      expect(titled('Pix delivered'), isTrue);
      await settle(tester);
      expect(haptics, isEmpty);
    });

    testWidgets('when the status reads stop, the wait ends its cycle and '
        'rests', (tester) async {
      await open(tester);
      await advance(tester, const Duration(seconds: 2));
      for (var i = 0; i < PixSendController.defaultMaxPolls; i++) {
        scheduled.last();
        await tester.pump();
      }
      expect(controller.state.pollingExhausted, isTrue);
      await advance(tester, Motion.durationPixSendWait);
      final rest = motion(tester);
      expect(rest.wait, 1);
      await advance(tester, const Duration(seconds: 1));
      expect(motion(tester).wait, 1);
      expect(
        PixSendScene.poseAt(rest).turn,
        closeTo(PixSendScene.restYaw, 1e-9),
      );
    });

    testWidgets('opened after the status reads stopped, the coin comes in '
        'and rests: nothing loops', (tester) async {
      useTallView(tester);
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.unsent)]),
      );
      wallet.sendResult = const PixFundingSent(txid: 'txid-1');
      await quoted();
      await controller.confirmAndFund();
      await tester.pump();
      for (var i = 0; i < PixSendController.defaultMaxPolls; i++) {
        scheduled.last();
        await tester.pump();
      }
      expect(controller.state.pollingExhausted, isTrue);
      clock = Duration.zero;
      await tester.pumpWidget(host(initial: '/pix/send/result'));
      await advance(tester, const Duration(seconds: 2));

      expect(motion(tester).entrance, 1);
      expect(motion(tester).wait, 0);
    });

    group('the app bar', () {
      /// A phone, where the page scrolls.
      void usePhone(WidgetTester tester) {
        tester.view.physicalSize = const Size(390, 844) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
      }

      /// The opacity the slice of the backdrop of the bar goes to.
      double backdrop(WidgetTester tester) => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(BackdropAppBar),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;

      testWidgets('leaves the scene uncut: the list starts at the top of '
          'the screen, and the scene and the refresh start below the bar', (
        tester,
      ) async {
        await open(tester);
        usePhone(tester);
        await advance(tester, const Duration(milliseconds: 400));

        expect(tester.getRect(find.byType(ListView)).top, 0);
        expect(
          tester.getRect(find.byType(PixSendScene)).top,
          greaterThanOrEqualTo(kToolbarHeight),
        );
        expect(
          tester
              .widget<RefreshIndicator>(find.byType(RefreshIndicator))
              .edgeOffset,
          kToolbarHeight,
        );
      });

      testWidgets('shows only its button over the scene, and takes its '
          'backdrop once the content scrolls under it', (tester) async {
        await open(tester);
        usePhone(tester);
        await advance(tester, const Duration(milliseconds: 400));
        expect(backdrop(tester), 0);

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await advance(tester, const Duration(milliseconds: 400));
        expect(backdrop(tester), 1);

        await tester.drag(find.byType(ListView), const Offset(0, 400));
        await advance(tester, const Duration(milliseconds: 400));
        expect(backdrop(tester), 0);
      });
    });

    testWidgets('with reduced motion, nothing loops, and the Pix token shows '
        'at once with one light haptic', (tester) async {
      reduceMotion(tester);
      await open(tester);
      await tester.pump();
      expect(motion(tester).entrance, 1);
      await advance(tester, const Duration(seconds: 1));
      expect(motion(tester).wait, 0);

      await answer(tester, PixWithdrawalStatus.sent);
      await tester.pump();
      expect(motion(tester).delivered, 1);
      expect(titled('Pix delivered'), isTrue);
      expect([for (final (type, _) in haptics) type], [light]);
    });
  });

  group('copy and paste', () {
    testWidgets('a code without a Pix key is refused', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/code'));
      await settle(tester);

      String field(String id, String value) =>
          '$id${value.length.toString().padLeft(2, '0')}$value';
      final account =
          field('00', 'BR.GOV.BCB.PIX') + field('25', 'pix.exemplo.com/qr/1');
      final body =
          '${field('00', '01')}${field('26', account)}${field('52', '0000')}'
          '${field('53', '986')}${field('58', 'BR')}${field('59', 'LOJA')}'
          '${field('60', 'RIO')}${field('62', field('05', '***'))}6304';
      await tester.enterText(
        find.byType(TextField),
        '$body${PixBrCodeParser.crc16(body)}',
      );
      await tester.pump();

      expect(find.text('No Pix key (dynamic code)'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(
        find.text(
          'This code has no Pix key. Mooze pays codes that carry a key only.',
        ),
        findsOneWidget,
      );
      expect(controller.state.draft, isNull);
    });

    testWidgets('a static code opens the amount step with its key', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(host(initial: '/pix/send/code'));
      await settle(tester);

      await tester.enterText(
        find.byType(TextField),
        PixBrCodeParser.build(
          pixKey: _email,
          merchantName: 'Padaria',
          merchantCity: 'Rio',
          amountInCents: 8450,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('CPF or CNPJ of the key owner'), findsOneWidget);
      expect(find.text('a**@exemplo.com.br'), findsOneWidget);
      expect(
        find.text('The code already sets the amount of the charge.'),
        findsOneWidget,
      );
    });
  });

  group('localization', () {
    for (final (locale, confirm) in const [
      (Locale('pt'), 'Confirmar e pagar'),
      (Locale('es'), 'Confirmar y pagar'),
    ]) {
      testWidgets('the review speaks ${locale.languageCode}', (tester) async {
        useTallView(tester);
        await quoted();
        await tester.pumpWidget(
          host(initial: '/pix/send/review', locale: locale),
        );
        await settle(tester);

        expect(find.text(confirm), findsOneWidget);
      });
    }

    test('the three ARB files hold the same keys', () {
      Set<String> keys(String lang) {
        final json =
            jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
                as Map<String, dynamic>;
        return json.keys.where((k) => !k.startsWith('@')).toSet();
      }

      final pt = keys('pt');
      expect(keys('en'), pt);
      expect(keys('es'), pt);
    });
  });
}
