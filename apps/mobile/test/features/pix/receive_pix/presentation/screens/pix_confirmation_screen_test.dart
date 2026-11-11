import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart' show PixFeeDto;
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/controllers/pix_deposit_controller.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/referral_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/pix_confirmation_screen.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_input_screen.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_qr_scene.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/fake_core_sync_helpers.dart';

/// Creates deposits with a fixed result, and keeps what each one asked for.
class _FakePixRepository extends Fake implements PixRepository {
  _FakePixRepository(this.result);

  final Either<String, PixDeposit> result;
  final requests = <({int amountInCents, String? taxIdNumber})>[];

  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents, {
    String? address,
    Asset asset = Asset.depix,
    String? taxIdNumber,
  }) {
    requests.add((amountInCents: amountInCents, taxIdNumber: taxIdNumber));
    return TaskEither.fromEither(result);
  }
}

/// The core helpers, with no fee for the fee card, which reads the fee tier
/// while it builds.
class _CoreHelpers extends FakeCoreSyncHelpers {
  const _CoreHelpers();

  @override
  PixFeeDto pixFee({
    required double amountBrl,
    required bool hasReferral,
    double? quoteBrl,
  }) => PixFeeDto(
    feeRatePercent: 0,
    feeAmount: 0,
    discountedAmount: amountBrl,
    activeTier: amountBrl > 0 ? 0 : null,
    amountInCents: BigInt.from((amountBrl * 100).truncate()),
  );
}

/// No saved payers, for the payer step.
class _NoPayers implements FavoritePayersRepository {
  @override
  Future<List<FavoritePayer>> getAll() async => const [];
  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async => null;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

/// A sample charge. Its code is not a real Pix code.
final _deposit = PixDeposit(
  depositId: 'deposit-1',
  pixKey: 'sample-pix-code-for-the-confirmation-test',
  asset: Asset.depix,
  amountInCents: 10000,
  network: 'liquid',
  status: DepositStatus.pending,
  createdAt: DateTime(2026, 11, 10),
);

void main() {
  useCoreSyncHelpers(const _CoreHelpers());

  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);

