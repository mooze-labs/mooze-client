import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/services/notifications.dart';
import 'package:mooze_mobile/widgets/lifecycle_manager.dart';
import 'routes.dart';
import 'themes/theme_base.dart' as mooze_theme;

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await LibLwk.init();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleManager(
      navigatorKey: navigatorKey,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Mooze',
        debugShowCheckedModeBanner: false,
        theme: mooze_theme.themeData,
        initialRoute: '/splash',
        routes: appRoutes,
      ),
    );
  }
}
