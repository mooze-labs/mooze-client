import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_submit_button.dart';

void main() {
  Widget buildWidget({
    bool isApiDown = false,
    bool isLoading = false,
    VoidCallback? onSubmit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ReferralSubmitButton(
          isApiDown: isApiDown,
          isLoading: isLoading,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  group('ReferralSubmitButton', () {
    group('normal state', () {
      testWidgets('should display submit button text', (tester) async {
        await tester.pumpWidget(buildWidget(onSubmit: () {}));

        expect(find.text('Aplicar Código'), findsOneWidget);
      });

      testWidgets('should call onSubmit when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(buildWidget(onSubmit: () => tapped = true));

        await tester.tap(find.text('Aplicar Código'));
        await tester.pump();

        expect(tapped, true);
      });
    });

    group('loading state', () {
      testWidgets('should display loading text when isLoading', (tester) async {
        await tester.pumpWidget(
          buildWidget(isLoading: true, onSubmit: () {}),
        );

        expect(find.text('Validando...'), findsOneWidget);
        expect(find.text('Aplicar Código'), findsNothing);
      });

      testWidgets('should not call onSubmit when loading', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildWidget(isLoading: true, onSubmit: () => tapped = true),
        );

        await tester.tap(find.text('Validando...'));
        await tester.pump();

        expect(tapped, false);
      });
    });

    group('API down state', () {
      testWidgets('should display warning when API is down', (tester) async {
        await tester.pumpWidget(buildWidget(isApiDown: true));

        expect(
          find.text(
            'A API está indisponível. Não é possível aplicar códigos de indicação no momento.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('should display warning icon when API is down',
          (tester) async {
        await tester.pumpWidget(buildWidget(isApiDown: true));

        expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      });

      testWidgets('should not display submit button when API is down',
          (tester) async {
        await tester.pumpWidget(buildWidget(isApiDown: true));

        expect(find.text('Aplicar Código'), findsNothing);
      });
    });
  });
}
