import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/security/screen_security_controller.dart';

/// The `no_screenshot` plugin talks to native over this method channel.
const _channel = MethodChannel('com.flutterplaza.no_screenshot_methods');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final controller = ScreenSecurityController.instance;

  /// Records the sequence of native calls the controller issues so we can
  /// assert the OS flag is toggled exactly at the 0↔1 boundaries.
  late List<String> calls;

  setUp(() async {
    calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      return true;
    });

    // Singleton state leaks across tests — normalize to a known baseline, then
    // drop the reset's own `screenshotOn` from the log so each test starts at
    // count 0 with an empty call list.
    await controller.reset();
    calls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('ScreenSecurityController reference counting', () {
    test('first enable turns protection ON exactly once', () async {
      await controller.enable();

      expect(controller.activeCount, 1);
      expect(controller.isProtected, true);
      expect(calls, ['screenshotOff']);
    });

    test('overlapping enables do not re-toggle the OS flag', () async {
      await controller.enable();
      await controller.enable();
      await controller.enable();

      expect(controller.activeCount, 3);
      // Only the 0→1 transition hits native.
      expect(calls, ['screenshotOff']);
    });

    test('protection stays ON until the LAST claim is released', () async {
      await controller.enable();
      await controller.enable();
      calls.clear();

      await controller.disable(); // 2 -> 1, still protected, no native call
      expect(controller.activeCount, 1);
      expect(controller.isProtected, true);
      expect(calls, isEmpty);

      await controller.disable(); // 1 -> 0, protection off
      expect(controller.activeCount, 0);
      expect(controller.isProtected, false);
      expect(calls, ['screenshotOn']);
    });

    test('a single enable/disable pair flips ON then OFF', () async {
      await controller.enable();
      await controller.disable();

      expect(controller.activeCount, 0);
      expect(calls, ['screenshotOff', 'screenshotOn']);
    });

    test('unbalanced disable at zero is a safe no-op', () async {
      await controller.disable();

      expect(controller.activeCount, 0);
      expect(controller.isProtected, false);
      expect(calls, isEmpty);
    });

    test('reset forces count to zero and clears the OS flag', () async {
      await controller.enable();
      await controller.enable();
      calls.clear();

      await controller.reset();

      expect(controller.activeCount, 0);
      expect(controller.isProtected, false);
      expect(calls, ['screenshotOn']);
    });

    test('count never goes negative under extra releases', () async {
      await controller.enable();
      await controller.disable();
      await controller.disable(); // extra
      await controller.disable(); // extra

      expect(controller.activeCount, 0);
    });
  });
}
