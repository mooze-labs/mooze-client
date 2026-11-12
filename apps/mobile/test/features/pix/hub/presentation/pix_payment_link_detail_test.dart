import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// The list of links has not loaded the link: the screen shows the one it
/// was given.
class _NoLinks extends PixPaymentLinksController {
  @override
  Future<List<PixPaymentLink>> build() async => const [];
}

const _url = 'https://pay.mooze.app/pay/tok_8f3a9c2e7b1d4056a';

PixPaymentLink _link({
  int? cents = 4590,
  String reference = 'Bolo de pote',
  PixPaymentLinkStatus status = PixPaymentLinkStatus.pending,
}) => PixPaymentLink(
  id: 'link-1',
  url: _url,
  reference: reference,
  status: status,
  createdAt: DateTime(2026, 11, 11, 14, 32),
  singleUse: true,
  amountInCents: cents,
  asset: Asset.depix,
);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// The texts that the share sheet received.
  late List<String?> shared;

  setUp(() {
    shared = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            shared.add((call.arguments as Map)['text'] as String?);
            return 'dev.fluttercommunity.plus/share/unavailable';
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          null,
        );
  });

  /// Opens the screen on a phone of [size], 390 x 844 by default.
  Future<void> open(
    WidgetTester tester,
    PixPaymentLink link, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pixHubPaymentLinksProvider.overrideWith(_NoLinks.new)],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: PixPaymentLinkDetailScreen(link: link),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder shareButton() => find.widgetWithText(PrimaryButton, t.pix_hub_share);

  /// Scrolls to the end of the screen. The list builds only what shows, so
  /// the note at the end exists only once it is on screen.
  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
  }

  group('share', () {
    // The payer receives this text. It names the amount, as the merchant
    // mode does, and nothing in it says "demo".
    testWidgets('sends the amount and the link', (tester) async {
      await open(tester, _link(cents: 4590));

      await tester.tap(shareButton());
      await tester.pump();

      expect(shared, [
        t.pix_hub_link_share_message_amount(formatBrlCents(4590), _url),
      ]);
      expect(shared.single, isNot(contains('demonstra')));
    });

    testWidgets('a link with an open amount sends the link alone', (
      tester,
    ) async {
      await open(tester, _link(cents: null));

      await tester.tap(shareButton());
      await tester.pump();

      expect(shared, [t.pix_hub_link_share_message(_url)]);
      expect(shared.single, isNot(contains('demonstra')));
    });
  });

  testWidgets('a pending link shows the QR Code, the address, the share and '
      'the revoke', (tester) async {
    await open(tester, _link());

    expect(find.byType(PixQrPanel), findsOneWidget);
    expect(find.byType(PixCopyField), findsOneWidget);
    expect(shareButton(), findsOneWidget);
    expect(find.text(t.pix_hub_link_revoke), findsOneWidget);
    await scrollToEnd(tester);
    expect(find.text(t.pix_hub_link_disclaimer), findsOneWidget);
  });

  // A link that takes no more payments would only lead the payer to a dead
  // page. The screen says why, and keeps the details.
  for (final (status, notice) in [
    (PixPaymentLinkStatus.paid, t.pix_hub_link_inactive_paid),
    (PixPaymentLinkStatus.expired, t.pix_hub_link_inactive_expired),
    (PixPaymentLinkStatus.revoked, t.pix_hub_link_inactive_revoked),
  ]) {
    testWidgets('a ${status.name} link says why it takes no payment, with no '
        'QR Code, address or share', (tester) async {
      await open(tester, _link(status: status));

      expect(find.text(notice), findsOneWidget);
      expect(find.byType(PixQrPanel), findsNothing);
      expect(find.byType(PixCopyField), findsNothing);
      expect(shareButton(), findsNothing);
      expect(find.text(t.pix_hub_link_revoke), findsNothing);
      expect(find.text(t.pix_hub_summary_created_at), findsOneWidget);
      // How a link is paid no longer applies.
      await scrollToEnd(tester);
      expect(find.text(t.pix_hub_link_disclaimer), findsNothing);
    });
  }

  group('top of the screen', () {
    // The identification says which charge this is, so it shows with the
    // amount, before the QR Code, and only once.
    testWidgets('the identification shows below the amount, before the QR '
        'Code', (tester) async {
      await open(tester, _link());

      expect(find.text('Bolo de pote'), findsOneWidget);
      expect(find.text(t.pix_hub_link_reference_label), findsNothing);
      final amount = tester.getRect(
        find.bySemanticsLabel(formatBrlCents(4590)),
      );
      final reference = tester.getRect(find.text('Bolo de pote'));
      final qr = tester.getRect(find.byType(PixQrPanel));
      expect(reference.top, greaterThan(amount.bottom - 1));
      expect(qr.top, greaterThan(reference.bottom));
    });

    testWidgets('a link with no identification shows none', (tester) async {
      await open(tester, _link(reference: ''));

      expect(find.text(t.pix_hub_link_reference_label), findsNothing);
      expect(find.byType(PixQrPanel), findsOneWidget);
    });

    // The identification above the QR Code must not push the address that
    // the owner copies below the buttons of a phone.
    testWidgets('the address still fits the first screen, above the '
        'buttons', (tester) async {
      await open(tester, _link());

      final address = tester.getRect(find.byType(PixCopyField));
      final share = tester.getRect(shareButton());
      expect(address.bottom, lessThanOrEqualTo(share.top));
    });
  });
}
