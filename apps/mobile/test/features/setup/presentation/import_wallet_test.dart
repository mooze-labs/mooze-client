import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/import_wallet/import_wallet_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/import_wallet/providers/seed_phrase_provider.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import 'setup_test_app.dart';

/// A valid BIP39 phrase: its checksum passes.
const _validPhrase =
    'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';

void main() {
  late GoRouter router;

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    usePhoneSize(tester);
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('first access')),
        ),
        GoRoute(
          path: '/setup/import-wallet',
          builder: (_, _) => const ImportWalletScreen(),
        ),
      ],
    );
    await tester.pumpWidget(setupTestApp(router: router, textScale: textScale));
    router.push('/setup/import-wallet');
    await settle(tester);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  bool importEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled;

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await settle(tester);
  }

  testWidgets('a valid phrase lists the words and turns on import', (
    tester,
  ) async {
    await open(tester);
    expect(importEnabled(tester), isFalse);

    await type(tester, _validPhrase);

    expect(container(tester).read(seedPhraseProvider).wordCount, 12);
    expect(find.text('Frase válida! Pronta para importar.'), findsOne);
    expect(importEnabled(tester), isTrue);
  });

  testWidgets('back clears the phrase and leaves', (tester) async {
    await open(tester);
    await type(tester, _validPhrase);

    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('first access'), findsOneWidget);
    expect(container(tester).read(seedPhraseProvider).wordCount, 0);
  });

  testWidgets('sits on the screen backdrop, with the guide on glass', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(AppBackdrop), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.text('Digite sua frase de recuperação'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits a phone at 200% text, with a full phrase', (tester) async {
    await open(tester, textScale: 2);
    await type(tester, _validPhrase);

    expect(tester.takeException(), isNull);
  });
}
