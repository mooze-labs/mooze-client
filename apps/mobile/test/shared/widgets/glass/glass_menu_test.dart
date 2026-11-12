import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_menu.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

void main() {
  /// What the items did, in order.
  late List<String> done;

  setUp(() => done = []);

  /// An app bar with the "more" button of a screen, as on the details of a
  /// payment link.
  Future<void> show(WidgetTester tester, {bool reduced = false}) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Theme(
          data: AppTheme.darkTheme(context),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              GlassMenuButton(
                tooltip: 'Mais ações',
                items: [
                  GlassMenuItem(
                    icon: Icons.edit_outlined,
                    label: 'Editar',
                    // Records whether the menu still showed when the
                    // action ran.
                    onSelected: () => done.add(
                      find.text('Desativar').evaluate().isEmpty
                          ? 'edit after close'
                          : 'edit while open',
                    ),
                  ),
                  GlassMenuItem(
                    icon: Icons.link_off_rounded,
                    label: 'Desativar',
                    destructive: true,
                    onSelected: () => done.add('revoke'),
                  ),
                ],
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
  }

  Finder button() => find.byTooltip('Mais ações');

  Future<void> open(WidgetTester tester) async {
    await tester.tap(button());
    await tester.pumpAndSettle();
  }

  // The menu is a floating glass panel, as the sheets and dialogs of the
  // app, not the flat Material menu.
  testWidgets('opens as a glass panel under its button', (tester) async {
    await show(tester);
    await open(tester);

    final panel = find.ancestor(
      of: find.text('Editar'),
      matching: find.byType(LiquidGlass),
    );
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('Desativar')),
      findsOneWidget,
    );
    expect(find.byType(PopupMenuItem), findsNothing);
    // As the sheets and dialogs: opaque, so the page behind does not show
    // through the text, and no blur to pay for.
    final glassWidget = tester.widget<LiquidGlass>(panel);
    expect(glassWidget.opaque, isTrue);
    expect(glassWidget.blurBackdrop, isFalse);

    final anchor = tester.getRect(button());
    final glass = tester.getRect(panel);
    expect(glass.top, greaterThanOrEqualTo(anchor.bottom));
    // It hangs from the end of the bar, as the button does, and stays on
    // the screen.
    expect(glass.right, lessThanOrEqualTo(390));
    expect(glass.right, greaterThan(anchor.center.dx));
  });

  // The action runs once the menu has closed, so a sheet that it opens
  // does not stack over a closing menu.
  testWidgets('an item closes the menu, then runs', (tester) async {
    await show(tester);
    await open(tester);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(done, ['edit after close']);
  });

  testWidgets('a tap outside closes it and runs nothing', (tester) async {
    await show(tester);
    await open(tester);

    await tester.tapAt(const Offset(40, 600));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsNothing);
    expect(done, isEmpty);
  });

  testWidgets('the system back closes it and runs nothing', (tester) async {
    await show(tester);
    await open(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsNothing);
    expect(done, isEmpty);
  });

  // A destructive action says so with its color, and with its words.
  testWidgets('a destructive item is red, the others are not', (tester) async {
    await show(tester);
    await open(tester);

    final context = tester.element(find.text('Desativar'));
    final red = context.colors.negativeColor;
    expect(tester.widget<Text>(find.text('Desativar')).style?.color, red);
    expect(tester.widget<Icon>(find.byIcon(Icons.link_off_rounded)).color, red);
    expect(tester.widget<Text>(find.text('Editar')).style?.color, isNot(red));
  });

  testWidgets('each item is a button for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester);
    await open(tester);

    expect(
      tester.getSemantics(find.text('Editar')),
      isSemantics(label: 'Editar', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  // The panel grows from its button and fades in.
  testWidgets('opens with a scale and a fade from the button', (tester) async {
    await show(tester);
    await tester.tap(button());
    await tester.pump();
    await tester.pump(Motion.durationEmphasis ~/ 2);

    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byType(LiquidGlass),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, inExclusiveRange(0, 1));
    expect(scale.alignment.x, greaterThan(0));

    await tester.pumpAndSettle();
    expect(scale.scale.value, 1);
  });

  testWidgets('with reduced motion, it shows at once', (tester) async {
    await show(tester, reduced: true);
    await tester.tap(button());
    await tester.pump();
    await tester.pump();

    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(LiquidGlass),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });
}
