import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/sync_error_indicator.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

void main() {
  late int retries;

  setUp(() => retries = 0);

  /// A button that opens the sheet, then a tap on it.
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncErrorProvider.overrideWith((ref) => true),
          ensureAuthSessionProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showSyncErrorSheet(
                    context,
                    ref,
                    onRetry: () => retries++,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('it is a floating glass sheet, not a dialog', (tester) async {
    await open(tester);

    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(GlassSheet), matching: finder);

    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(inSheet(find.text('Erro de Sincronização')), findsOneWidget);
    expect(
      inSheet(find.text('Não foi possível sincronizar os serviços Mooze.')),
      findsOneWidget,
    );
    expect(inSheet(find.text('Operação não autorizada')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GlassSheet),
        matching: find.byWidgetPredicate(
          (w) => w is PixIcon && w.icon == PixIcons.error,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Retry closes the sheet and retries the sync', (tester) async {
    await open(tester);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
    expect(retries, 1);
  });

  testWidgets('closing the sheet does not retry', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
    expect(retries, 0);
  });

  test('the error shows once the session check ends', () async {
    final check = Completer<bool>();
    final container = ProviderContainer(
      overrides: [
        syncErrorProvider.overrideWith((ref) => true),
        ensureAuthSessionProvider.overrideWith((ref) => check.future),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncErrorVisibleProvider, (_, _) {});

    expect(container.read(syncErrorVisibleProvider), isFalse);

    check.complete(false);
    await container.read(ensureAuthSessionProvider.future);
    expect(container.read(syncErrorVisibleProvider), isTrue);
  });
}
