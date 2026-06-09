import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/security/screen_security_controller.dart';
import 'package:mooze_mobile/shared/security/secure_screen.dart';

const _channel = MethodChannel('com.flutterplaza.no_screenshot_methods');

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

  testWidgets('mounting SecureScreen claims protection, disposing releases it',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SecureScreen(child: Text('secret', textDirection: TextDirection.ltr)),
    ));
    expect(controller.isProtected, true);
    expect(controller.activeCount, 1);

    // Replace the whole tree — exercises a removal path that a back-only
    // PopScope would never observe.
    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    expect(controller.isProtected, false);
    expect(controller.activeCount, 0);
  });

  testWidgets('overlapping secure screens keep protection until the last unmounts',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SecureScreen(
        child: SecureScreen(
          child: Text('nested', textDirection: TextDirection.ltr),
        ),
      ),
    ));
    expect(controller.activeCount, 2);
    expect(controller.isProtected, true);

    await tester.pumpWidget(const MaterialApp(home: Text('home')));
    expect(controller.activeCount, 0);
    expect(controller.isProtected, false);
  });
}
