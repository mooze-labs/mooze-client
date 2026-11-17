import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/app/session/lock_seal_provider.dart';
import 'package:mooze_mobile/app/session/widgets/privacy_shield_overlay.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/pin_setup/widgets/biometric_scene.dart';
import 'package:mooze_mobile/app/session/widgets/native_privacy_cover_bridge.dart';
import 'package:mooze_mobile/shared/clipboard/clipboard_reader.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  /// A channel the test calls right after a prompt starts, as the plugin of
  /// the prompt would.
  const prompt = MethodChannel('test/prompt');

  late List<String> calls;
  late ProviderContainer providers;
  late ThemeMode mode;
  late StateSetter setMode;

  /// Records the messages to the cover and to [prompt], in their order.
  void record(WidgetTester tester) {
    calls = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    for (final channel in [NativePrivacyCoverBridge.channel, prompt]) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add('${call.method}(${call.arguments ?? ''})');
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }
  }

  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  /// The shields the fake painter painted, with their size and pixel ratio.
  late List<(PrivacyShieldOverlay, Size, double)> painted;

  Future<Uint8List?> painter(
    ui.FlutterView view,
    Widget shield,
    Size size,
    double pixelRatio,
  ) async {
    painted.add((_find<PrivacyShieldOverlay>(shield), size, pixelRatio));
    return Uint8List.fromList([1, 2, 3]);
  }

  Future<void> pump(WidgetTester tester, {bool snapshot = false}) async {
    addTearDown(ClipboardReader.debugReset);
    record(tester);
    painted = [];
    mode = ThemeMode.light;
    providers = ProviderContainer(
      overrides: [
        lockSealKindProvider.overrideWith((ref) async => BiometricKind.face),
      ],
    );
    addTearDown(providers.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providers,
        child: StatefulBuilder(
          builder: (context, setState) {
            setMode = setState;
            return MaterialApp(
              theme: AppTheme.lightTheme(context),
              darkTheme: AppTheme.darkTheme(context),
              themeMode: mode,
              builder: (context, child) => NativePrivacyCoverBridge(
                snapshot: snapshot,
                painter: painter,
                child: child!,
              ),
              home: const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  testWidgets('tells iOS the color of the backdrop, and again when the '
      'theme changes', (tester) async {
    await pump(tester);
    List<String> colors() =>
        calls.where((c) => c.startsWith('setColor')).toList();
    expect(colors(), hasLength(1));
    final light = colors().single;

    // The theme animates: the cover follows it, and ends on the dark one.
    setMode(() => mode = ThemeMode.dark);
    await tester.pumpAndSettle();
    final dark = colors().last;
    expect(dark, isNot(light));

    setMode(() => mode = ThemeMode.light);
    await tester.pumpAndSettle();
    expect(colors().last, light);
  }, variant: ios);

  testWidgets('keeps the cover down while one of our prompts is up, and '
      'says so before the prompt opens', (tester) async {
    await pump(tester);
    expect(calls, contains('setSuppressed(false)'));
    calls.clear();

    providers.read(authPromptActiveProvider.notifier).begin();
    await prompt.invokeMethod<void>('authenticate');
    expect(calls, ['setSuppressed(true)', 'authenticate()']);

    providers.read(authPromptActiveProvider.notifier).end();
    await tester.pump();
    expect(calls.last, 'setSuppressed(false)');
  }, variant: ios);

  testWidgets('keeps the cover down while the clipboard is read', (
    tester,
  ) async {
    await pump(tester);
    final answer = Completer<Map<String, dynamic>?>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return answer.future;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    calls.clear();

    final read = ClipboardReader.readText();
    await tester.pump();
    expect(calls, ['setSuppressed(true)']);

    answer.complete({'text': 'lq1qq'});
    await read;
    await tester.pump();
    expect(calls, ['setSuppressed(true)', 'setSuppressed(false)']);
  }, variant: ios);

  testWidgets('releases the cover once the app is back and its first frame '
      'is drawn, not before', (tester) async {
    await pump(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    calls.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, isEmpty);
    await tester.pump();
    expect(calls, ['release()']);
  }, variant: ios);

  group('the picture of the shield', () {
    List<String> images() =>
        calls.where((c) => c.startsWith('setImage')).toList();

    testWidgets('is painted once the app is idle, from the shield of '
        'Flutter, at the size of the screen, and sent with its scale', (
      tester,
    ) async {
      await pump(tester, snapshot: true);
      await tester.pump();
      expect(painted, isEmpty);

      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      final (shield, size, ratio) = painted.single;
      expect(shield.sealKind, BiometricKind.face);
      expect(shield.onUsePin, isNull);
      expect(size, tester.view.physicalSize / tester.view.devicePixelRatio);
      expect(ratio, tester.view.devicePixelRatio);
      expect(images().single, contains('[1, 2, 3]'));
      expect(
        images().single,
        contains('scale: ${tester.view.devicePixelRatio}'),
      );
    }, variant: ios);

    testWidgets('is painted again when what the shield shows changes, once '
        'the theme has ended its animation, and not otherwise', (tester) async {
      await pump(tester, snapshot: true);
      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      expect(painted, hasLength(1));

      setMode(() => mode = ThemeMode.dark);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      expect(painted, hasLength(2));

      // Back in the app, with nothing changed.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      expect(painted, hasLength(2));
      expect(images(), hasLength(2));
    }, variant: ios);

    testWidgets('waits for the foreground', (tester) async {
      await pump(tester, snapshot: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      expect(painted, isEmpty);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
      await tester.pump();
      expect(painted, hasLength(1));
    }, variant: ios);
  });

  testWidgets('does nothing on Android', (tester) async {
    await pump(tester, snapshot: true);
    providers.read(authPromptActiveProvider.notifier).begin();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(NativePrivacyCoverBridge.snapshotDelay);
    await tester.pump();
    expect(calls, isEmpty);
    expect(painted, isEmpty);
  });
}

/// The [T] that [widget] wraps, down its line of `child`ren: the painter
/// gets the shield in its media query, localizations and theme.
T _find<T>(Object widget) {
  Object? node = widget;
  while (node != null && node is! T) {
    node = (node as dynamic).child as Object?;
  }
  return node as T;
}
