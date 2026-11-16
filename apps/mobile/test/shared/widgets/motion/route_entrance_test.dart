import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/widgets/motion/route_entrance.dart';

/// Calls [afterRouteEntrance] once, and records when its action runs.
class _Entered extends StatefulWidget {
  const _Entered(this.onEntered);

  final VoidCallback onEntered;

  @override
  State<_Entered> createState() => _EnteredState();
}

class _EnteredState extends State<_Entered> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    afterRouteEntrance(context, widget.onEntered);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('without a route, the action runs at once', (tester) async {
    var entered = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Entered(() => entered = true),
      ),
    );
    expect(entered, isTrue);
  });

  testWidgets('on the first route, which has no entrance, the action runs at '
      'once', (tester) async {
    var entered = false;
    await tester.pumpWidget(MaterialApp(home: _Entered(() => entered = true)));
    expect(entered, isTrue);
  });

  testWidgets('on a pushed route, the action waits for the page transition, '
      'though the page first lays out offstage at its end', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    late final MaterialPageRoute<void> route;
    double? enteredAt;
    route = MaterialPageRoute<void>(
      builder: (_) => _Entered(() => enteredAt = route.animation!.value),
    );
    navigator.currentState!.push(route);

    await tester.pump();
    // The HeroController of the app puts the new page offstage for this
    // frame, and its animation then reads as complete.
    expect(enteredAt, isNull);
    await tester.pump(route.transitionDuration ~/ 2);
    expect(enteredAt, isNull);

    await tester.pumpAndSettle();
    expect(enteredAt, 1);
  });

  testWidgets('a page that leaves before it has come in runs nothing', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    var entered = false;
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _Entered(() => entered = true)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    navigator.currentState!.pop();

    await tester.pumpAndSettle();
    expect(entered, isFalse);
  });
}
