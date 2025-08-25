import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquidSdk;
import 'package:mooze_mobile/themes/app_theme.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await LibLwk.init();

  await liquidSdk.initialize();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mooze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
