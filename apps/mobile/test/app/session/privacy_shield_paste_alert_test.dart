import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_foreground_observer.dart';
import 'package:mooze_mobile/app/session/privacy_shield_controller.dart';
import 'package:mooze_mobile/app/session/privacy_shield_state.dart';
import 'package:mooze_mobile/shared/clipboard/clipboard_reader.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On iOS 16 and later, a read of text that another app copied shows the
/// system "Allow Paste" alert. The alert takes the app out of the active
/// state, so Flutter reports `inactive`, as for the app switcher. That
/// `inactive` may arrive while the read waits, or right after its answer.
/// The shield must not rise for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Completer<Object?> clipboard;
  late DateTime now;

  setUp(() {
    clipboard = Completer<Object?>();
    now = DateTime(2026, 11, 12, 10);
    ClipboardReader.debugReset();
    ClipboardReader.now = () => now;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return clipboard.future;
          return null;
        });
  });

  tearDown(() {
    ClipboardReader.now = DateTime.now;
    ClipboardReader.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  PrivacyShieldState shield(ProviderContainer c) =>
      c.read(privacyShieldControllerProvider);

  test('reads the text of the clipboard', () async {
    final read = ClipboardReader.readText();
    clipboard.complete({'text': 'lq1qqexample'});
    expect(await read, 'lq1qqexample');
  });

  group('the shield and the paste alert', () {
    test('an inactive while a read waits does not raise the shield', () async {
      final c = await container();
      final read = ClipboardReader.readText();

      c.read(privacyShieldControllerProvider.notifier).onInactive();

      expect(shield(c), PrivacyShieldState.hidden);
      clipboard.complete(null);
      await read;
    });

    test('an inactive right after the answer does not raise it', () async {
      final c = await container();
      final read = ClipboardReader.readText();
      clipboard.complete({'text': 'x'});
      await read;

      now = now.add(const Duration(milliseconds: 900));
      c.read(privacyShieldControllerProvider.notifier).onInactive();

      expect(shield(c), PrivacyShieldState.hidden);
    });

    // The window is short: an app switch after it is covered as always.
    test('an inactive once the read settled raises it', () async {
      final c = await container();
      final read = ClipboardReader.readText();
      clipboard.complete({'text': 'x'});
      await read;

      now = now.add(ClipboardReader.alertSettle);
      c.read(privacyShieldControllerProvider.notifier).onInactive();

      expect(shield(c), PrivacyShieldState.visible);
    });

    test('with no read, an inactive raises it', () async {
      final c = await container();

      c.read(privacyShieldControllerProvider.notifier).onInactive();

      expect(shield(c), PrivacyShieldState.visible);
    });

    // Leaving the app while the alert is open is a real backgrounding.
    test('a real backgrounding during a read still raises it', () async {
      final c = await container();
      final read = ClipboardReader.readText();

      c.read(privacyShieldControllerProvider.notifier).onLeavingForeground();

      expect(shield(c), PrivacyShieldState.visible);
      clipboard.complete(null);
      await read;
    });
  });

  group('the app lifecycle', () {
    Future<ProviderContainer> observe(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionNotifierProvider.overrideWith(
            (ref) => Completer<Never>().future,
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AppForegroundObserver(child: SizedBox()),
        ),
      );
      return container;
    }

    testWidgets('the inactive of a paste alert leaves the screen as it is', (
      tester,
    ) async {
      final c = await observe(tester);
      // Made inside the fake time of the test: a completer made in `setUp`
      // would answer only after the test ends.
      clipboard = Completer<Object?>();
      final read = ClipboardReader.readText();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(shield(c), PrivacyShieldState.hidden);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      clipboard.complete(null);
      await read;
    });

    testWidgets('an app switch raises the shield', (tester) async {
      final c = await observe(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(shield(c), PrivacyShieldState.visible);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  // Every read goes through [ClipboardReader], so every paste alert is
  // known to the shield.
  test('the app reads the clipboard only through ClipboardReader', () {
    final direct = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('clipboard_reader.dart'))
        .where((file) => file.readAsStringSync().contains('Clipboard.getData'))
        .map((file) => file.path)
        .toList();

    expect(direct, isEmpty);
  });
}
