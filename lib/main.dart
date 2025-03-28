import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/widgets/lifecycle_manager.dart';
import 'routes.dart';
import 'themes/theme_base.dart' as mooze_theme;

void main() async {
  await LibLwk.init();
  //await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleManager(
      child: MaterialApp(
        title: 'Mooze',
        theme: mooze_theme.themeData,
        initialRoute: '/splash',
        routes: appRoutes,
      ),
    );
  }
}
