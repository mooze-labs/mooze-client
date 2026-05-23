import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_device/safe_device.dart';
import 'package:safe_device/safe_device_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_foreground_observer.dart';
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

import 'routes.dart';

void main() async {
  BootTracer.start();
  WidgetsFlutterBinding.ensureInitialized();
  BootTracer.mark('main.bindings_ready');

  // Platform FFI inits (LibLwk + FlutterBreezLiquid) are owned by the V2
  // `PlatformInitializerImpl` and run during V2 boot. Calling them here
  // too produces `Bad state: Should not initialize flutter_rust_bridge
  // twice` the first time V2 boot starts.

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
      // Trigger V2 lifecycle exactly once on first build. The controller's
      // own state machine handles existing-wallet vs. needs-setup branching:
      // for an existing wallet this runs the full boot pipeline; for a
      // fresh install it transitions to `AppPhase.needsSetup` and waits
      // for the setup flow (import_button / create-wallet) to invoke
      // `start()` again after the mnemonic is persisted.
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
            ),
          ),
        ),
      ),
    );
  }
}
