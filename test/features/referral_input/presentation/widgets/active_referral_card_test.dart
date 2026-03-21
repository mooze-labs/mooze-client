import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/active_referral_card.dart';

void main() {
  Widget buildWidget({required String referralCode}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActiveReferralCard(referralCode: referralCode),
        ),
      ),
    );
  }

  group('ActiveReferralCard', () {
    testWidgets('should display the referral code', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'MOOZE123'));

      expect(find.text('Código: MOOZE123'), findsOneWidget);
    });

    testWidgets('should display active discount title', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'CODE1'));

      expect(find.text('Desconto Ativo'), findsOneWidget);
    });

    testWidgets('should display savings message', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'CODE1'));

      expect(
        find.text('Você está economizando em todas as transações!'),
        findsOneWidget,
      );
    });

    testWidgets('should display check circle icon', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'CODE1'));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('should display savings icon', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'CODE1'));

      expect(find.byIcon(Icons.savings_rounded), findsOneWidget);
    });

    testWidgets('should display different codes correctly', (tester) async {
      await tester.pumpWidget(buildWidget(referralCode: 'ABCXYZ'));

      expect(find.text('Código: ABCXYZ'), findsOneWidget);
    });
  });
}
