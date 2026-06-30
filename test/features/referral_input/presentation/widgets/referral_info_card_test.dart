import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_info_card.dart';

void main() {
  Widget buildWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReferralInfoCard(),
        ),
      ),
    );
  }

  group('ReferralInfoCard', () {
    testWidgets('should display title text', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Economize com indicações!'), findsOneWidget);
    });

    testWidgets('should display discount badge', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('ATÉ 15% DE DESCONTO'), findsOneWidget);
    });

    testWidgets('should display description text', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(
        find.text(
          'Digite seu código de indicação e aproveite descontos exclusivos em todas as taxas da plataforma.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display gift icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    });
  });
}
