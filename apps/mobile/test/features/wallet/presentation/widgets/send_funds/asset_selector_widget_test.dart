import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_picker_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/asset_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import '../../../../../shared/test_app.dart';

/// Balances of the tests.
final _holdings = [
  WalletHolding(
    asset: Asset.lbtc,
    balance: BigInt.from(48210),
    fiatValue: 295.05,
    formattedBalance: '48.210 sats',
    formattedFiatValue: r'R$ 295,05',
    hasBalance: true,
  ),
  WalletHolding(
    asset: Asset.depix,
    balance: BigInt.from(152075000000),
    fiatValue: 1520.75,
    formattedBalance: '1.520,75 Depix',
    formattedFiatValue: r'R$ 1.520,75',
    hasBalance: true,
  ),
];

Future<ProviderContainer> _pumpSelector(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletHoldingsProvider.overrideWithValue(
          AsyncValue.data(Right(_holdings)),
        ),
        isVisibleProvider.overrideWith((ref) => _FixedVisibility(false)),
        selectedAssetBalanceProvider.overrideWith(
          (ref) async => const Right('48.210 sats'),
        ),
      ],
      child: wrapForTest(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: AssetSelectorWidget(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(AssetSelectorWidget)),
  );
}

void main() {
  testWidgets('the selector keeps the available balance', (tester) async {
    await _pumpSelector(tester);

    expect(find.text('Saldo disponível'), findsOneWidget);
    expect(find.text('48.210 sats'), findsOneWidget);
  });

  testWidgets('the sheet shows the balance of each asset', (tester) async {
    await _pumpSelector(tester);
    await tester.tap(find.byType(AssetSelectorWidget));
    await tester.pumpAndSettle();

    final sheet = find.byType(AssetPickerSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('48.210 sats')),
      findsOneWidget,
    );
    expect(find.text(r'R$ 295,05'), findsOneWidget);
    expect(find.text('1.520,75 Depix'), findsOneWidget);
    expect(find.text(r'R$ 1.520,75'), findsOneWidget);
  });

  testWidgets('a pick closes the sheet and selects the asset', (tester) async {
    final container = await _pumpSelector(tester);
    await tester.tap(find.byType(AssetSelectorWidget));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Depix'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSheet), findsNothing);
    expect(container.read(selectedAssetProvider), Asset.depix);
  });
}

/// Balance visibility with a fixed start value. The app notifier reads
/// the stored setting, which the tests do not have.
class _FixedVisibility extends StateNotifier<bool>
    implements VisibilityNotifier {
  _FixedVisibility(super.hidden);

  @override
  Future<void> setVisibility(bool isVisible) async => state = isVisible;

  @override
  void toggle() => state = !state;
}
