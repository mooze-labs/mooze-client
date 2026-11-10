import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/view_mnemonic.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/display_seeds.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/seed_display.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'setup_test_app.dart';

const _mnemonic =
    'abacate banana caju damasco figo goiaba jaca kiwi limão manga nêspera '
    'uva';

void main() {
  late OpenedRoutes opened;

  setUp(() => opened = OpenedRoutes());

  Future<void> open(
    WidgetTester tester,
    String path, {
    double textScale = 1,
  }) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(
          path: '/setup/create-wallet/display-seeds',
          builder: (_, _) => const DisplaySeedsScreen(mnemonic: _mnemonic),
        ),
        GoRoute(
          path: '/settings/seed',
          builder: (_, _) => const ViewMnemonicScreen(mnemonic: _mnemonic),
        ),
        opened.stub('/setup/create-wallet/confirm-seeds'),
      ],
    );
    await tester.pumpWidget(setupTestApp(router: router, textScale: textScale));
    await settle(tester);
  }

  for (final (name, path) in [
    ('the new phrase', '/setup/create-wallet/display-seeds'),
    ('the phrase in the settings', '/settings/seed'),
  ]) {
    group(name, () {
      testWidgets('lists the words on glass, on the screen backdrop', (
        tester,
      ) async {
        await open(tester, path);

        expect(find.byType(AppBackdrop), findsWidgets);
        final grid = find.descendant(
          of: find.byType(GlassPanel),
          matching: find.byType(MnemonicGridDisplay),
        );
        expect(grid, findsOneWidget);
        for (final word in _mnemonic.split(' ')) {
          expect(
            find.descendant(
              of: grid,
              matching: find.textContaining(word, findRichText: true),
            ),
            findsOneWidget,
          );
        }
      });

      testWidgets('fits a phone at 200% text', (tester) async {
        await open(tester, path, textScale: 2);

        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the new phrase goes on to its confirmation', (tester) async {
    await open(tester, '/setup/create-wallet/display-seeds');

    await tester.tap(find.text('Confirmar frase'));
    await settle(tester);

    expect(opened.last, '/setup/create-wallet/confirm-seeds');
    expect(opened.extras.last, _mnemonic);
  });

  testWidgets('the settings copy the phrase', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await open(tester, '/settings/seed');

    await tester.tap(find.text('Copiar seed'));
    await settle(tester);
    expect(copied, _mnemonic);

    // The button turns back after its pause.
    await tester.pump(const Duration(seconds: 3));
  });
}
