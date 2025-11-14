import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquidSdk;
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_bootstrap.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/widgets/pix_status_listener.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/transaction_status_listener.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LibLwk.init();

  await liquidSdk.initialize();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(walletSyncBootstrapProvider);
    ref.read(connectivityProvider);
    return TransactionStatusListener(
      child: PixStatusListener(
        child: MaterialApp.router(
          title: 'Mooze',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme(context),
          themeMode: ThemeMode.dark,
          routerConfig: router,
        ),
      ),
    );
  }
}
