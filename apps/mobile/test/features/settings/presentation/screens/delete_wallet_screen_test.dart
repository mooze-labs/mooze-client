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
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';

import '../../../setup/presentation/setup_test_app.dart';

class _MockLifecycle extends Mock implements AppLifecycleController {}

class _MockSession extends Mock implements SessionManagerService {}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  late _MockLifecycle lifecycle;
  late OpenedRoutes opened;

  setUp(() {
    lifecycle = _MockLifecycle();
    when(
      () => lifecycle.deleteWalletAndReimport(),
    ).thenAnswer((_) async => const Right(unit));
    opened = OpenedRoutes();
  });

  Future<void> open(WidgetTester tester) async {
    final session = _MockSession();
    when(() => session.resetIdentity()).thenReturn(TaskEither.right(unit));
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
  }

  final slide = find.byType(SlideToConfirmButton);
  final thumb = find.descendant(
    of: slide,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector && widget.onHorizontalDragEnd != null,
    ),
  );

  SlideToConfirmButton slideOf(WidgetTester tester) =>
      tester.widget<SlideToConfirmButton>(
        find.byType(SlideToConfirmButton, skipOffstage: false),
      );

  Future<void> acknowledgeBothRisks(WidgetTester tester) async {
    await tester.tap(find.text(t.delete_wallet_pix_limits_title));
    await tester.tap(find.text(t.delete_wallet_funds_loss_title));
    await tester.pump();
  }

  testWidgets('the slide stays off until the user acknowledges both risks', (
    tester,
  ) async {
    await open(tester);
    expect(slideOf(tester).text, t.delete_wallet_button);
    expect(slideOf(tester).isEnabled, isFalse);

    await tester.drag(thumb, const Offset(800, 0));
    await settle(tester);
    expect(find.text('PIN'), findsNothing);

    await tester.tap(find.text(t.delete_wallet_pix_limits_title));
    await tester.pump();
    expect(slideOf(tester).isEnabled, isFalse);
    await tester.tap(find.text(t.delete_wallet_funds_loss_title));
    await tester.pump();
    expect(slideOf(tester).isEnabled, isTrue);
  });

  testWidgets('a tap asks for nothing: only a slide opens the PIN', (
    tester,
  ) async {
    await open(tester);
    await acknowledgeBothRisks(tester);

    await tester.tap(slide);
    await settle(tester);
    expect(find.text('PIN'), findsNothing);

    await tester.drag(thumb, const Offset(800, 0));
    await settle(tester);
    expect(find.text('PIN'), findsOneWidget);
  });

  testWidgets('a deleted wallet starts over at the onboarding', (tester) async {
    await open(tester);
    await acknowledgeBothRisks(tester);

    await tester.drag(thumb, const Offset(800, 0));
    await settle(tester);
    await tester.tap(find.text('PIN'));
    await settle(tester);

    verify(() => lifecycle.deleteWalletAndReimport()).called(1);
    expect(opened.last, '/setup/onboarding');
  });

  testWidgets('the slide waits at its end while the PIN is asked, and comes '
      'back when the user leaves the PIN', (tester) async {
    await open(tester);
    await acknowledgeBothRisks(tester);

    await tester.drag(thumb, const Offset(800, 0));
    await settle(tester);
    expect(find.text('PIN'), findsOneWidget);
    expect(slideOf(tester).isLoading, isTrue);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('PIN'), findsNothing);
    expect(slideOf(tester).isLoading, isFalse);
    expect(
      tester.getRect(thumb).left,
      moreOrLessEquals(tester.getRect(slide).left),
    );
    verifyNever(() => lifecycle.deleteWalletAndReimport());
  });
}
