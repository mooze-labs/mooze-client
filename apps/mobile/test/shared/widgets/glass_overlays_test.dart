import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders [home] with the dark app theme on the MaterialApp, so dialog
/// routes get the theme too.
Widget _app(Widget home) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(400, 800)),
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        theme: AppTheme.darkTheme(context),
        home: home,
      ),
    ),
  );
}

/// Reads the RGBA bytes of the boundary with [key].
Future<(ByteData, int)> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return (bytes, image.width);
}

/// Red tint of the pixel at the center of the boundary with [key]: the red
/// channel minus the green channel. A neutral gray gives 0.
Future<int> _centerRedTint(WidgetTester tester, GlobalKey key) async {
  final (bytes, width) = await _pixels(tester, key);
  final height = bytes.lengthInBytes ~/ (width * 4);
  final offset = ((height ~/ 2) * width + width ~/ 2) * 4;
  return bytes.getUint8(offset) - bytes.getUint8(offset + 1);
}

/// A pure red square with a glass panel over it.
Widget _glassOverRed(GlobalKey key, {required bool opaque}) => _app(
  Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox.square(
          dimension: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFFFF0000)),
              LiquidGlass(
                borderRadius: BorderRadius.zero,
                blurBackdrop: false,
                opaque: opaque,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Map<String, Rect> _alertLayout(WidgetTester tester) => {
  for (final text in ['Title', 'Body', 'OK'])
    text: tester.getRect(find.text(text)),
};

void main() {
  group('Opaque glass', () {
    testWidgets('translucent glass shows the content behind it', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(_glassOverRed(key, opaque: false));
      expect(await _centerRedTint(tester, key), greaterThan(20));
    });

    testWidgets('opaque glass hides the content behind it', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(_glassOverRed(key, opaque: true));
      // The dark glass layers are neutral, so no red shows through.
      expect(await _centerRedTint(tester, key), 0);
    });
  });

  group('GlassSheet', () {
    /// A sheet at the bottom of the screen, with [bottomInset] as the
    /// system inset of the home indicator.
    Widget sheet({double bottomInset = 0}) => _app(
      Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: EdgeInsets.only(bottom: bottomInset)),
            child: const Align(
              alignment: Alignment.bottomCenter,
              // A modal bottom sheet gets the full screen width.
              child: GlassSheet(
                child: SizedBox(height: 200, width: double.infinity),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('floats with four round corners and no blur', (tester) async {
      await tester.pumpWidget(sheet());

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassSheet),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(
        clip.borderRadius,
        const BorderRadius.all(Radius.circular(GlassSheet.cornerRadius)),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('keeps a margin from the sides and the bottom', (tester) async {
      await tester.pumpWidget(sheet());

      final screen = tester.getRect(find.byType(Scaffold));
      final glass = tester.getRect(find.byType(LiquidGlass));
      expect(glass.left, screen.left + GlassSheet.sideMargin);
      expect(glass.right, screen.right - GlassSheet.sideMargin);
      expect(glass.bottom, screen.bottom - GlassSheet.minBottomGap);
    });

    testWidgets('sits just above the home indicator', (tester) async {
      await tester.pumpWidget(sheet(bottomInset: 34));

      final screen = tester.getRect(find.byType(Scaffold));
      final glass = tester.getRect(find.byType(LiquidGlass));
      // As the floating navigation bar: 8 pt into the 34 pt inset.
      expect(glass.bottom, screen.bottom - 26);
    });

    testWidgets('keeps the size limits of the sheet', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: GlassSheet(
                constraints: BoxConstraints(minHeight: 300),
                child: SizedBox(height: 10),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(LiquidGlass)).height, 300);
    });
  });

  group('GlassAlertDialog', () {
    Future<void> open(WidgetTester tester, {required bool glass}) async {
      // A fresh app, so no dialog from an earlier call stays open.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) {
                    const title = Text('Title');
                    const content = Text('Body');
                    final actions = [
                      TextButton(onPressed: () {}, child: const Text('OK')),
                    ];
                    return glass
                        ? GlassAlertDialog(
                            title: title,
                            content: content,
                            actions: actions,
                          )
                        : AlertDialog(
                            title: title,
                            content: content,
                            actions: actions,
                          );
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('places its parts as AlertDialog does at ${scale}x text', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await open(tester, glass: false);
        final expected = _alertLayout(tester);

        await open(tester, glass: true);
        expect(find.byType(LiquidGlass), findsOneWidget);
        final actual = _alertLayout(tester);
        for (final part in expected.keys) {
          expect(actual[part], expected[part], reason: part);
        }
      });
    }

    testWidgets('has the alert semantics of AlertDialog', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, glass: true);

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.semanticsRole, ui.SemanticsRole.alertDialog);
      expect(
        find.bySemanticsLabel(
          MaterialLocalizations.of(
            tester.element(find.text('Title')),
          ).alertDialogLabel,
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
