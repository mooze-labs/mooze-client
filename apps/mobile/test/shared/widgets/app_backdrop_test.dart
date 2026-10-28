import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders [child] with the app theme of [brightness].
Widget _app(Widget child, {required Brightness brightness}) {
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
        child: child,
      ),
    ),
  );
}

/// Reads the RGBA bytes of the boundary with [key].
Future<ByteData> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  image.dispose();
  return bytes;
}

/// Returns the RGBA channels of pixel ([x], [y]).
List<int> _pixel(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return [for (var i = 0; i < 4; i++) bytes.getUint8(offset + i)];
}

/// Checks that each channel differs by at most one step. Gradient
/// rasterization can round one channel differently in two draws.
Matcher _sameColorAs(List<int> expected) => predicate<List<int>>(
  (actual) => [
    for (var i = 0; i < 4; i++) (actual[i] - expected[i]).abs(),
  ].every((difference) => difference <= 1),
  'within one step of $expected',
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a slice matches the full backdrop in the ${brightness.name} '
        'theme', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final fullKey = GlobalKey();
      final sliceKey = GlobalKey();
      await tester.pumpWidget(
        _app(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The full backdrop, from the top of the screen.
              SizedBox(
                width: 200,
                height: 600,
                child: RepaintBoundary(
                  key: fullKey,
                  child: const AppBackdrop(),
                ),
              ),
              // A header slice that starts 100 pt below the top.
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: SizedBox(
                  width: 200,
                  height: 60,
                  child: RepaintBoundary(
                    key: sliceKey,
                    child: const AppBackdrop(origin: 100),
                  ),
                ),
              ),
            ],
          ),
          brightness: brightness,
        ),
      );

      final full = await _pixels(tester, fullKey);
      final slice = await _pixels(tester, sliceKey);
      for (final y in [0, 30, 59]) {
        for (final x in [10, 100, 190]) {
          expect(
            _pixel(slice, 200, x, y),
            _sameColorAs(_pixel(full, 200, x, y + 100)),
            reason: 'pixel ($x, $y) of the slice',
          );
        }
      }
    });
  }

  testWidgets('the dark backdrop fades graphite into the page', (tester) async {
    late BackdropStyle style;
    late ColorScheme scheme;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            style = BackdropStyle.of(context);
            scheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
        brightness: Brightness.dark,
      ),
    );

    expect(style.colors.first, scheme.surfaceContainerHighest);
    expect(style.colors.last, scheme.surfaceDim);
    expect(style.glow, isNull);
  });

  testWidgets('the light backdrop is a pearl wash with a brand blush', (
    tester,
  ) async {
    late BackdropStyle style;
    late ColorScheme scheme;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            style = BackdropStyle.of(context);
            scheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
        brightness: Brightness.light,
      ),
    );

    expect(style.colors.first, scheme.surfaceBright);
    expect(style.colors.last, scheme.surfaceDim);
    expect(style.glow?.withValues(alpha: 1), scheme.primaryContainer);
  });

  testWidgets('the backdrop app bar paints the backdrop behind its title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          extendBodyBehindAppBar: true,
          appBar: BackdropAppBar(title: Text('Ativos')),
          body: AppBackdrop(),
        ),
        brightness: Brightness.dark,
      ),
    );

    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.backgroundColor, Colors.transparent);
    expect(bar.flexibleSpace, isA<AppBackdrop>());
    expect(find.text('Ativos'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('a panel differs from the page in the ${brightness.name} '
        'theme', (tester) async {
      late BoxDecoration panel;
      late ColorScheme scheme;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              panel = AppSurfaces.panel(context);
              scheme = Theme.of(context).colorScheme;
              return const SizedBox();
            },
          ),
          brightness: brightness,
        ),
      );

      expect(panel.color, isNot(scheme.surfaceDim));
      if (brightness == Brightness.light) {
        expect(panel.boxShadow, isNotEmpty);
      } else {
        expect(panel.border, isNotNull);
      }
    });
  }
}