  /// Opens the review of a deposit of R$ 100,00.
  Future<void> open(
    WidgetTester tester, {
    required _FakePixRepository repository,
    PixChargePayer payer = PixChargePayer.self,
    bool cpfRequired = false,
    DepositValidation validation = const DepositValidation.valid(),
  }) async {
    // The test font draws each glyph as a full square, so the fee rows need
    // more than the width of a phone.
    tester.view.physicalSize = const Size(600, 1000) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/pix/confirm',
      routes: [
        GoRoute(
          path: '/pix/confirm',
          builder: (_, _) => PixConfirmationScreen(payer: payer),
        ),
        GoRoute(
          path: '/pix/payment/:id',
          builder: (_, state) =>
              Scaffold(body: Text('payment ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          depositAmountProvider.overrideWith((ref) => 100.0),
          depositValidationProvider.overrideWithValue(validation),
          assetQuoteProvider.overrideWith((ref, asset) async => right(some(5))),
          feeRateProvider.overrideWith((ref, amount) async => 0),
          feeAmountProvider.overrideWith((ref, amount) async => 0),
          discountedFeesDepositProvider.overrideWith(
            (ref, amount) async => amount,
          ),
          hasReferralProvider.overrideWith((ref) async => false),
          pixCpfRequiredProvider.overrideWithValue(cpfRequired),
          pixDepositControllerProvider.overrideWith(
            (ref) async => PixDepositController(repository),
          ),
          favoritePayersRepositoryProvider.overrideWithValue(_NoPayers()),
        ],
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  /// Pumps [time] in frames.
  Future<void> advance(WidgetTester tester, Duration time) async {
    for (var elapsed = Duration.zero; elapsed < time; elapsed += step) {
      await tester.pump(step);
    }
  }

  /// The slide of [screen].
  Finder slideOf(Type screen) => find.descendant(
    of: find.byType(screen),
    matching: find.byType(SlideToConfirmButton),
  );

  /// The thumb of the slide of [screen].
  Finder thumbOf(Type screen) => find.descendant(
    of: slideOf(screen),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector && widget.onHorizontalDragEnd != null,
    ),
  );

  testWidgets('the deposit is confirmed with a slide, not a tap: the slide '
      'creates the charge, and the scene opens its payment screen', (
    tester,
  ) async {
    final repository = _FakePixRepository(right(_deposit));
    await open(tester, repository: repository);

    expect(find.byType(PrimaryButton), findsNothing);
    final slide = tester.widget<SlideToConfirmButton>(
      slideOf(PixConfirmationScreen),
    );
    expect(slide.text, t.wallet_slide_to_confirm);
    expect(slide.isEnabled, isTrue);

    await tester.tap(slideOf(PixConfirmationScreen));
    await advance(tester, const Duration(seconds: 1));
    expect(repository.requests, isEmpty);

    await tester.drag(thumbOf(PixConfirmationScreen), const Offset(800, 0));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PixQrScene), findsOneWidget);
    expect(repository.requests, [(amountInCents: 10000, taxIdNumber: null)]);

    await advance(tester, const Duration(seconds: 4));
    expect(find.text('payment deposit-1'), findsOneWidget);
    expect(find.byType(PixQrScene), findsNothing);
  });

  testWidgets('a failed charge shows the error and gives the thumb back, so '
      'a new slide tries again', (tester) async {
    final repository = _FakePixRepository(left('Falha simulada'));
    await open(tester, repository: repository);

    await tester.drag(thumbOf(PixConfirmationScreen), const Offset(800, 0));
    await advance(tester, const Duration(seconds: 3));

    expect(find.text('Falha simulada'), findsOneWidget);
    expect(find.byType(PixQrScene), findsNothing);
    final slide = slideOf(PixConfirmationScreen);
    expect(tester.widget<SlideToConfirmButton>(slide).isLoading, isFalse);
    expect(
      tester.getRect(thumbOf(PixConfirmationScreen)).left,
      tester.getRect(slide).left,
    );

    // The error stays over the slide for a while.
    await advance(tester, const Duration(seconds: 6));
    expect(find.text('Falha simulada'), findsNothing);
    await tester.drag(thumbOf(PixConfirmationScreen), const Offset(800, 0));
    await advance(tester, const Duration(seconds: 3));
    expect(repository.requests, hasLength(2));
  });

  testWidgets('the slide stays off while the amount is not valid', (
    tester,
  ) async {
    final repository = _FakePixRepository(right(_deposit));
    await open(
      tester,
      repository: repository,
      validation: const DepositValidation.errorWith(
        DepositValidationError.belowMinimum,
        limitAmount: 20,
      ),
    );

    expect(
      tester
          .widget<SlideToConfirmButton>(slideOf(PixConfirmationScreen))
          .isEnabled,
      isFalse,
    );
    await tester.drag(thumbOf(PixConfirmationScreen), const Offset(800, 0));
    await advance(tester, const Duration(seconds: 1));
    expect(repository.requests, isEmpty);
  });

  testWidgets('for another payer, a plain button opens the payer step, whose '
      'slide creates the charge with their document', (tester) async {
    final repository = _FakePixRepository(right(_deposit));
    await open(
      tester,
      repository: repository,
      payer: PixChargePayer.someoneElse,
      cpfRequired: true,
    );

    expect(slideOf(PixConfirmationScreen), findsNothing);
    final button = find.descendant(
      of: find.byType(PixConfirmationScreen),
      matching: find.byType(PrimaryButton),
    );
    expect(tester.widget<PrimaryButton>(button).text, t.common_continue);
    expect(tester.widget<PrimaryButton>(button).isEnabled, isTrue);

    await tester.tap(button);
    await advance(tester, const Duration(seconds: 1));
    expect(find.byType(CpfInputScreen), findsOneWidget);
    expect(repository.requests, isEmpty);
    // The button of the review waits with a spinner.
    final review = tester.widget<PrimaryButton>(
      find.descendant(
        of: find.byType(PixConfirmationScreen, skipOffstage: false),
        matching: find.byType(PrimaryButton, skipOffstage: false),
      ),
    );
    expect(review.isLoading, isTrue);

    await tester.enterText(find.byType(TextField), '52998224725');
    await advance(tester, const Duration(milliseconds: 500));
    await tester.drag(thumbOf(CpfInputScreen), const Offset(800, 0));
    await advance(tester, const Duration(seconds: 1));

    expect(find.byType(CpfInputScreen), findsNothing);
    expect(repository.requests, [
      (amountInCents: 10000, taxIdNumber: '52998224725'),
    ]);
    await advance(tester, const Duration(seconds: 4));
    expect(find.text('payment deposit-1'), findsOneWidget);
  });

  testWidgets('for another payer, the button stays off while the amount is '
      'not valid', (tester) async {
    final repository = _FakePixRepository(right(_deposit));
    await open(
      tester,
      repository: repository,
      payer: PixChargePayer.someoneElse,
      cpfRequired: true,
      validation: const DepositValidation.errorWith(
        DepositValidationError.belowMinimum,
        limitAmount: 20,
      ),
    );

    final button = find.byType(PrimaryButton);
    expect(tester.widget<PrimaryButton>(button).isEnabled, isFalse);
    await tester.tap(button);
    await advance(tester, const Duration(seconds: 1));
    expect(find.byType(CpfInputScreen), findsNothing);
  });

  testWidgets('for another payer without the payer step, the review creates '
      'the charge itself, so it keeps the slide', (tester) async {
    final repository = _FakePixRepository(right(_deposit));
    await open(
      tester,
      repository: repository,
      payer: PixChargePayer.someoneElse,
    );

    expect(find.byType(PrimaryButton), findsNothing);
    await tester.drag(thumbOf(PixConfirmationScreen), const Offset(800, 0));
    await tester.pump();
    await tester.pump();
    expect(repository.requests, [(amountInCents: 10000, taxIdNumber: null)]);
    await advance(tester, const Duration(seconds: 4));
  });
}
