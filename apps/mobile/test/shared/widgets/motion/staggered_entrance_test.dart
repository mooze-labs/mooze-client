import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../test_app.dart';
import 'motion_test_helpers.dart';

Widget _entrance({VoidCallback? onTap}) => wrapForTest(
  Scaffold(
    body: StaggeredEntrance(
      sessionKey: 'test',
      sections: [
        const Text('header'),
        const Text('balance'),
        const Text('actions'),
        const Text('assets'),
        ElevatedButton(onPressed: onTap, child: const Text('transactions')),
      ],
    ),
  ),
);

/// Opacity of the entrance fade around [text].
double _opacity(WidgetTester tester, String text) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.text(text),
          matching: find.descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(FadeTransition),
          ),
        )
        .first,
  );
  return fade.opacity.value;
}

void main() {
  setUp(StaggeredEntrance.resetSession);

  testWidgets('the first mount staggers the sections inside the budget', (
    tester,
  ) async {
    await tester.pumpWidget(_entrance());

    expect(_opacity(tester, 'header'), 0);
    expect(_opacity(tester, 'transactions'), 0);

    // The last section starts 4 stagger steps after the first one.
    await tester.pump(Motion.staggerStep * 4);
    expect(_opacity(tester, 'header'), greaterThan(0));
    expect(_opacity(tester, 'transactions'), 0);

    await tester.pump(Motion.entranceBudget - Motion.staggerStep * 4);
    for (final section in [
      'header',
      'balance',
      'actions',
      'assets',
      'transactions',
    ]) {
      expect(_opacity(tester, section), 1, reason: section);
    }
  });

  testWidgets('a second mount in the same session shows the sections at '
      'once', (tester) async {
    await tester.pumpWidget(_entrance());
    await tester.pumpAndSettle();
    expect(StaggeredEntrance.hasPlayed('test'), isTrue);

    // A tab return disposes the home screen and builds it again.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_entrance());

    expect(_opacity(tester, 'header'), 1);
    expect(_opacity(tester, 'transactions'), 1);
  });

  testWidgets('reduced motion shows the sections at once', (tester) async {
    reduceMotion(tester);
    await tester.pumpWidget(_entrance());

    expect(_opacity(tester, 'header'), 1);
    expect(_opacity(tester, 'transactions'), 1);
  });

  testWidgets('taps work during the entrance', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_entrance(onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('transactions'));
    expect(taps, 1);

    await tester.pumpAndSettle();
  });
}
