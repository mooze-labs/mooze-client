import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/referral_input/presentation/widgets/referral_code_input.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildWidget({
    bool isEnabled = true,
    bool isApiDown = false,
    VoidCallback? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ReferralCodeInput(
            controller: controller,
            isEnabled: isEnabled,
            isApiDown: isApiDown,
            onChanged: onChanged ?? () {},
          ),
        ),
      ),
    );
  }

  group('ReferralCodeInput', () {
    testWidgets('should display floating label', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Código de Indicação'), findsOneWidget);
    });

    testWidgets('should display hint text when enabled', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Ex: MOOZE123'), findsOneWidget);
    });

    testWidgets('should display unavailable hint when API is down',
        (tester) async {
      await tester.pumpWidget(buildWidget(isApiDown: true));

      expect(find.text('Indisponível'), findsOneWidget);
      expect(find.text('Ex: MOOZE123'), findsNothing);
    });

    testWidgets('should call onChanged when text changes', (tester) async {
      var changeCount = 0;
      await tester.pumpWidget(
        buildWidget(onChanged: () => changeCount++),
      );

      await tester.enterText(find.byType(TextField), 'ABC');
      await tester.pump();

      expect(changeCount, 1); // enterText replaces text in one shot
    });

    testWidgets('should not allow input when disabled', (tester) async {
      await tester.pumpWidget(buildWidget(isEnabled: false));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('should be disabled when API is down and isEnabled is false',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(isEnabled: false, isApiDown: true),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('should accept text input when enabled', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField), 'mooze');
      await tester.pump();

      // UpperCaseTextFormatter converts to uppercase
      expect(controller.text, 'MOOZE');
    });
  });
}
