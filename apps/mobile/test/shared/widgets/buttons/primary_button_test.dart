import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  Widget wrap(Widget child) => Builder(
    builder: (context) => MaterialApp(
      theme: AppTheme.lightTheme(context),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  BoxShadow shadowOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.boxShadow!.single;
  }

  testWidgets('shadow follows the theme primary color', (tester) async {
    await tester.pumpWidget(
      wrap(const PrimaryButton(text: 'Go', onPressed: _noop)),
    );

    final primary = Theme.of(
      tester.element(find.byType(PrimaryButton)),
    ).colorScheme.primary;
    final shadow = shadowOf(tester);

    expect(shadow.color.toARGB32() & 0x00FFFFFF, primary.toARGB32() & 0x00FFFFFF);
    expect(shadow.color.a, lessThan(1.0));
  });

  testWidgets('shadow follows a custom color', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PrimaryButton(
          text: 'Go',
          onPressed: _noop,
          color: Colors.teal,
        ),
      ),
    );

    final shadow = shadowOf(tester);
    expect(
      shadow.color.toARGB32() & 0x00FFFFFF,
      Colors.teal.toARGB32() & 0x00FFFFFF,
    );
  });

  testWidgets('no shadow when disabled', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PrimaryButton(text: 'Go', onPressed: _noop, isEnabled: false),
      ),
    );

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byType(ElevatedButton),
        matching: find.byType(Container),
      ).first,
    );
    expect((container.decoration! as BoxDecoration).boxShadow, isNull);
  });
}

void _noop() {}
