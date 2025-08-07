import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquidSdk;
import 'package:mooze_mobile/themes/app_theme.dart';
// import 'themes/theme_base.dart';

// import 'package:mooze_mobile/services/notifications.dart';
// import 'package:mooze_mobile/widgets/lifecycle_manager.dart';
import 'routes.dart';

// Create a global navigator key
//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // await LibLwk.init();
  await liquidSdk.initialize();
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // final notificationService = NotificationService();
  // await notificationService.initialize();

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
