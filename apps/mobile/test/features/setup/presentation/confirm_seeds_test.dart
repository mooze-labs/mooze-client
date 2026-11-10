import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/confirm_seeds.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/selected_words_row.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/word_grid_selector.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'setup_test_app.dart';

/// Twelve different words, so each word has one position.
const _words = [
  'abacate',
  'banana',
  'caju',
  'damasco',
  'figo',
  'goiaba',
  'jaca',
  'kiwi',
  'limão',
  'manga',
  'nêspera',
  'pera',
];

void main() {
  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/setup/create-wallet/confirm-seeds',
      initialExtra: _words.join(' '),
      routes: [
        GoRoute(
          path: '/setup/create-wallet/confirm-seeds',
          builder: (_, _) => const ConfirmMnemonicScreen(),
        ),
      ],
    );
    await tester.pumpWidget(setupTestApp(router: router, textScale: textScale));
    await settle(tester);
  }

  /// The positions that the screen asks for, from 1.
  List<int> asked(WidgetTester tester) =>
      tester.widget<SelectedWordsRow>(find.byType(SelectedWordsRow)).positions;

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled;

  Future<void> choose(WidgetTester tester, String word) async {
    await tester.tap(
      find.descendant(
        of: find.byType(WordSelectionGrid),
        matching: find.text(word),
      ),
    );
    await settle(tester);
  }

  testWidgets('confirm waits for the three words', (tester) async {
    await open(tester);
    final positions = asked(tester);
    expect(confirmEnabled(tester), isFalse);

    await choose(tester, _words[positions[0] - 1]);
    await choose(tester, _words[positions[1] - 1]);
    expect(confirmEnabled(tester), isFalse);
    await choose(tester, _words[positions[2] - 1]);

    expect(confirmEnabled(tester), isTrue);
  });

  testWidgets('a second tap frees the slot of a word', (tester) async {
    await open(tester);
    final word = _words[asked(tester)[0] - 1];

    await choose(tester, word);
    expect(
      find.descendant(
        of: find.byType(SelectedWordsRow),
        matching: find.text(word),
      ),
      findsOneWidget,
    );

    await choose(tester, word);
    expect(
      find.descendant(
        of: find.byType(SelectedWordsRow),
        matching: find.text(word),
      ),
      findsNothing,
    );
  });

  testWidgets('words in the wrong order show the error', (tester) async {
    await open(tester);
    final positions = asked(tester);
    for (final position in positions.reversed) {
      await choose(tester, _words[position - 1]);
    }

    await tester.tap(find.text('Confirmar'));
    await settle(tester);

    expect(
      find.text('Uma ou mais palavras estão incorretas. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('sits on the screen backdrop, with the words on glass', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(AppBackdrop), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(WordSelectionGrid),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits a phone at 200% text', (tester) async {
    await open(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
