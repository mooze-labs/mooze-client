import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/routes.dart';

void main() {
  testWidgets(
    'the tabs fade in over the PIN screen, without sliding in from the side',
    (tester) async {
      final router = _router('/pin');
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final tabs = find.byKey(_tabsKey);
      final opacity = _opacityOf(tester, tabs);
      expect(opacity, greaterThan(0.05));
      expect(opacity, lessThan(0.95));
      // In place, but for the slight growth of the fade.
      expect(tester.getTopLeft(tabs).dx.abs(), lessThan(10));
      // The PIN screen still shows under them.
      expect(find.text('pin'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(_opacityOf(tester, tabs), 1);
      expect(tester.getTopLeft(tabs), Offset.zero);
      expect(find.text('pin'), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets('a change of tab does not play the fade again', (tester) async {
    final router = _router('/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/asset');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('asset'), findsOneWidget);
    expect(_opacityOf(tester, find.byKey(_tabsKey)), 1);
    expect(tester.getTopLeft(find.byKey(_tabsKey)), Offset.zero);
  });

  testWidgets(
    'a page opened over the tabs slides in, and the tabs move aside under it',
    (tester) async {
      final router = _router('/home');
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/detail');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.getTopLeft(find.text('detail')).dx, greaterThan(10));
      expect(tester.getTopLeft(find.byKey(_tabsKey)).dx, lessThan(-10));

      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

final _tabsKey = GlobalKey(debugLabel: 'tabs');

/// The tabs as the app opens them, with their real page and transition,
/// around light stand-ins for the screens.
GoRouter _router(String initialLocation) {
  final tabs = walletRoutes.whereType<ShellRoute>().single;
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/pin', builder: (_, _) => const _Screen('pin')),
      GoRoute(path: '/detail', builder: (_, _) => const _Screen('detail')),
      ShellRoute(
        pageBuilder: (context, state, child) {
          final page =
              tabs.pageBuilder!(context, state, child)
                  as CustomTransitionPage<Object?>;
          return CustomTransitionPage<Object?>(
            key: page.key,
            transitionDuration: page.transitionDuration,
            reverseTransitionDuration: page.reverseTransitionDuration,
            transitionsBuilder: page.transitionsBuilder,
            child: KeyedSubtree(key: _tabsKey, child: child),
          );
        },
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const _Screen('home')),
          GoRoute(path: '/asset', builder: (_, _) => const _Screen('asset')),
        ],
      ),
    ],
  );
}

/// The opacity [finder] paints with, through every fade above it.
double _opacityOf(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  RenderObject? node = tester.renderObject(finder);
  while (node != null) {
    if (node is RenderAnimatedOpacity) opacity *= node.opacity.value;
    if (node is RenderOpacity) opacity *= node.opacity;
    node = node.parent;
  }
  return opacity;
}

class _Screen extends StatelessWidget {
  const _Screen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}
