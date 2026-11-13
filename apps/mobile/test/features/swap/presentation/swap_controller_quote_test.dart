import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/data/models.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/swap_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'fake_swap_repository.dart';

final lbtc = Asset.lbtc.id;
final usdt = Asset.usdt.id;

/// 1 000 USDt, in base units.
const thousandUsdt = 100000000000;

/// A quote of the L-BTC / USDt market.
QuoteResponse lbtcUsdtQuote({
  required int id,
  required int requested,
  required int baseAmount,
  required int quoteAmount,
}) => quoteOf(
  id: id,
  base: lbtc,
  quote: usdt,
  requested: requested,
  baseAmount: baseAmount,
  quoteAmount: quoteAmount,
);

void main() {
  late FakeSwapRepository repository;
  late SwapController controller;

  /// Opens a quote on the L-BTC / USDt market, with the fees in [feeAsset].
  Future<void> quoting(
    String feeAsset, {
    required String send,
    required String receive,
    required int amount,
  }) async {
    repository = FakeSwapRepository([
      market(base: lbtc, quote: usdt, feeAsset: feeAsset),
    ]);
    controller = SwapController(repositoryFuture: Future.value(repository));
    addTearDown(controller.dispose);
    await controller.loadMetadata();
    await controller.startQuote(
      sendAsset: send,
      receiveAsset: receive,
      amount: BigInt.from(amount),
    );
  }

  Future<void> emit(QuoteResponse quote) async {
    repository.quotes.add(quote);
    await pumpEventQueue();
  }

  // SideSwap quotes the trade before fees and charges the fees in the fee
  // asset of the market. The official client computes what the user sends
  // and receives the same way (`get_send_recv_amount`).
  group('what the user sends and receives', () {
    // The swap of the report: 1 000 USDt for L-BTC, with the fees in L-BTC.
    // The sheet said 1 100 785 sats, and 2 282 sats less arrived.
    test('fees in the asset received come out of it', () async {
      await quoting('Base', send: usdt, receive: lbtc, amount: thousandUsdt);
      await emit(
        lbtcUsdtQuote(
          id: 1,
          requested: thousandUsdt,
          baseAmount: 1100785,
          quoteAmount: thousandUsdt,
        ),
      );

      expect(controller.state.receiveAmount, 1100785 - 2282);
      expect(controller.state.sendAmount, thousandUsdt);
      expect(controller.state.feeAssetId, lbtc);
    });

    // Sell L-BTC with the fees in L-BTC: SideSwap takes the fees from the
    // amount sent, so the sent total is the amount typed.
    test(
      'fees in the asset sent add to it, and the receive stays whole',
      () async {
        await quoting('Base', send: lbtc, receive: usdt, amount: 1100785);
        await emit(
          lbtcUsdtQuote(
            id: 1,
            requested: 1100785,
            baseAmount: 1100785 - 2282,
            quoteAmount: thousandUsdt,
          ),
        );

        expect(controller.state.sendAmount, 1100785);
        expect(controller.state.receiveAmount, thousandUsdt);
      },
    );

    // The fee asset is a field of the market, not always its base asset.
    test('the market tells which asset pays the fees', () async {
      await quoting('Quote', send: lbtc, receive: usdt, amount: 1100785);
      await emit(
        lbtcUsdtQuote(
          id: 1,
          requested: 1100785,
          baseAmount: 1100785,
          quoteAmount: thousandUsdt,
        ),
      );

      expect(controller.state.feeAssetId, usdt);
      expect(controller.state.receiveAmount, thousandUsdt - 2282);
      expect(controller.state.sendAmount, 1100785);
    });

    // When the metadata did not load, the quote loads the markets itself.
    // They also tell the fee asset.
    test('the markets loaded with the quote tell the fee asset', () async {
      repository = FakeSwapRepository([
        market(base: lbtc, quote: usdt, feeAsset: 'Quote'),
      ]);
      controller = SwapController(repositoryFuture: Future.value(repository));
      addTearDown(controller.dispose);
      await controller.startQuote(
        sendAsset: lbtc,
        receiveAsset: usdt,
        amount: BigInt.from(1100785),
      );
      await emit(
        lbtcUsdtQuote(
          id: 1,
          requested: 1100785,
          baseAmount: 1100785,
          quoteAmount: thousandUsdt,
        ),
      );

      expect(controller.state.feeAssetId, usdt);
      expect(controller.state.receiveAmount, thousandUsdt - 2282);
    });

    // The rate on the sheet is what the user gets per unit sent, fees
    // included, so amount × rate gives the amount received.
    test('the rate is the amount received per unit sent', () async {
      await quoting('Base', send: usdt, receive: lbtc, amount: thousandUsdt);
      await emit(
        lbtcUsdtQuote(
          id: 1,
          requested: thousandUsdt,
          baseAmount: 1100785,
          quoteAmount: thousandUsdt,
        ),
      );

      expect(controller.state.exchangeRate, (1100785 - 2282) / thousandUsdt);
    });
  });

  // SideSwap sends a new quote every ~3 s on the same subscription. The
  // user must sign the quote whose amounts are on the screen.
  group('the quote signed is the quote shown', () {
    Future<void> twoQuotes() async {
      await quoting('Base', send: usdt, receive: lbtc, amount: thousandUsdt);
      await emit(
        lbtcUsdtQuote(
          id: 1,
          requested: thousandUsdt,
          baseAmount: 1100785,
          quoteAmount: thousandUsdt,
        ),
      );
      // The price moved: 219 sats less, as in the report.
      await emit(
        lbtcUsdtQuote(
          id: 2,
          requested: thousandUsdt,
          baseAmount: 1100785 - 219,
          quoteAmount: thousandUsdt,
        ),
      );
    }

    test('a new quote shows its amounts, and the countdown goes on', () async {
      await twoQuotes();

      expect(controller.state.receiveAmount, 1100785 - 219 - 2282);
      expect(controller.state.status, QuoteStatus.valid);
    });

    test('confirm signs the quote whose amounts are on the screen', () async {
      await twoQuotes();
      final shown = controller.state.currentQuote!.quote!;

      await controller.confirmSwap();

      expect(repository.signed, [shown.quoteId]);
      expect(shown.baseAmount, 1100785 - 219);
    });
  });
}
