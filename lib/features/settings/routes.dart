import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/referral_input/referral_input_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/currency_selector_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/delete_wallet_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/license_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:mooze_mobile/features/support/presentations/srcreens/support_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/terms_and_conditions.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/view_mnemonic.dart';

final settingsRoutes = [
  GoRoute(path: "/settings", builder: (context, state) => SettingsScreen()),
  GoRoute(
    path: "/settings/delete-wallet",
    builder: (context, state) => DeleteWalletScreen(),
  ),
  GoRoute(
    path: '/settings/license',
    builder: (context, state) => LicenseScreen(),
  ),
  GoRoute(
    path: '/settings/terms',
    builder: (context, state) => TermsAndConditionsScreen(),
  ),
  GoRoute(
    path: '/settings/support',
    builder: (context, state) => SupportScreen(),
  ),
  GoRoute(
    path: '/settings/view-mnemonic',
    builder:
        (context, state) => ViewMnemonicScreen(mnemonic: state.extra as String),
  ),
  GoRoute(
    path: '/settings/referral',
    builder: (context, state) => ReferralInputScreen(),
  ),
  GoRoute(
    path: '/settings/currency-selector',
    builder: (context, state) => CurrencySelectorScreen(),
  ),
];
