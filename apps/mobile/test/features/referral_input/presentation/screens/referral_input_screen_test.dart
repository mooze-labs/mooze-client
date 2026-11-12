import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/features/referral_input/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/features/referral_input/presentation/screens/referral_input_screen.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/active_referral_card.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_code_input.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_info_card.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_submit_button.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/utils/result.dart';
import '../../../../shared/test_app.dart';

class MockGetExistingReferralUseCase extends Mock
    implements GetExistingReferralUseCase {}

class MockApplyReferralCodeUseCase extends Mock
    implements ApplyReferralCodeUseCase {}

void main() {
  late MockGetExistingReferralUseCase mockGetExistingReferral;
  late MockApplyReferralCodeUseCase mockApplyReferralCode;

  setUp(() {
    mockGetExistingReferral = MockGetExistingReferralUseCase();
    mockApplyReferralCode = MockApplyReferralCodeUseCase();
  });

  /// [home] replaces the screen as the first route, so a test can push the
  /// screen over it.
  Widget buildScreen({
    bool isApiDown = false,
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        getExistingReferralUseCaseProvider.overrideWithValue(
          mockGetExistingReferral,
        ),
        applyReferralCodeUseCaseProvider.overrideWithValue(
          mockApplyReferralCode,
        ),
        apiDownProvider.overrideWith((ref) => isApiDown),
        connectivityProvider.overrideWith(
          (ref) => ConnectivityNotifier()
            ..state = ConnectivityState(
              isOnline: true,
              lastUpdate: DateTime.now(),
              consecutiveFailures: 0,
            ),
        ),
      ],
      child: wrapForTest(home ?? ReferralInputScreen(),
      ),
    );
  }

  group('ReferralInputScreen', () {
    group('when no existing referral code', () {
      setUp(() {
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success(null));
      });

      testWidgets('should display app bar title', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Código de Indicação'), findsWidgets);
      });

      testWidgets('should display ReferralInfoCard', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ReferralInfoCard), findsOneWidget);
      });

      testWidgets('should display ReferralCodeInput', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ReferralCodeInput), findsOneWidget);
      });

      testWidgets('should display ReferralSubmitButton', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ReferralSubmitButton), findsOneWidget);
      });

      testWidgets('should not display ActiveReferralCard', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ActiveReferralCard), findsNothing);
      });

      // The settings push this screen. The app bar has no leading of its
      // own: it shows the back button of the app, because the route can
      // pop. The glyph comes from the app theme, so the test looks for the
      // button and for what it does.
      testWidgets('should display back button', (tester) async {
        await tester.pumpWidget(
          buildScreen(home: const Scaffold(body: Text('Settings'))),
        );
        Navigator.of(tester.element(find.text('Settings'))).push(
          MaterialPageRoute<void>(builder: (_) => ReferralInputScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(ReferralInputScreen), findsNothing);
        expect(find.text('Settings'), findsOneWidget);
      });
    });

    group('when existing referral code exists', () {
      setUp(() {
        when(() => mockGetExistingReferral())
            .thenAnswer((_) async => const Success('MOOZE123'));
      });

      testWidgets('should display ActiveReferralCard', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ActiveReferralCard), findsOneWidget);
        expect(find.text('Código: MOOZE123'), findsOneWidget);
      });

      testWidgets('should not display ReferralCodeInput', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ReferralCodeInput), findsNothing);
      });

      testWidgets('should not display ReferralSubmitButton', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ReferralSubmitButton), findsNothing);
      });
    });
  });
}
