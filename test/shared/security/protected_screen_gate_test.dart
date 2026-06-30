import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/security/protected_screen_gate.dart';
import 'package:mooze_mobile/shared/security/screen_security_controller.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

const _channel = MethodChannel('com.flutterplaza.no_screenshot_methods');

Widget _gate(Widget child) => MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [AppExtraColors.dark],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ProtectedScreenGate(
        logo: const SizedBox.shrink(),
        child: child,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final controller = ScreenSecurityController.instance;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async => true);
    // Reset synchronously (don't await): the controller's plugin-call queue
    // never completes inside a FakeAsync test zone, so awaiting it here would
    // deadlock on the prior test's leaked call. The assertions read the
    // synchronous refcount, which reset() zeroes immediately.
    controller.reset();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  testWidgets(
      'protection stays OFF (warning capturable) until reveal, then ON',
      (tester) async {
    await tester.pumpWidget(_gate(const Text('TOP-SECRET-SEED')));
    await tester.pump();

    // HYBRID: while only the warning is visible, FLAG_SECURE stays OFF so a
    // screenshot here captures the branded warning rather than black.
    expect(controller.isProtected, false);
    expect(find.text('TOP-SECRET-SEED'), findsNothing);
    expect(find.text('Screenshot Blocked'), findsOneWidget);

    // Acknowledge → secret revealed AND protection turns ON.
    await tester.tap(find.text('I understand'));
    await tester.pump();
    expect(find.text('TOP-SECRET-SEED'), findsOneWidget);
    expect(controller.isProtected, true);
  });

  testWidgets('revealing then disposing releases protection', (tester) async {
    await tester.pumpWidget(_gate(const Text('secret')));
    await tester.pump();
    expect(controller.activeCount, 0); // no claim while gated

    await tester.tap(find.text('I understand'));
    await tester.pump();
    expect(controller.activeCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.activeCount, 0);
    expect(controller.isProtected, false);
  });

  testWidgets('leaving the gate WITHOUT revealing takes no claim',
      (tester) async {
    await tester.pumpWidget(_gate(const Text('secret')));
    await tester.pump();
    expect(controller.activeCount, 0);

    // Navigate away without acknowledging — must not leave a dangling claim.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.activeCount, 0);
    expect(controller.isProtected, false);
  });
}
