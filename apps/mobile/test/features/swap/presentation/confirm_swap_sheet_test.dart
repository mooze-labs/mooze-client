import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/swap_controller.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/confirm_swap_bottom_sheet.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/test_app.dart';
import 'fake_swap_repository.dart';

final lbtc = Asset.lbtc.id;
final depix = Asset.depix.id;

/// 1 000 Depix, in base units.
const thousandDepix = 100000000000;

void main() {
  /// The confirm sheet of 1 000 Depix for L-BTC. SideSwap quotes 246 282
  /// sats before its 2 282 sats of fees, charged in L-BTC.
  Future<void> showSheet(WidgetTester tester) async {
    // The test font draws every glyph as a wide square: a wide surface
    // keeps the rows of the sheet from overflowing. These tests read
    // values, not layout.
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = FakeSwapRepository([
      market(base: lbtc, quote: depix, feeAsset: 'Base'),
    ]);
    // The provider disposes the controller with the tree.
    final controller = SwapController(
      repositoryFuture: Future.value(repository),
    );
    await controller.loadMetadata();
    await controller.startQuote(
      sendAsset: depix,
      receiveAsset: lbtc,
      amount: BigInt.from(thousandDepix),
    );
    repository.quotes.add(
      quoteOf(
        id: 1,
        base: lbtc,
        quote: depix,
        requested: thousandDepix,
        baseAmount: 244000 + 2282,
        quoteAmount: thousandDepix,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          swapControllerProvider.overrideWith((ref) => controller),
        ],
        child: wrapForTest(const Scaffold(body: ConfirmSwapBottomSheet())),
      ),
    );
    // The countdown ticks, so the sheet never settles.
    await tester.pump();
    await tester.pump();
  }

  // The sheet promises what arrives in the wallet: the quote minus the fees
  // charged in L-BTC.
  testWidgets('"you receive" shows the amount after the fees', (tester) async {
    await showSheet(tester);

    expect(find.text('244.000'), findsOneWidget);
    expect(find.text('246.282'), findsNothing);
    expect(find.text('2.282 sats'), findsOneWidget);
  });

  // Bitcoin shows in sats, as on the swap screen: 1 Depix buys a few hundred
  // sats, which reads better than 0.00000244 L-BTC.
  testWidgets('the rate shows sats per unit sent', (tester) async {
    await showSheet(tester);

    expect(find.text('Cotação · 1 Depix = 244 SATS'), findsOneWidget);
  });
}
