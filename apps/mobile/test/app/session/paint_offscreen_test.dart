import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/app/session/widgets/paint_offscreen.dart';
import 'package:mooze_mobile/app/session/widgets/privacy_shield_overlay.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  const ratio = 2.0;

  Future<Uint8List> pixels(ui.Image image) async => (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();

  for (final light in [true, false]) {
    for (final kind in [BiometricKind.face, null]) {
      final name =
          '${light ? 'light' : 'dark'}, '
          '${kind == null ? 'the vault' : 'the seal'}';
      testWidgets('paints the shield off the screen as the screen shows it: '
          '$name', (tester) async {
        tester.view.physicalSize = const Size(390, 844) * ratio;
        tester.view.devicePixelRatio = ratio;
        tester.view.padding = const FakeViewPadding(top: 47 * ratio);
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        late BuildContext context;
        final overlay = PrivacyShieldOverlay(sealKind: kind);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => Theme(
              data: light
                  ? AppTheme.lightTheme(context)
                  : AppTheme.darkTheme(context),
              child: child!,
            ),
            home: Builder(
              builder: (c) {
                context = c;
                return RepaintBoundary(key: key, child: overlay);
              },
            ),
          ),
        );
        // The logo and the glyphs load.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await tester.pump();

        final shown = await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          return pixels(await boundary.toImage(pixelRatio: ratio));
        });

        final media = MediaQuery.of(context);
        final painted = await tester.runAsync(() async {
          final image = await paintOffscreen(
            view: tester.view,
            child: MediaQuery(
              data: media,
              child: Localizations.override(
                context: context,
                child: InheritedTheme.captureAll(context, overlay),
              ),
            ),
            size: media.size,
            pixelRatio: ratio,
          );
          return pixels(image);
        });

        expect(painted!.length, shown!.length);
        var different = 0;
        for (var i = 0; i < shown.length; i += 4) {
          if (shown[i] != painted[i] ||
              shown[i + 1] != painted[i + 1] ||
              shown[i + 2] != painted[i + 2]) {
            different++;
          }
        }
        expect(different, 0);
        // Not a blank picture: the shield has its art and its texts.
        expect(painted.toSet().length, greaterThan(16));
      });
    }
  }

  testWidgets('waits for a part that arrives later, as a picture that '
      'loads, and paints it', (tester) async {
    final image = await tester.runAsync(
      () => paintOffscreen(
        view: tester.view,
        child: const _Later(),
        size: const Size(10, 10),
        pixelRatio: 1,
      ),
    );
    final bytes = await tester.runAsync(() => pixels(image!));
    // The color that arrived, not the empty box before it.
    expect(bytes!.sublist(0, 4), [255, 0, 0, 255]);
  });
}

/// Empty until a moment after it is built, then red, as a picture that
/// loads.
class _Later extends StatefulWidget {
  const _Later();

  @override
  State<_Later> createState() => _LaterState();
}

class _LaterState extends State<_Later> {
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _arrived = true);
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _arrived ? const Color(0xFFFF0000) : const Color(0x00000000),
  );
}
