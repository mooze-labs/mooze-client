import 'dart:ui' show Tristate;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/domain/repositories/mnemonic_repository.dart';
import 'package:mooze_mobile/features/setup/presentation/controller/mnemonic_controller.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/mnemonic_controller_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/configure_seeds.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/providers/extended_phrase_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'setup_test_app.dart';

/// Makes a phrase of the asked length out of numbered words.
class _FakeMnemonics implements MnemonicRepository {
  @override
  String generateMnemonic(bool extendedPhrase) =>
      List.generate(extendedPhrase ? 24 : 12, (i) => 'w$i').join(' ');

  @override
  TaskEither<String, Unit> saveMnemonic(String mnemonic) =>
      TaskEither.right(unit);

  @override
  bool validateMnemonic(String mnemonic) => true;
}

void main() {
  late OpenedRoutes opened;

  setUp(() => opened = OpenedRoutes());

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/setup/create-wallet/configure-seeds',
      routes: [
        GoRoute(
          path: '/setup/create-wallet/configure-seeds',
          builder: (_, _) => const ConfigureSeedsScreen(),
        ),
        opened.stub('/setup/create-wallet/display-seeds'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        textScale: textScale,
        overrides: [
          mnemonicControllerProvider.overrideWithValue(
            MnemonicController(repository: _FakeMnemonics()),
          ),
        ],
      ),
    );
    await settle(tester);
  }

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ConfigureSeedsScreen)),
  );

  bool announcedSelected(WidgetTester tester, String title) =>
      tester
          .getSemantics(find.text(title))
          .getSemanticsData()
          .flagsCollection
          .isSelected ==
      Tristate.isTrue;

  testWidgets('the chosen length is announced as selected', (tester) async {
    await open(tester);
    expect(announcedSelected(tester, '12 Palavras'), isTrue);
    expect(announcedSelected(tester, '24 Palavras (recomendado)'), isFalse);

    await tester.tap(find.text('24 Palavras (recomendado)'));
    await settle(tester);

    expect(container(tester).read(extendedPhraseProvider), isTrue);
    expect(announcedSelected(tester, '24 Palavras (recomendado)'), isTrue);
    expect(announcedSelected(tester, '12 Palavras'), isFalse);
  });

  testWidgets('generate opens a phrase of the chosen length', (tester) async {
    await open(tester);
    await tester.tap(find.text('24 Palavras (recomendado)'));
    await settle(tester);

    await tester.tap(find.text('Gerar frase de recuperação'));
    await settle(tester);

    expect(opened.last, '/setup/create-wallet/display-seeds');
    expect((opened.extras.last! as String).split(' '), hasLength(24));
  });

  testWidgets('sits on the screen backdrop, with the lengths on glass', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(AppBackdrop), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.text('12 Palavras'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits a phone at 200% text', (tester) async {
    await open(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
