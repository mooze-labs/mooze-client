import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/home_action_row.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import '../../../../shared/test_app.dart';
import '../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Size of the test screen: a phone with a home indicator.
const _screen = Size(390, 844);

/// Bottom inset of the home indicator.
const _homeIndicator = 34.0;

/// A screen with one button that runs [open].
Widget _launcher(void Function(BuildContext context) open) => wrapForTest(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// Sets the test screen to [_screen] with the home indicator inset.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = _screen * 3;
  tester.view.padding = const FakeViewPadding(bottom: _homeIndicator * 3);
  addTearDown(tester.view.reset);
}

/// Bounds of the glass of the open sheet.
Rect _glassRect(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.byType(GlassSheet),
    matching: find.byType(LiquidGlass),
  ),
);

/// Checks that the glass keeps clear of the sides and the bottom edge.
void _expectFloating(WidgetTester tester) {
  final rect = _glassRect(tester);
  expect(rect.left, GlassSheet.sideMargin);
  expect(rect.right, _screen.width - GlassSheet.sideMargin);
  expect(_screen.height - rect.bottom, _homeIndicator - 8);
}

void _openInfo(
  BuildContext context, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showGlassInfoSheet(
    context,
    title: 'Como receber',
    steps: const [
      ('Selecione o ativo', 'Escolha o ativo.'),
      ('Escolha a rede', 'Escolha a rede.'),
      ('Gere o QR code', 'Compartilhe o código.'),
    ],
    hint: 'Toque fora para fechar',
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void main() {
  group('Info sheet', () {
    testWidgets('floats with the title, numbered steps, and hint', (
      tester,
    ) async {
      _usePhoneScreen(tester);
      await tester.pumpWidget(_launcher(_openInfo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      _expectFloating(tester);
      expect(find.text('Como receber'), findsOneWidget);
      for (final number in ['1', '2', '3']) {
        expect(find.text(number), findsOneWidget);
      }
      expect(find.text('Gere o QR code'), findsOneWidget);
      expect(find.text('Toque fora para fechar'), findsOneWidget);
      // Without an action, the sheet shows no button.
      expect(find.byType(PrimaryButton), findsNothing);
    });

    testWidgets('the title grows with the text size up to 150%', (
      tester,
    ) async {
      _usePhoneScreen(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_launcher(_openInfo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Como receber'));
      expect(title.textScaler!.scale(10), 15);
    });

    testWidgets('the close button closes the sheet', (tester) async {
      _usePhoneScreen(tester);
      await tester.pumpWidget(_launcher(_openInfo));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.byType(GlassSheet), findsNothing);
    });

    testWidgets('the action closes the sheet and runs', (tester) async {
      _usePhoneScreen(tester);
      var runs = 0;
      await tester.pumpWidget(
        _launcher(
          (context) =>
              _openInfo(context, actionLabel: 'Ir', onAction: () => runs++),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();

      expect(runs, 1);
      expect(find.byType(GlassSheet), findsNothing);
    });

    testWidgets('the sheet slides in over the open duration', (tester) async {
      _usePhoneScreen(tester);
      await tester.pumpWidget(_launcher(_openInfo));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final moving = _glassRect(tester);
      await tester.pumpAndSettle();

      expect(moving.top, greaterThan(_glassRect(tester).top));
    });

    testWidgets('with reduced motion, the sheet opens and closes at once', (
      tester,
    ) async {
      _usePhoneScreen(tester);
      reduceMotion(tester);
      await tester.pumpWidget(_launcher(_openInfo));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();

      _expectFloating(tester);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(GlassSheet), findsNothing);
    });
  });

  group('More sheet', () {
    testWidgets('floats with the title and the entries', (tester) async {
      _usePhoneScreen(tester);
      await tester.pumpWidget(
        _launcher(
          (context) => showHomeMoreSheet(
            context,
            actions: [
              HomeMoreAction(
                label: 'Histórico',
                icon: Icons.receipt_long_outlined,
                onSelected: () {},
              ),
              HomeMoreAction(
                label: 'Ativos',
                svgAsset: 'assets/icons/menu/navigation/asset.svg',
                onSelected: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      _expectFloating(tester);
      expect(find.text('Mais ações'), findsOneWidget);
      expect(find.bySemanticsLabel('Histórico'), findsOneWidget);
      expect(find.bySemanticsLabel('Ativos'), findsOneWidget);
    });

    testWidgets('an entry closes the sheet and runs its action', (
      tester,
    ) async {
      _usePhoneScreen(tester);
      var selected = 0;
      await tester.pumpWidget(
        _launcher(
          (context) => showHomeMoreSheet(
            context,
            actions: [
              HomeMoreAction(
                label: 'Histórico',
                icon: Icons.receipt_long_outlined,
                onSelected: () => selected++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle();

      expect(selected, 1);
      expect(find.byType(GlassSheet), findsNothing);
    });
  });
}
