import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

const _orange = Color(0xFFFF9500);
const _gray = Color(0xFF8E8E93);

/// A payment link that waits for its payment.
TxStatusPanel _pending({List<String> details = const ['11 de nov.']}) =>
    TxStatusPanel(
      icon: Icons.schedule_rounded,
      title: 'Pendente',
      color: _orange,
      details: details,
      steps: const [
        TxStep('Criado', TxStepState.done),
        TxStep('Aguardando', TxStepState.active),
        TxStep('Pago', TxStepState.upcoming),
      ],
    );

/// The same link, revoked.
TxStatusPanel _revoked() => const TxStatusPanel(
  icon: Icons.link_off_rounded,
  title: 'Desativado',
  color: _gray,
  details: ['11 de nov.'],
  steps: [
    TxStep('Criado', TxStepState.done),
    TxStep('Desativado', TxStepState.failed),
    TxStep('Pago', TxStepState.upcoming),
  ],
);

void main() {
  Future<void> show(
    WidgetTester tester,
    TxStatusPanel panel, {
    bool reduced = false,
  }) {
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
          // At its own height, in a scroll, as on a detail screen.
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: panel,
          ),
        ),
      ),
    );
  }

  /// Color of the solid disc of the header.
  Color discColor(WidgetTester tester) {
    final disc = tester.widget<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints ==
                const BoxConstraints.tightFor(width: 30, height: 30),
      ),
    );
    return (disc.decoration! as BoxDecoration).color!;
  }

  final half = Motion.durationSlow ~/ 2;

  // A revoke, a payment, or a refund changes the status while the screen
  // is open. The card shows the change, not a jump.
  testWidgets('a new status crossfades over the old one', (tester) async {
    await show(tester, _pending());
    await show(tester, _revoked());
    await tester.pump(half);

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Desativado'), findsWidgets);

    await tester.pump(Motion.durationSlow);
    expect(find.text('Pendente'), findsNothing);
  });

  testWidgets('the color of the card moves from the old status to the new', (
    tester,
  ) async {
    await show(tester, _pending());
    expect(discColor(tester), _orange);

    await show(tester, _revoked());
    await tester.pump(half);
    final middle = discColor(tester);
    expect(middle, isNot(_orange));
    expect(middle, isNot(_gray));

    await tester.pump(Motion.durationSlow);
    expect(discColor(tester), _gray);
  });

  testWidgets('a step that changes animates its node and its name', (
    tester,
  ) async {
    await show(tester, _pending());
    await show(tester, _revoked());
    await tester.pump(half);

    // The waiting step leaves as the revoked step arrives: halfway, the
    // old name still shows, and the new node is still fading in.
    expect(find.text('Aguardando'), findsOneWidget);
    final arriving = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byIcon(Icons.close_rounded),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(arriving.opacity.value, inExclusiveRange(0, 1));

    await tester.pump(Motion.durationSlow);
    expect(find.text('Aguardando'), findsNothing);
  });

  testWidgets('the card grows smoothly when a line is added', (tester) async {
    await show(tester, _pending());
    final before = tester.getSize(find.byType(TxStatusPanel)).height;

    await show(tester, _pending(details: const ['11 de nov.', 'Expirou']));
    await tester.pump(half);
    final middle = tester.getSize(find.byType(TxStatusPanel)).height;

    await tester.pump(Motion.durationSlow);
    final after = tester.getSize(find.byType(TxStatusPanel)).height;
    expect(after, greaterThan(before));
    expect(middle, greaterThan(before));
    expect(middle, lessThan(after));
  });

  testWidgets('a new status does not move on the first show', (tester) async {
    await show(tester, _revoked());
    await tester.pump();

    expect(discColor(tester), _gray);
    expect(find.text('Desativado'), findsWidgets);
  });

  testWidgets('with reduced motion, the new status shows at once', (
    tester,
  ) async {
    await show(tester, _pending(), reduced: true);
    await show(tester, _revoked(), reduced: true);
    await tester.pump();

    expect(find.text('Pendente'), findsNothing);
    expect(find.text('Aguardando'), findsNothing);
    expect(discColor(tester), _gray);
  });
}
