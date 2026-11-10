import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/app_lifecycle_controller.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/delete_wallet_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

import '../../../setup/presentation/setup_test_app.dart';

class _MockLifecycle extends Mock implements AppLifecycleController {}

class _MockSession extends Mock implements SessionManagerService {}

void main() {
  testWidgets('a deleted wallet starts over at the onboarding', (tester) async {
    final lifecycle = _MockLifecycle();
    when(
      () => lifecycle.deleteWalletAndReimport(),
    ).thenAnswer((_) async => const Right(unit));
    final session = _MockSession();
    when(() => session.resetIdentity()).thenReturn(TaskEither.right(unit));
    final opened = OpenedRoutes();
    usePhoneSize(tester);

    await tester.pumpWidget(
      setupTestApp(
        router: GoRouter(
          initialLocation: '/settings/delete-wallet',
          routes: [
            GoRoute(
              path: '/settings/delete-wallet',
              builder: (_, _) => const DeleteWalletScreen(),
            ),
            // Like the PIN screen, it confirms while it is still open.
            GoRoute(
              path: '/setup/pin/verify',
              builder: (_, state) => Scaffold(
                body: TextButton(
                  onPressed: (state.extra! as VerifyPinArgs).onPinConfirmed,
                  child: const Text('PIN'),
                ),
              ),
            ),
            opened.stub('/setup/onboarding'),
            opened.stub('/setup/first-access'),
          ],
        ),
        overrides: [
          appLifecycleControllerProvider.overrideWith((_) async => lifecycle),
          sessionManagerServiceProvider.overrideWithValue(session),
        ],
      ),
    );
    await tester.pump();
    final t = lookupAppLocalizations(const Locale('pt'));

    await tester.tap(find.text(t.delete_wallet_pix_limits_title));
    await tester.tap(find.text(t.delete_wallet_funds_loss_title));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(PrimaryButton, t.delete_wallet_button),
    );
    await settle(tester);
    await tester.tap(find.text('PIN'));
    await settle(tester);

    verify(() => lifecycle.deleteWalletAndReimport()).called(1);
    expect(opened.last, '/setup/onboarding');
  });
}
