import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/interfaces/fee_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/custom_fee_rate_option.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/fee_speed_selection_widget.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

import '../../../../swap/presentation/fixed_fee_provider.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// The speed choice of a BTC send on the Bitcoin network, with the custom
  /// fee setting at [customFee].
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required bool customFee,
  }) async {
    SharedPreferences.setMockInitialValues({
      SendCustomFeeEnabledNotifier.key: customFee,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedAssetProvider.overrideWith((ref) => Asset.btc),
          selectedNetworkProvider.overrideWithValue(Blockchain.bitcoin),
          bitcoinFeeServiceProvider.overrideWithValue(
            FixedFeeProvider().service,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: FeeSpeedSelectionWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(FeeSpeedSelectionWidget)),
    );
  }

  FeeSpeed? selectedSpeed(WidgetTester tester) => tester
      .widget<FeeSpeedSelector>(find.byType(FeeSpeedSelector))
      .selectedSpeed;

  testWidgets('without the setting, only the speeds show', (tester) async {
    await pump(tester, customFee: false);

    expect(find.byType(FeeSpeedSelector), findsOneWidget);
    expect(find.byType(CustomFeeRateOption), findsNothing);
  });

  testWidgets('with the setting, a custom rate replaces the selected speed, '
      'and a speed clears it', (tester) async {
    final container = await pump(tester, customFee: true);
    expect(selectedSpeed(tester), FeeSpeed.medium);

    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();

    expect(container.read(customFeeRateProvider), 5);
    expect(selectedSpeed(tester), isNull);
    expect(await container.read(bitcoinSendFeeRateProvider.future), 5);

    await tester.tap(find.byTooltip(t.wallet_fee_custom_increase));
    await tester.pumpAndSettle();
    expect(await container.read(bitcoinSendFeeRateProvider.future), 6);

    await tester.tap(find.text(t.wallet_fee_fast));
    await tester.pumpAndSettle();

    expect(container.read(customFeeRateProvider), isNull);
    expect(container.read(feeSpeedProvider), FeeSpeed.fast);
    expect(selectedSpeed(tester), FeeSpeed.fast);
    expect(await container.read(bitcoinSendFeeRateProvider.future), 9);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the lens leaves the speeds for a custom rate, and comes back '
      'with a speed', (tester) async {
    await pump(tester, customFee: true);
    double speedLens() => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.descendant(
              of: find.byType(FeeSpeedSelector),
              matching: find.byType(GlassLens),
            ),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    expect(speedLens(), 1);

    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();
    expect(speedLens(), 0);

    await tester.tap(find.text(t.wallet_fee_normal));
    await tester.pumpAndSettle();
    expect(speedLens(), 1);
  });

  testWidgets('while the rates load, the skeleton has the height of the '
      'speeds', (tester) async {
    final rates = Completer<BitcoinFeeEstimate?>();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedAssetProvider.overrideWith((ref) => Asset.btc),
          selectedNetworkProvider.overrideWithValue(Blockchain.bitcoin),
          bitcoinFeeServiceProvider.overrideWithValue(
            BitcoinFeeService(providers: [_Pending(rates.future)]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          // A scroll view, as the send form.
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: FeeSpeedSelectionWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final loading = tester.getSize(find.byType(FeeSpeedSelectionWidget));

    rates.complete(fixedBitcoinFees());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FeeSpeedSelectionWidget)), loading);
  });

  testWidgets('a closed custom row opens again on a new selection', (
    tester,
  ) async {
    await pump(tester, customFee: true);
    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();
    // The chevron closes it.
    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text(t.wallet_fee_fast));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.wallet_fee_custom));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });
}

/// A fee source whose rates arrive with [rates].
class _Pending implements FeeProvider {
  _Pending(this.rates);

  final Future<BitcoinFeeEstimate?> rates;

  @override
  String get providerName => 'pending';

  @override
  Future<BitcoinFeeEstimate?> fetchFeeEstimate() => rates;
}
