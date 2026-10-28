import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/asset_loading.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders [child] with the app theme of [brightness] and no Scaffold, so
/// the only Material is the one that the panel gives.
Widget _app(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: Builder(
      builder: (context) => Theme(
        data: brightness == Brightness.dark
            ? AppTheme.darkTheme(context)
            : AppTheme.lightTheme(context),
        child: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
}

void main() {
  group('GlassPanel', () {
    testWidgets('has no backdrop blur', (tester) async {
      await tester.pumpWidget(
        _app(const GlassPanel(child: SizedBox(height: 120))),
      );

      expect(find.byType(LiquidGlass), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('the floating glass still blurs the content behind it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const LiquidGlass(child: SizedBox(height: 64))),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('clips the content to the panel corners', (tester) async {
      await tester.pumpWidget(
        _app(const GlassPanel(child: SizedBox(height: 120))),
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, AppSurfaces.panelRadius);
    });

    testWidgets('rows inside it can use InkWell', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          GlassPanel(
            child: InkWell(
              onTap: () => taps++,
              child: const SizedBox(height: 56, width: double.infinity),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(taps, 1);
    });

    for (final brightness in Brightness.values) {
      testWidgets('renders the ${brightness.name} glass', (tester) async {
        await tester.pumpWidget(
          _app(
            const GlassPanel(
              padding: EdgeInsets.all(16),
              child: Text('Bitcoin'),
            ),
            brightness: brightness,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Bitcoin'), findsOneWidget);
      });
    }
  });

  testWidgets('the holdings skeleton uses the same glass panel', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const AssetLoading()));

    expect(find.byType(GlassPanel), findsOneWidget);
  });
}
