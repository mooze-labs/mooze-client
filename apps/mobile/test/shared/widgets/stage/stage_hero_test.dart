import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_hero.dart';

const _mark = ValueKey('mark');

/// A token whose mark takes a quarter of its width, at its top left.
class _Token extends StatelessWidget {
  const _Token();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topLeft,
    child: FractionallySizedBox(
      widthFactor: 0.25,
      heightFactor: 0.25,
      child: SizedBox(key: _mark),
    ),
  );
}

/// The same token, but its mark has a fixed size, as the glyph of a coin
/// face has: a flight that lays it out at another size breaks its
/// proportions.
class _FixedToken extends StatelessWidget {
  const _FixedToken();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topLeft,
    child: SizedBox(key: _mark, width: 50, height: 50),
  );
}

void main() {
  Future<void> fly(WidgetTester tester, Widget token) async {
    final navigator = GlobalKey<NavigatorState>();
    Widget page(double size) => Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: size,
          child: StageHero(tag: StageHero.moozeCoin, child: token),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: page(100)),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page(200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  /// The rect of the token in the air: the overlay places it.
  Rect flight(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.byKey(_mark), matching: find.byType(Positioned))
        .first,
  );

  testWidgets('the token flies as one, between its two places', (tester) async {
    await fly(tester, const _Token());
    expect(find.byKey(_mark), findsOneWidget);
    expect(flight(tester).width, inExclusiveRange(100, 200));
  });

  testWidgets('in the air, the token keeps the proportions of where it '
      'lands, even when its parts have fixed sizes', (tester) async {
    await fly(tester, const _FixedToken());
    expect(flight(tester).width, inExclusiveRange(100, 200));
    final token = tester.getRect(find.byType(_FixedToken));
    final mark = tester.getRect(find.byKey(_mark));
    // Not squashed, though the rect of the flight need not be square.
    expect(token.width, moreOrLessEquals(token.height, epsilon: 0.5));
    // At its landing place, 200 wide, the mark takes a quarter.
    expect(mark.width / token.width, moreOrLessEquals(0.25, epsilon: 1e-6));
  });
}
