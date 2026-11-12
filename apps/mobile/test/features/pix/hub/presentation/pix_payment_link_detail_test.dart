import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_payment_link_reference_store.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/info_banner.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The list of links has not loaded the link: the screen shows the one it
/// was given. It records the revokes instead of calling the API.
class _NoLinks extends PixPaymentLinksController {
  /// The IDs of the links that the screen asked to revoke.
  final revoked = <String>[];

  @override
  Future<List<PixPaymentLink>> build() async => const [];

  @override
  Future<Either<PixHubFailure, Unit>> revoke(String id) async {
    revoked.add(id);
    return right(unit);
  }
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

  /// The texts that reached the clipboard.
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
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      )
      ..setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// The device storage of the names of the links.
  late SharedPreferences prefs;

  Future<void> open(WidgetTester tester, PixPaymentLink link) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pixHubPaymentLinksProvider.overrideWith(_NoLinks.new),
          localeStringProvider.overrideWithValue('pt_BR'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
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

  Finder menuButton() => find.byTooltip(t.pix_hub_link_actions);

  /// Pumps frames for a sheet, a menu, or a dialog. The step in progress of
  /// the status track breathes, so `pumpAndSettle` never ends.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The list of links of the screen, which records the revokes.
  _NoLinks links(WidgetTester tester) =>
      ProviderScope.containerOf(
            tester.element(find.byType(PixPaymentLinkDetailScreen)),
          ).read(pixHubPaymentLinksProvider.notifier)
          as _NoLinks;

  TxStatusPanel status(WidgetTester tester) =>
      tester.widget<TxStatusPanel>(find.byType(TxStatusPanel));

  // The link reads like a transaction of the wallet: the same page, hero,
  // status panel, and metadata panel.
  testWidgets('follows the layout of the transaction details', (tester) async {
    await open(tester, _link());

    expect(find.byType(TxDetailScaffold), findsOneWidget);
    expect(find.byType(HeroAssetIcon), findsOneWidget);
    expect(find.byType(TxStatusPanel), findsOneWidget);
    expect(find.byType(TxMetaPanel), findsOneWidget);
  });

  group('hero', () {
    testWidgets('names the charge above the amount, centered on it', (
      tester,
    ) async {
      await open(tester, _link());

      final reference = tester.getRect(find.text('Bolo de pote'));
      final amount = tester.getRect(
        find.bySemanticsLabel(formatBrlCents(4590)),
      );
      expect(reference.bottom, lessThanOrEqualTo(amount.top + 1));
      expect(reference.center.dx, closeTo(amount.center.dx, 1));
    });

    // As a received transaction: the sign carries the direction, so it
    // never depends on the color.
    testWidgets('a paid link shows the amount it brought in, with a plus '
        'sign', (tester) async {
      await open(tester, _link(status: PixPaymentLinkStatus.paid));

      expect(
        find.bySemanticsLabel('+ ${formatBrlCents(4590)}'),
        findsOneWidget,
      );
    });

    testWidgets('a link with an open amount says so', (tester) async {
      await open(tester, _link(cents: null));

      expect(find.text(t.pix_hub_link_open_amount), findsOneWidget);
    });
  });

  group('status', () {
    for (final (linkStatus, title, states) in [
      (
        PixPaymentLinkStatus.pending,
        t.pix_hub_link_status_pending,
        [TxStepState.done, TxStepState.active, TxStepState.upcoming],
      ),
      (
        PixPaymentLinkStatus.paid,
        t.pix_hub_link_status_paid,
        [TxStepState.done, TxStepState.done, TxStepState.done],
      ),
      (
        PixPaymentLinkStatus.expired,
        t.pix_hub_link_status_expired,
        [TxStepState.done, TxStepState.failed, TxStepState.upcoming],
      ),
      (
        PixPaymentLinkStatus.revoked,
        t.pix_hub_link_status_revoked,
        [TxStepState.done, TxStepState.failed, TxStepState.upcoming],
      ),
    ]) {
      testWidgets('a ${linkStatus.name} link shows how far it went', (
        tester,
      ) async {
        await open(tester, _link(status: linkStatus));

        expect(status(tester).title, title);
        expect(status(tester).steps.map((step) => step.state), states);
        expect(status(tester).steps.first.label, t.pix_hub_link_step_created);
      });
    }

    testWidgets('shows when the link was created', (tester) async {
      await open(tester, _link());

      expect(status(tester).details.single, contains('2026'));
      expect(status(tester).details.single, contains('14:32'));
    });
  });

  group('actions', () {
    // The payer receives this text. It names the amount, as the merchant
    // mode does, and nothing in it says "demo".
    testWidgets('share sends the amount and the link', (tester) async {
      await open(tester, _link(cents: 4590));

      await tester.tap(find.text(t.pix_hub_link_share_action));
      await tester.pump();

      expect(shared, [
        t.pix_hub_link_share_message_amount(formatBrlCents(4590), _url),
      ]);
    });

    testWidgets('a link with an open amount shares the link alone', (
      tester,
    ) async {
      await open(tester, _link(cents: null));

      await tester.tap(find.text(t.pix_hub_link_share_action));
      await tester.pump();

      expect(shared, [t.pix_hub_link_share_message(_url)]);
    });

    // As the explorer link of a transaction, the QR Code opens on demand,
    // in a floating sheet, with how to use it.
    testWidgets('the QR Code opens in a floating sheet', (tester) async {
      await open(tester, _link());
      expect(find.byType(PixQrPanel), findsNothing);

      await tester.tap(find.text(t.pix_hub_link_qr_action));
      await frames(tester);

      expect(find.byType(GlassSheet), findsOneWidget);
      expect(tester.widget<PixQrPanel>(find.byType(PixQrPanel)).data, _url);
      expect(find.text(t.pix_hub_link_qr_caption), findsOneWidget);
    });

    // The QR Code opens in the app: a chevron, not the outward arrow of a
    // link that leaves it.
    testWidgets('the QR Code action points inward', (tester) async {
      await open(tester, _link());

      final action = find.widgetWithText(
        InCardActionButton,
        t.pix_hub_link_qr_action,
      );
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.arrow_outward_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('the address shows short and copies the whole link', (
      tester,
    ) async {
      await open(tester, _link());

      final row = find.widgetWithText(DetailRow, t.pix_hub_link_url_label);
      expect(row, findsOneWidget);
      expect(find.text(_url), findsNothing);
      // The ends of the token, as a transaction ID shows its ends: short
      // enough for the value column, with no second ellipsis.
      expect(tester.widget<DetailRow>(row).value, 'tok_8...4056a');
      expect(tester.widget<DetailRow>(row).copyValue, _url);

      await tester.tap(
        find.descendant(of: row, matching: find.byType(GestureDetector)).last,
      );
      await tester.pump();
      expect(copied, [_url]);
    });
  });

  testWidgets('the details show the asset with its logo and the usage', (
    tester,
  ) async {
    await open(tester, _link());

    final cells = tester.widget<TxMetaPanel>(find.byType(TxMetaPanel)).cells;
    final asset = cells.singleWhere(
      (cell) => cell.label == t.pix_hub_link_asset_label,
    );
    expect(asset.leading, isNotNull);
    expect(
      cells.map((cell) => cell.value),
      contains(t.pix_hub_link_single_use),
    );
  });

  // A link that takes no more payments would only lead the payer to a dead
  // page. The screen says why, and keeps the details.
  for (final (linkStatus, notice) in [
    (PixPaymentLinkStatus.paid, t.pix_hub_link_inactive_paid),
    (PixPaymentLinkStatus.expired, t.pix_hub_link_inactive_expired),
    (PixPaymentLinkStatus.revoked, t.pix_hub_link_inactive_revoked),
  ]) {
    testWidgets('a ${linkStatus.name} link says why it takes no payment, '
        'with no address, share, QR Code, or revoke', (tester) async {
      await open(tester, _link(status: linkStatus));

      expect(find.widgetWithText(InfoBanner, notice), findsOneWidget);
      expect(find.text(t.pix_hub_link_url_label), findsNothing);
      expect(find.text(t.pix_hub_link_share_action), findsNothing);
      expect(find.text(t.pix_hub_link_qr_action), findsNothing);
      expect(find.byType(TxMetaPanel), findsOneWidget);

      // Its name still organizes the list, so the menu keeps the rename.
      await tester.tap(menuButton());
      await frames(tester);
      expect(find.text(t.pix_hub_link_reference_edit), findsOneWidget);
      expect(find.text(t.pix_hub_link_revoke), findsNothing);
    });
  }

  // A destructive action stays out of the thumb zone: it lives in the menu
  // of the bar, and asks first in a floating sheet, as the other notices,
  // with a red button that names the action.
  group('revoke', () {
    Future<void> openRevoke(WidgetTester tester) async {
      await open(tester, _link());
      expect(find.text(t.pix_hub_link_revoke), findsNothing);
      await tester.tap(menuButton());
      await frames(tester);
      await tester.tap(find.text(t.pix_hub_link_revoke));
      await frames(tester);
    }

    testWidgets('asks in a floating sheet, with a red button', (tester) async {
      await openRevoke(tester);

      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.text(t.pix_hub_link_revoke_title), findsOneWidget);
      final confirm = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, t.pix_hub_link_revoke_confirm),
      );
      final sheet = tester.element(find.byType(GlassSheet));
      expect(confirm.color, sheet.colors.negativeColor);
      // A sheet from the bottom, not a dialog in the middle.
      expect(ModalRoute.of(sheet), isA<ModalBottomSheetRoute<bool>>());
    });

    testWidgets('the red button revokes the link', (tester) async {
      await openRevoke(tester);

      await tester.tap(find.text(t.pix_hub_link_revoke_confirm));
      await frames(tester);

      expect(find.byType(GlassSheet), findsNothing);
      expect(links(tester).revoked, ['link-1']);
    });

    testWidgets('cancel closes the sheet and keeps the link', (tester) async {
      await openRevoke(tester);

      await tester.tap(find.text(t.common_cancel));
      await frames(tester);

      expect(find.byType(GlassSheet), findsNothing);
      expect(links(tester).revoked, isEmpty);
      expect(status(tester).title, t.pix_hub_link_status_pending);
      expect(menuButton(), findsOneWidget);
    });
  });

  // The name of a link only organizes the links of the owner. It can be
  // added or changed at any time, from the menu of the bar.
  group('identification', () {
    Future<void> openSheet(WidgetTester tester, String action) async {
      await tester.tap(menuButton());
      await frames(tester);
      await tester.tap(find.text(action));
      await frames(tester);
    }

    Finder field() => find.descendant(
      of: find.byType(GlassSheet),
      matching: find.byType(TextField),
    );

    testWidgets('the menu is a glass panel that offers to name a link with '
        'no name, and to revoke it', (tester) async {
      await open(tester, _link(reference: ''));

      await tester.tap(menuButton());
      await frames(tester);

      final panel = find.ancestor(
        of: find.text(t.pix_hub_link_reference_add),
        matching: find.byType(LiquidGlass),
      );
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text(t.pix_hub_link_revoke)),
        findsOneWidget,
      );
    });

    testWidgets('a name added in the sheet shows on the link and stays on '
        'the device', (tester) async {
      await open(tester, _link(reference: ''));

      await openSheet(tester, t.pix_hub_link_reference_add);
      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.text(t.pix_hub_link_reference_sheet_body), findsOneWidget);

      await tester.enterText(field(), '  Aula de março ');
      await tester.tap(find.text(t.common_save));
      await frames(tester);

      expect(find.byType(GlassSheet), findsNothing);
      expect(find.text('Aula de março'), findsOneWidget);
      expect(PixPaymentLinkReferenceStore(prefs).load(), {
        'link-1': 'Aula de março',
      });
    });

    testWidgets('a new name grows and fades in', (tester) async {
      await open(tester, _link(reference: ''));

      await openSheet(tester, t.pix_hub_link_reference_add);
      await tester.enterText(field(), 'Aula de março');
      await tester.tap(find.text(t.common_save));
      // The sheet closes, then the name arrives.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Aula de março'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await frames(tester);
      expect(fade.opacity.value, 1);
    });

    // The amount under the name moves up as the name leaves, not at once.
    testWidgets('a cleared name closes its space smoothly', (tester) async {
      await open(tester, _link());
      double amountTop() =>
          tester.getRect(find.bySemanticsLabel(formatBrlCents(4590))).top;
      final before = amountTop();

      await openSheet(tester, t.pix_hub_link_reference_edit);
      await tester.enterText(field(), '');
      await tester.tap(find.text(t.common_save));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final middle = amountTop();
      await frames(tester);
      final after = amountTop();

      expect(after, isNot(before));
      expect(
        middle,
        inExclusiveRange(math.min(before, after), math.max(before, after)),
      );
    });

    testWidgets('a link with a name offers to edit it, filled in', (
      tester,
    ) async {
      await open(tester, _link());

      await openSheet(tester, t.pix_hub_link_reference_edit);

      expect(
        tester.widget<TextField>(field()).controller?.text,
        'Bolo de pote',
      );
    });

    testWidgets('a cleared name leaves the link with no name', (tester) async {
      await open(tester, _link());

      await openSheet(tester, t.pix_hub_link_reference_edit);
      await tester.enterText(field(), '');
      await tester.tap(find.text(t.common_save));
      await frames(tester);

      expect(find.text('Bolo de pote'), findsNothing);
      expect(PixPaymentLinkReferenceStore(prefs).load(), {'link-1': ''});

      // The menu now offers to add a name.
      await tester.tap(menuButton());
      await frames(tester);
      expect(find.text(t.pix_hub_link_reference_add), findsOneWidget);
    });

    testWidgets('closing the sheet keeps the name', (tester) async {
      await open(tester, _link());

      await openSheet(tester, t.pix_hub_link_reference_edit);
      await tester.enterText(field(), 'Outro nome');
      await tester.tap(find.byTooltip(t.common_close));
      await frames(tester);

      expect(find.byType(GlassSheet), findsNothing);
      expect(find.text('Bolo de pote'), findsOneWidget);
      expect(PixPaymentLinkReferenceStore(prefs).load(), isEmpty);
    });

    // The keyboard opens over the bottom of the screen. The field and the
    // save button stay above it.
    testWidgets('the sheet rises above the keyboard', (tester) async {
      await open(tester, _link());
      await openSheet(tester, t.pix_hub_link_reference_edit);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await frames(tester);

      final keyboardTop = 844.0 - 300;
      expect(
        tester.getRect(find.text(t.common_save)).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
    });
  });
}
