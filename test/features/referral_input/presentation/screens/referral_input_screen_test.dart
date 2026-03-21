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

  Widget buildScreen({
    bool isApiDown = false,
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
      child: const MaterialApp(
        home: ReferralInputScreen(),
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

      testWidgets('should display back button', (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.arrow_back_ios_new_rounded),
          findsOneWidget,
        );
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
