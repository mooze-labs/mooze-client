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
