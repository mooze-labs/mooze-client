import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/pix_payment_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/analytics/analytics.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sample Pix copy-and-paste code. It is not a real Pix code.
const _code =
    '00020126580014br.gov.bcb.pix0136sample-code-of-the-test5204000053039865802BR';

final _deposit = PixDeposit(
  depositId: 'deposit-1',
  pixKey: _code,
  asset: Asset.depix,
  amountInCents: 5000,
  network: 'liquid',
  status: DepositStatus.pending,
  createdAt: DateTime.now(),
);

class _NoConsent implements ConsentStore {
  @override
  bool read() => false;

  @override
  Future<void> write(bool value) async {}
}

/// Records the events that the screen sends.
class _RecordingAnalytics extends AnalyticsController {
  _RecordingAnalytics()
    : super(
        configured: false,
        store: _NoConsent(),
        load: (_) async => throw UnimplementedError(),
      );

  final tracked = <String>[];

  @override
  void track(AnalyticsEvent event) => tracked.add(event.name);
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  late List<String?> shared;
  late List<String?> copied;

  setUp(() {
    shared = [];
    copied = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      })
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          shared.add((call.arguments as Map)['text'] as String?);
          return 'dev.fluttercommunity.plus/share/unavailable';
        },
      );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, null)
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      );
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<_RecordingAnalytics> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          analyticsProvider.overrideWith((ref) => analytics),
          assetQuoteProvider.overrideWith((ref, asset) async => right(some(5))),
          feeRateProvider.overrideWith((ref, amount) async => 0),
          discountedFeesDepositProvider.overrideWith(
            (ref, amount) async => amount,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: ValidPixPaymentScreen(deposit: _deposit),
        ),
      ),
    );
    await frames(tester);
    return analytics;
  }

  /// Scrolls to [finder] and taps it. The panel sits below the QR Code, and
  /// the scroll lays out on the next frame.
  Future<void> tapBelow(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  // The payer scans the code on this screen, so the QR Code stays in view:
  // nothing hides it behind an action.
  testWidgets('the QR Code shows on the screen, with no action to show it', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(PixQrPanel), findsOneWidget);
    expect(find.text(t.pix_deposit_qr_action), findsNothing);
  });

  // As in the details of a deposit: one panel holds what the deposit
  // delivers, its fees, the code with copy, and the share.
  testWidgets('one panel holds what you receive, the fees, the code, and '
      'the share', (tester) async {
    await open(tester);

    Element panelOf(String text) => find
        .ancestor(of: find.text(text), matching: find.byType(GlassPanel))
        .evaluate()
        .first;
    final panel = panelOf(t.pix_you_will_receive);
    for (final text in [
      t.pix_fee_processor,
      t.pix_hub_charge_code_label,
      t.pix_deposit_share_action,
    ]) {
      expect(panelOf(text), same(panel), reason: text);
    }
  });

  testWidgets('the share sends the amount and the Pix code', (tester) async {
    await open(tester);

    await tapBelow(tester, find.text(t.pix_deposit_share_action));

    expect(shared, [t.pix_deposit_share_message(formatBrlCents(5000), _code)]);
  });

  // The copy keeps the event that the old copy field sent.
  testWidgets('the code shows short, copies whole, and records the copy', (
    tester,
  ) async {
    final analytics = await open(tester);

    final row = find.widgetWithText(DetailRow, t.pix_hub_charge_code_label);
    expect(find.text(_code), findsNothing);
    await tapBelow(
      tester,
      find.descendant(of: row, matching: find.byType(GestureDetector)).last,
    );

    expect(copied, [_code]);
    expect(analytics.tracked, ['pix_code_copied']);
  });
}
