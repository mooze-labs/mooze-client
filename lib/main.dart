import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquidSdk;
import 'package:lwk/lwk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_bootstrap.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_status_listener.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/transaction_status_listener.dart';
import 'package:mooze_mobile/shared/user/widgets/level_change_listener.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LibLwk.init();

  await liquidSdk.FlutterBreezLiquid.init();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(walletSyncBootstrapProvider);
    ref.read(connectivityProvider);
    return LevelChangeListener(
      child: TransactionStatusListener(
        child: PixStatusListener(
          child: MaterialApp.router(
            title: 'Mooze',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme(context),
            themeMode: ThemeMode.dark,
            routerConfig: router,
          ),
        ),
      ),
    );
  }
}
