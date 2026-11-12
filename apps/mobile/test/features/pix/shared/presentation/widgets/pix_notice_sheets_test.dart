import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/first_time_pix_sheet.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_limits_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// Opens a notice from a button with [show]. The result of the notice
  /// goes to [results].
  Future<void> open(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) show, {
    List<Object?>? results,
    bool dark = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Theme(
          data: dark
              ? AppTheme.darkTheme(context)
              : AppTheme.lightTheme(context),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                // Opens the notice even when no result is recorded.
                final result = await show(context);
                results?.add(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  PrimaryButton button(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  /// Lets the reading time of a notice pass, one second per frame, as the
  /// countdown ticks.
  Future<void> waitReading(WidgetTester tester) async {
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  }

  /// A drag down from the top of the sheet, above its body. The body
  /// scrolls, so a drag on it moves the text, not the sheet.
  Future<void> dragDown(WidgetTester tester) async {
    final top = tester.getRect(find.byType(GlassSheet)).topCenter;
    await tester.dragFrom(top + const Offset(0, 16), const Offset(0, 500));
    await tester.pumpAndSettle();
  }

  /// A tap outside the sheet, then a drag down.
  Future<void> tryToDismiss(WidgetTester tester) async {
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    if (find.byType(GlassSheet).evaluate().isEmpty) return;
    await dragDown(tester);
  }

  group('first access notice', () {
    testWidgets('opens as a floating glass sheet, not a dialog', (
      tester,
    ) async {
      await open(tester, FirstTimePixSheet.show);

      expect(find.text(t.pix_first_time_title), findsOneWidget);
      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(GlassDialog), findsNothing);
      expect(find.byType(GlassAlertDialog), findsNothing);
    });

    // The notice asks the user to accept the security review. Only the
    // accept button closes it.
    testWidgets('a tap outside or a drag down does not close it', (
      tester,
    ) async {
      await open(tester, FirstTimePixSheet.show);
      // No handle: nothing hints at a drag that does not close it.
      expect(find.byType(GlassSheetHandle), findsNothing);
      await tryToDismiss(tester);

      expect(find.byType(GlassSheet), findsOneWidget);
    });

    testWidgets('accepts with true once the reading time passes', (
      tester,
    ) async {
      final results = <Object?>[];
      await open(tester, FirstTimePixSheet.show, results: results);

      expect(button(tester).isEnabled, isFalse);
      expect(
        find.text(t.pix_first_time_accept_button_counting(7)),
        findsOneWidget,
      );
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsOneWidget);

      await waitReading(tester);
      expect(button(tester).isEnabled, isTrue);
      expect(find.text(t.pix_first_time_accept_button), findsOneWidget);

      // The countdown stops at zero, so the button stays unlocked.
      await tester.pump(const Duration(seconds: 3));
      expect(button(tester).isEnabled, isTrue);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsNothing);
      expect(results, [true]);
    });
  });

  group('limits notice', () {
    testWidgets('opens as a floating glass sheet, not a dialog', (
      tester,
    ) async {
      await open(tester, PixLimitsInfoSheet.show);

      expect(find.text(t.pix_limits_title), findsOneWidget);
      expect(find.text(t.pix_limits_initial_value), findsOneWidget);
      expect(find.text(t.pix_limits_max_value), findsOneWidget);
      expect(find.byType(GlassSheet), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(GlassAlertDialog), findsNothing);
    });

    // After the first-access notice the app shows the limits on its own, so
    // the user reads them before going on.
    testWidgets('shown on its own, it waits the reading time and only its '
        'button closes it', (tester) async {
      await open(tester, PixLimitsInfoSheet.show);

      expect(button(tester).isEnabled, isFalse);
      expect(
        find.text(t.pix_limits_button_understood_countdown(7)),
        findsOneWidget,
      );
      expect(find.byType(GlassSheetHandle), findsNothing);
      await tryToDismiss(tester);
      expect(find.byType(GlassSheet), findsOneWidget);

      await waitReading(tester);
      expect(button(tester).isEnabled, isTrue);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsNothing);
    });

    // The user tapped to read the limits. They may want to leave at once,
    // so nothing holds them.
    testWidgets('opened to read, its button closes it at once', (tester) async {
      await open(
        tester,
        (context) => PixLimitsInfoSheet.show(context, mustRead: false),
      );

      expect(button(tester).isEnabled, isTrue);
      expect(find.text(t.common_understood), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsNothing);
    });

    testWidgets('opened to read, a tap outside closes it', (tester) async {
      await open(
        tester,
        (context) => PixLimitsInfoSheet.show(context, mustRead: false),
      );

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsNothing);
    });

    testWidgets('opened to read, it shows a handle and a drag down closes '
        'it', (tester) async {
      await open(
        tester,
        (context) => PixLimitsInfoSheet.show(context, mustRead: false),
      );

      expect(find.byType(GlassSheetHandle), findsOneWidget);
      await dragDown(tester);
      expect(find.byType(GlassSheet), findsNothing);
    });
  });

  // A small phone at 200% text, in both themes: the body scrolls and the
  // button stays on screen.
  for (final dark in [true, false]) {
    final theme = dark ? 'dark' : 'light';
    for (final (name, show, title)
        in <(String, Future<Object?> Function(BuildContext), String)>[
          ('first access', FirstTimePixSheet.show, t.pix_first_time_title),
          ('limits', PixLimitsInfoSheet.show, t.pix_limits_title),
        ]) {
      testWidgets('the $name notice fits a small phone with large text '
          '($theme)', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await open(tester, show, dark: dark);

        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);
        final action = tester.getRect(find.byType(PrimaryButton));
        expect(action.bottom, lessThanOrEqualTo(568));
        expect(action.top, greaterThanOrEqualTo(0));
      });
    }
  }
}
