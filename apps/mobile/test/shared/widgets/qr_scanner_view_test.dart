import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Renders [view] as the app does, in Portuguese.
Widget _host(Widget view) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    builder: (context, child) =>
        Theme(data: AppTheme.darkTheme(context), child: child!),
    home: view,
  );
}

/// A camera that failed with [code], without starting a real camera.
MobileScannerController _failedCamera(
  MobileScannerErrorCode code, {
  String? message,
}) {
  return MobileScannerController(autoStart: false)
    ..value = const MobileScannerState.uninitialized().copyWith(
      isInitialized: true,
      error: MobileScannerException(
        errorCode: code,
        errorDetails: message == null
            ? null
            : MobileScannerErrorDetails(message: message),
      ),
    );
}

void main() {
  QrScannerView view({
    bool found = false,
    MobileScannerController? controller,
    String? unavailableMessage,
    Widget? unavailableAction,
  }) {
    return QrScannerView(
      title: 'Pagar com QR Code',
      hint: 'Posicione o código',
      detail: 'Pix',
      found: found,
      onCode: (_) {},
      unavailableMessage: unavailableMessage,
      unavailableAction: unavailableAction,
      controller: controller,
      debugPreview: const ColoredBox(color: Colors.black),
    );
  }

  testWidgets('shows the title, the hints and the camera controls', (
    tester,
  ) async {
    await tester.pumpWidget(_host(view()));
    await tester.pump();

    expect(find.text('Pagar com QR Code'), findsOneWidget);
    expect(find.text('Posicione o código'), findsOneWidget);
    expect(find.text('Pix'), findsOneWidget);
    expect(find.text('Procurando QR Code...'), findsOneWidget);
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('Câmera'), findsOneWidget);
  });

  testWidgets('a code in handling shows as found', (tester) async {
    await tester.pumpWidget(_host(view(found: true)));
    await tester.pumpAndSettle();

    expect(find.text('QR Code encontrado!'), findsOneWidget);
    expect(find.text('Procurando QR Code...'), findsNothing);
  });

  testWidgets('a blocked camera offers the settings, not the controls', (
    tester,
  ) async {
    final camera = _failedCamera(MobileScannerErrorCode.permissionDenied);

    await tester.pumpWidget(
      _host(
        view(
          controller: camera,
          unavailableAction: const Text('Pix Copia e Cola'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câmera bloqueada'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
    // The way out of a failed camera is not the way out of a blocked one.
    expect(find.text('Pix Copia e Cola'), findsNothing);
    expect(find.text('Flash'), findsNothing);
  });

  testWidgets('another camera failure shows the way out of the screen', (
    tester,
  ) async {
    final camera = _failedCamera(MobileScannerErrorCode.genericError);

    await tester.pumpWidget(
      _host(
        view(
          controller: camera,
          unavailableMessage: 'Use o Pix Copia e Cola.',
          unavailableAction: const Text('Pix Copia e Cola'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Câmera indisponível'), findsOneWidget);
    expect(find.text('Use o Pix Copia e Cola.'), findsOneWidget);
    expect(find.text('Pix Copia e Cola'), findsOneWidget);
    expect(find.text('Procurando QR Code...'), findsNothing);
  });

  testWidgets('the camera hands a binary code to a host that reads bytes, '
      'and the text of a code to the others', (tester) async {
    final binary = Barcode(rawBytes: Uint8List.fromList([0x0a, 0x00, 0x0d]));
    final barcodes = <Barcode>[];
    final codes = <String>[];
    // The real camera view, with a camera that never starts.
    Widget camera({required bool readsBytes}) => _host(
      QrScannerView(
        title: 'SeedQR',
        hint: 'Posicione o código',
        found: false,
        onCode: readsBytes ? null : codes.add,
        onBarcode: readsBytes ? barcodes.add : null,
        controller: MobileScannerController(autoStart: false),
      ),
    );
    void detect(WidgetTester tester, List<Barcode> found) => tester
        .widget<MobileScanner>(find.byType(MobileScanner))
        .onDetect!(BarcodeCapture(barcodes: found));

    await tester.pumpWidget(camera(readsBytes: true));
    detect(tester, [const Barcode(), binary]);
    expect(barcodes, [same(binary)]);

    await tester.pumpWidget(camera(readsBytes: false));
    detect(tester, [binary, const Barcode(rawValue: 'texto')]);
    expect(codes, ['texto']);
  });

  test('a host that reads bytes gets the first code with content, a binary '
      'code without text too', () {
    final binary = Barcode(rawBytes: Uint8List.fromList([0x0a, 0x00, 0x0d]));
    const text = Barcode(rawValue: 'texto');

    expect(
      QrScannerView.readableBarcode([const Barcode(), binary, text]),
      same(binary),
    );
    expect(
      QrScannerView.readableBarcode([const Barcode(rawValue: ''), text]),
      same(text),
    );
    expect(
      QrScannerView.readableBarcode([Barcode(rawBytes: Uint8List(0))]),
      isNull,
    );
  });

  testWidgets('a failure message of the camera comes first', (tester) async {
    final camera = _failedCamera(
      MobileScannerErrorCode.genericError,
      message: 'No camera found',
    );

    await tester.pumpWidget(
      _host(
        view(controller: camera, unavailableMessage: 'Use o Pix Copia e Cola.'),
      ),
    );
    await tester.pump();

    expect(find.text('No camera found'), findsOneWidget);
    // Without an action of the screen, the way out is back.
    expect(find.text('Voltar'), findsOneWidget);
  });
}
