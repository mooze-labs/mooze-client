import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_payment_link_repository.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_detail_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_links_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/operations/pix_pending_requests_screen.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The API of the engine: a revoke stamps `revoked_at`, and the next list
/// returns the link as revoked.
class _FakeLinks implements PixPaymentLinkRepository {
  final Set<String> revoked = {};
  int lists = 0;

  /// When set, a list read waits for it, like a slow network.
  Completer<void>? slowList;

  /// When set, the revoke answers this failure.
  PixHubFailure? revokeFailure;

  PixPaymentLink _link(String id, int cents) => PixPaymentLink(
    id: id,
    url: 'https://pay.mooze.app/pay/$id',
    reference: '',
    amountInCents: cents,
    asset: Asset.depix,
    status: revoked.contains(id)
        ? PixPaymentLinkStatus.revoked
        : PixPaymentLinkStatus.pending,
    createdAt: DateTime(2026, 11, 6, 10),
    singleUse: true,
  );

  @override
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks() {
    return TaskEither(() async {
      lists++;
      await slowList?.future;
      return Right([_link('a', 1500), _link('b', 2500)]);
    });
  }

  @override
  TaskEither<PixHubFailure, Unit> revokeLink(String id) {
    final failure = revokeFailure;
    if (failure != null) return TaskEither.left(failure);
    revoked.add(id);
    return TaskEither.right(unit);
  }

  @override
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  late _FakeLinks links;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    links = _FakeLinks();
  });

  Future<void> open(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/pix/links',
          builder: (_, _) => const PixPaymentLinksScreen(),
        ),
        GoRoute(
          path: '/pix/links/detail',
          builder: (_, state) =>
              PixPaymentLinkDetailScreen(link: state.extra as PixPaymentLink),
        ),
        GoRoute(
          path: '/pix/pending',
          builder: (_, _) => const PixPendingRequestsScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pixPaymentLinkRepositoryProvider.overrideWithValue(links),
          pixDepositHistoryProvider.overrideWith(
            (ref) async => const Right([]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> openFirstLink(WidgetTester tester) async {
    await open(tester, '/pix/links');
    await tester.tap(find.byType(PixPaymentLinkTile).first);
    await settle(tester);
  }

  group('a revoke in the details', () {
    testWidgets('turns the status there, without leaving', (tester) async {
      await openFirstLink(tester);
      expect(find.text('Pending'), findsOneWidget);

      await revoke(tester);

      expect(find.byType(PixPaymentLinkDetailScreen), findsOneWidget);
      expect(statusTitle(tester), 'Deactivated');
      // A revoked link takes no second revoke: its menu keeps only the
      // name of the link.
      await tester.tap(find.byTooltip('More actions'));
      await settle(tester);
      expect(find.text('Add a reference'), findsOneWidget);
      expect(find.text('Deactivate link'), findsNothing);
    });

    testWidgets('shows before the list read of the API ends', (tester) async {
      await openFirstLink(tester);
      final listsBefore = links.lists;
      links.slowList = Completer<void>();

      await revoke(tester);

      expect(links.lists, listsBefore + 1, reason: 'the list reloads');
      expect(statusTitle(tester), 'Deactivated');

      links.slowList!.complete();
      await settle(tester);
      expect(statusTitle(tester), 'Deactivated');
    });

    testWidgets('reaches the list below it', (tester) async {
      await openFirstLink(tester);
      await revoke(tester);

      await tester.pageBack();
      await settle(tester);

      expect(find.byType(PixPaymentLinksScreen), findsOneWidget);
      expect(find.text('Deactivated'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('that fails keeps the status and reads the API again', (
      tester,
    ) async {
      await openFirstLink(tester);
      final listsBefore = links.lists;
      links.revokeFailure = const PixHubFailure(PixHubErrorCode.network);

      await revoke(tester);

      expect(find.text('Pending'), findsOneWidget);
      // The revoke stays on offer, in the menu.
      expect(find.byTooltip('More actions'), findsOneWidget);
      // A timeout can hide a revoke that went through.
      expect(links.lists, listsBefore + 1);
    });
  });

  testWidgets('the pending list drops a link revoked there', (tester) async {
    await open(tester, '/pix/pending');
    expect(find.byTooltip('Deactivate link'), findsNWidgets(2));
    links.slowList = Completer<void>();

    await tester.tap(find.byTooltip('Deactivate link').first);
    await settle(tester);
    await tester.tap(find.text('Deactivate'));
    await settle(tester);

    expect(find.byTooltip('Deactivate link'), findsOneWidget);
    links.slowList!.complete();
  });
}

/// The status that the details show, in the title of the status panel.
String statusTitle(WidgetTester tester) =>
    tester.widget<TxStatusPanel>(find.byType(TxStatusPanel)).title;

/// Revokes the link of the details: the revoke lives in the menu of the
/// bar, and asks for a confirmation.
Future<void> revoke(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More actions'));
  await settle(tester);
  await tester.tap(find.text('Deactivate link'));
  await settle(tester);
  await tester.tap(find.text('Deactivate'));
  await settle(tester);
}

/// Pumps frames for the routes, the dialog and the reload. The screens have
/// shimmer animations, so `pumpAndSettle` never ends.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
