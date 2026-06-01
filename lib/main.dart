import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_device/safe_device.dart';
import 'package:safe_device/safe_device_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_foreground_observer.dart';
import 'package:mooze_mobile/app/session/widgets/session_lock_gate.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/locale_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_status_listener.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/transaction_status_listener.dart';
import 'package:mooze_mobile/shared/user/widgets/level_change_listener.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/diagnostics/boot_tracer.dart';
import 'package:mooze_mobile/shared/platform/platform_warmup.dart';
import 'package:mooze_mobile/shared/storage/mnemonic_prefetch.dart';

import 'routes.dart';

void main() async {
  BootTracer.start();
  WidgetsFlutterBinding.ensureInitialized();
  BootTracer.mark('main.bindings_ready');

  // Kick off the iOS Keychain read for the wallet mnemonic now, before anything
  // awaits it, so the platform-channel round-trip overlaps with runApp and
  // provider setup instead of sitting on the critical path. Downstream
  // consumers await this single future rather than issuing their own reads.
  MnemonicPrefetch.start();
  BootTracer.mark('main.mnemonic_prefetch_started');

  // Platform FFI inits (LibLwk + FlutterBreezLiquid). Started here (cached as
  // Futures inside `PlatformWarmup`) so they overlap with the rest of boot
  // instead of blocking the UI thread sequentially during the `platform` phase.
  // The boot orchestrator awaits the same Futures, so each library is still
  // initialized only once per process.
  PlatformWarmup.start();
  BootTracer.mark('main.platform_warmup_started');

  SafeDevice.init(SafeDeviceConfig(mockLocationCheckEnabled: false));
  BootTracer.mark('main.safe_device_init');
  final sharedPreferences = await SharedPreferences.getInstance();
  BootTracer.mark('main.shared_prefs_ready');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
  BootTracer.mark('main.runApp_returned');
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _v2BootStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_v2BootStarted) {
      _v2BootStarted = true;
      BootTracer.mark('app.first_build');
      // Trigger the V2 lifecycle exactly once on first build. The controller's
      // state machine handles existing-wallet vs. needs-setup branching: an
      // existing wallet runs the full boot pipeline; a fresh install waits for
      // the setup flow to invoke `start()` again after persisting the mnemonic.
      Future.microtask(() async {
        BootTracer.mark('app.controller.resolving');
        final c = await ref.read(appLifecycleControllerProvider.future);
        BootTracer.mark('app.controller.resolved');
        await c.start();
        BootTracer.mark('app.controller.start_returned');
      });
    }
    ref.read(connectivityProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return LevelChangeListener(
      child: AppForegroundObserver(
        child: TransactionStatusListener(
          child: PixStatusListener(
            child: MaterialApp.router(
              title: 'Mooze',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme(context),
              darkTheme: AppTheme.darkTheme(context),
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (deviceLocale, supported) {
                if (deviceLocale != null) {
                  for (final l in supported) {
                    if (l.languageCode == deviceLocale.languageCode) return l;
                  }
                }
                return const Locale('en');
              },
              routerConfig: router,
              // The session lock lives above the router, not inside it: stacking
              // it over the navigator keeps the current screen mounted, so the
              // lock clears back to exactly where the user was, with no route
              // push/pop. The gate collapses to nothing while unlocked.
              builder: (context, navigator) {
                return Stack(
                  children: [
                    navigator ?? const SizedBox.shrink(),
                    const SessionLockGate(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
