import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/update_service.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_banner.dart';
import 'package:mooze_mobile/shared/providers/update_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/update_notification_widget.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import 'motion/motion_test_helpers.dart';

/// An update notifier that starts in [initial] and never reaches the
/// network.
class _FakeUpdateNotifier extends UpdateNotifier {
  _FakeUpdateNotifier(UpdateState initial) : super(UpdateService()) {
    state = initial;
  }

  @override
  Future<void> checkForUpdates() async {}
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  const update = UpdateState(
    hasUpdate: true,
    newVersion: '1.4.0',
    localVersion: '1.3.2',
  );

  /// The banner under a stand-in for the home header, in Portuguese.
  Future<void> pump(
    WidgetTester tester, {
    UpdateState state = update,
    Brightness brightness = Brightness.dark,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateNotifierProvider.overrideWith(
            (ref) => _FakeUpdateNotifier(state),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Theme(
              data: brightness == Brightness.dark
                  ? AppTheme.darkTheme(context)
                  : AppTheme.lightTheme(context),
              child: child!,
            ),
          ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('header'),
                  UpdateNotificationWidget(),
                  Text('balance'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('no new version, no banner', (tester) async {
    await pump(tester, state: const UpdateState(localVersion: '1.3.2'));
    await tester.pumpAndSettle();

    expect(find.byType(StatusBanner), findsNothing);
  });

  testWidgets('a new version shows a glass banner with the version and a '
      'close button', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.byType(StatusBanner), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatusBanner),
        matching: find.byType(GlassPanel),
      ),
      findsOneWidget,
    );
    expect(find.text(t.update_available_short), findsOneWidget);
    expect(
      find.text(
        '${t.update_version_label('1.4.0')} · ${t.update_available_body}',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(t.common_close), findsOneWidget);
  });

  testWidgets('a tap on the banner opens the sheet with both versions; '
      'later closes it and keeps the banner', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.update_available_short));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateSheet), findsOneWidget);
    final sheet = find.byType(UpdateSheet);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
    expect(inSheet(find.byType(GlassSheet)), findsOneWidget);
    expect(inSheet(find.text(t.update_dialog_title)), findsOneWidget);
    expect(inSheet(find.text('1.3.2')), findsOneWidget);
    expect(inSheet(find.text('1.4.0')), findsOneWidget);
    // The labels sit above their values, without the colon.
    expect(inSheet(find.text('Versão atual')), findsOneWidget);
    expect(inSheet(find.text('Nova versão')), findsOneWidget);
    expect(inSheet(find.text(t.update_available_button)), findsOneWidget);

    await tester.tap(inSheet(find.text(t.update_later)));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateSheet), findsNothing);
    expect(find.byType(StatusBanner), findsOneWidget);
  });

  testWidgets('the update button closes the sheet and runs the update', (
    tester,
  ) async {
    var updates = 0;
    await pump(tester);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(UpdateNotificationWidget));
    showFloatingGlassSheet<void>(
      context,
      builder: (_) => UpdateSheet(
        newVersion: '1.4.0',
        localVersion: '1.3.2',
        onUpdate: () => updates++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.update_available_button));
    await tester.pumpAndSettle();

    expect(updates, 1);
    expect(find.byType(UpdateSheet), findsNothing);
  });

  testWidgets('the close button puts the banner away and the content '
      'below moves up', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final balanceTop = tester.getTopLeft(find.text('balance')).dy;

    await tester.tap(find.byTooltip(t.common_close));
    await tester.pump(Motion.durationBase ~/ 2);
    // The banner fades out before the gap closes.
    expect(find.byType(StatusBanner), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(StatusBanner), findsNothing);
    expect(tester.getTopLeft(find.text('balance')).dy, lessThan(balanceTop));
  });

  testWidgets('under reduced motion the banner shows and goes at once', (
    tester,
  ) async {
    reduceMotion(tester);
    await pump(tester);
    await tester.pump();

    expect(find.byType(StatusBanner), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byTooltip(t.common_close));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StatusBanner), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the banner and the sheet fit a 320 pt screen at 200% text '
        'in the ${brightness.name} theme', (tester) async {
      await pump(
        tester,
        brightness: brightness,
        size: const Size(320, 640),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(t.update_available_short));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
