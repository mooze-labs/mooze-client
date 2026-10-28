import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/pix_hub_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_operation_list.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_primary_action_cards.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_onboarding_service.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../shared/widgets/motion/motion_test_helpers.dart';

/// Skips the first-access dialogs, which have their own tests.
class _SeenOnboarding implements PixOnboardingService {
  @override
  Future<bool> hasSeenFirstTimeDialog() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pending records that a test can change after the first frame.
final _pending = StateProvider<List<PixWithdrawalRecord>>((ref) => const []);

final _record = PixWithdrawalRecord(
  id: 'w-1',
  createdAt: DateTime.utc(2026, 10, 24, 12),
  payoutAmountInCents: 4590,
  depositAmountInCents: 4689,
  depositAmountSats: 4689000000,
  depositAddress: 'lq1qqdeposit',
  expiresAt: DateTime.utc(2026, 10, 24, 12, 30),
  maskedKey: 'a***@exemplo.com.br',
  fundingStatus: PixFundingStatus.uncertain,
);

/// Renders [child] with the app theme of [brightness] and the app
/// translations.
Widget _app(Widget child, {Brightness brightness = Brightness.dark}) {
  return ProviderScope(
    overrides: [
      pixOnboardingServiceProvider.overrideWithValue(_SeenOnboarding()),
      pixPendingWithdrawalsProvider.overrideWith((ref) => ref.watch(_pending)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: Builder(
        builder: (context) => Theme(
          data: brightness == Brightness.dark
              ? AppTheme.darkTheme(context)
              : AppTheme.lightTheme(context),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

/// Opacity of the entrance fade around [finder].
double _entranceOpacity(WidgetTester tester, Finder finder) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(
          of: finder,
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

  group('Pix hub entrance', () {
    testWidgets('the first show fades the blocks in, in order', (tester) async {
      await tester.pumpWidget(_app(const PixHubScreen()));

      final title = find.text('Área Pix');
      final card = find.byType(PixHighlightActionCard);
      expect(_entranceOpacity(tester, title), 0);

      await tester.pump(Motion.staggerStep);
      expect(_entranceOpacity(tester, title), greaterThan(0));
      expect(_entranceOpacity(tester, card), 0);

      await tester.pump(Motion.entranceBudget);
      expect(_entranceOpacity(tester, title), 1);
      expect(_entranceOpacity(tester, card), 1);
    });

    testWidgets('a tab return shows the blocks at once', (tester) async {
      await tester.pumpWidget(_app(const PixHubScreen()));
      await tester.pump(Motion.entranceBudget);

      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpWidget(_app(const PixHubScreen()));

      expect(_entranceOpacity(tester, find.text('Área Pix')), 1);
    });

    testWidgets('reduced motion shows the blocks at once', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(_app(const PixHubScreen()));

      expect(_entranceOpacity(tester, find.text('Área Pix')), 1);
      expect(_entranceOpacity(tester, find.byType(PixHighlightActionCard)), 1);
    });
  });

  group('Pending Pix sends', () {
    Future<void> showHub(WidgetTester tester) async {
      await tester.pumpWidget(_app(const PixHubScreen()));
      await tester.pump(Motion.entranceBudget);
    }

    void addRecord(WidgetTester tester) {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PixHubScreen)),
      );
      container.read(_pending.notifier).state = [_record];
    }

    testWidgets('a new pending send grows and fades in', (tester) async {
      await showHub(tester);
      addRecord(tester);
      await tester.pump();
      await tester.pump(Motion.durationEmphasis ~/ 2);

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Pix em andamento'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(find.text('Pix em andamento'), findsOneWidget);
    });

    testWidgets('reduced motion shows a new pending send at once', (
      tester,
    ) async {
      reduceMotion(tester);
      await showHub(tester);
      addRecord(tester);
      await tester.pump();

      expect(find.text('Pix em andamento'), findsOneWidget);
      expect(find.byType(AnimatedSize), findsNothing);
    });
  });

  testWidgets('the hub fits a 320 pt screen at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app(const PixHubScreen()));
    await tester.pump(Motion.entranceBudget);
    expect(tester.takeException(), isNull);
  });

  group('Pix hub surfaces', () {
    testWidgets('the receive card scales while pressed', (tester) async {
      await tester.pumpWidget(
        _app(
          PixHighlightActionCard(
            icon: PixIcons.qrCode,
            label: 'Receber',
            description: 'Compartilhe sua chave',
            onTap: () {},
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PixHighlightActionCard)),
      );
      await tester.pump(Motion.durationPress);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        Motion.pressScale,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the receive card text sits on the darker brand color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          PixHighlightActionCard(
            icon: PixIcons.qrCode,
            label: 'Receber',
            description: 'Compartilhe sua chave',
            onTap: () {},
          ),
        ),
      );

      final ink = tester.widget<Ink>(find.byType(Ink));
      final gradient =
          (ink.decoration! as BoxDecoration).gradient! as LinearGradient;
      // The text starts on the left, where the gradient starts.
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.colors.first, AppExtraColors.dark.navBarFabBackground);
    });

    testWidgets('the header background changes with the motion token', (
      tester,
    ) async {
      await tester.pumpWidget(_app(PixHubHeader(onScan: () {}, onInfo: () {})));
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Motion.durationFast,
      );
    });

    testWidgets('reduced motion changes the header background at once', (
      tester,
    ) async {
      reduceMotion(tester);
      await tester.pumpWidget(_app(PixHubHeader(onScan: () {}, onInfo: () {})));
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
    });

    testWidgets('the operation divider shows on the light glass panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          PixOperationList(
            items: [
              PixOperationItem(
                icon: PixIcons.key,
                label: 'Pagar com chave Pix',
                onTap: () {},
              ),
              PixOperationItem(
                icon: PixIcons.link,
                label: 'Links de pagamento',
                onTap: () {},
              ),
            ],
          ),
          brightness: Brightness.light,
        ),
      );

      // The rows sit on a glass panel, so the divider uses the panel
      // hairline. It differs from the glass tone, so it shows.
      expect(
        find.descendant(
          of: find.byType(PixOperationList),
          matching: find.byType(GlassPanel),
        ),
        findsOneWidget,
      );
      final context = tester.element(find.byType(Divider));
      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.color, AppSurfaces.hairline(context));
      expect(divider.color, isNot(GlassPanel.maybeToneOf(context)));
    });
  });
}
