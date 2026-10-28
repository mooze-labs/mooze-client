import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/section_settings.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import '../../../../shared/test_app.dart';

/// Counts the runs of the action.
class _CountAction extends SettingsActions {
  int runs = 0;

  @override
  void execute() => runs++;
}

Widget _section(List<ConfigStructure> items) => wrapForTest(
  Scaffold(
    body: SectionSettings(title: 'Segurança', settingsItems: items),
  ),
);

/// Gradient of the row with [title], or null when the row has none.
LinearGradient? _gradientOf(WidgetTester tester, String title) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.widgetWithText(LabelSettings, title),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).gradient as LinearGradient?;
}

void main() {
  testWidgets('groups the rows in one glass panel without a backdrop blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      _section([
        ConfigStructure(title: 'Biometria'),
        ConfigStructure(title: 'Alterar PIN'),
        ConfigStructure(title: 'Idioma'),
      ]),
    );

    expect(find.byType(GlassPanel), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(LabelSettings),
      ),
      findsNWidgets(3),
    );
    expect(find.byType(LabelDivider), findsNWidgets(2));
    expect(find.byType(AppPanel), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('a tap on a row runs its action', (tester) async {
    final action = _CountAction();
    await tester.pumpWidget(
      _section([ConfigStructure(title: 'Biometria', action: action)]),
    );

    await tester.tap(find.text('Biometria'));
    expect(action.runs, 1);
  });

  testWidgets('the highlighted row fades out into the glass', (tester) async {
    await tester.pumpWidget(
      _section([
        ConfigStructure(title: 'Modo comerciante', highlight: true),
        ConfigStructure(title: 'Pagadores favoritos'),
      ]),
    );

    final primary = Theme.of(
      tester.element(find.byType(SectionSettings)),
    ).colorScheme.primary;
    final gradient = _gradientOf(tester, 'Modo comerciante')!;
    expect(gradient.colors.first, primary);
    expect(gradient.colors.last, primary.withValues(alpha: 0));
    expect(_gradientOf(tester, 'Pagadores favoritos'), isNull);
  });
}
