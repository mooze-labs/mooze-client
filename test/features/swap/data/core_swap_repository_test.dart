import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/swap/data/models.dart';
import 'package:mooze_mobile/features/swap/data/repositories/core_swap_repository.dart';
import 'package:mooze_mobile/features/swap/data/services/core_sideswap_session.dart';

class _MockCore extends Mock implements MoozeCore {}

const _lbtc = 'lbtc-asset';
const _usdt = 'usdt-asset';

SideSwapEventDto _quoteEvent({
  QuoteStatusDto status = QuoteStatusDto.success,
  int quoteId = 11,
}) =>
    SideSwapEventDto(
      kind: SideSwapEventKind.quote,
      quote: QuoteDto(
        status: status,
        quoteId: status == QuoteStatusDto.success ? BigInt.from(quoteId) : null,
        baseAmount: BigInt.from(1000),
        quoteAmount: BigInt.from(650000),
        serverFee: BigInt.from(2),
        fixedFee: BigInt.from(1),
        ttlMs: BigInt.from(30000),
        available: status == QuoteStatusDto.lowBalance ? BigInt.from(5) : null,
        errorMessage: status == QuoteStatusDto.error ? 'sem liquidez' : null,
        quoteSubId: BigInt.from(3),
        requestedAmount: BigInt.from(1000),
        baseAssetId: _lbtc,
        quoteAssetId: _usdt,
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(BigInt.zero));

  late _MockCore core;
  late StreamController<SideSwapEventDto> events;
  late CoreSwapRepository repo;

  setUp(() {
    core = _MockCore();
    events = StreamController<SideSwapEventDto>.broadcast();
    when(() => core.sideswapConnect(
          apiKey: any(named: 'apiKey'),
          url: any(named: 'url'),
        )).thenAnswer((_) async {});
    when(() => core.sideswapEvents()).thenAnswer((_) => events.stream);
    when(() => core.sideswapStopQuote()).thenAnswer((_) async {});
    when(() => core.sideswapCloseEvents()).thenAnswer((_) async {});
    when(() => core.sideswapDisconnect()).thenAnswer((_) async {});
    when(
      () => core.sideswapStartQuote(
        sendAssetId: any(named: 'sendAssetId'),
        receiveAssetId: any(named: 'receiveAssetId'),
        amount: any(named: 'amount'),
      ),
    ).thenAnswer(
      (_) async => StartQuoteDto(
        started: true,
        quoteSubId: BigInt.from(3),
        baseAssetId: _lbtc,
        quoteAssetId: _usdt,
      ),
    );
    repo = CoreSwapRepository(
      session: CoreSideswapSession(core: Future.value(core), apiKey: 'key'),
    );
  });

  tearDown(() async {
    repo.dispose();
    await events.close();
  });

  test('every call connects with the app API key first', () async {
    when(() => core.sideswapAssets()).thenAnswer((_) async => []);

    await repo.getAssets().run();

    verify(() => core.sideswapConnect(apiKey: 'key', url: null)).called(1);
  });

  test('getAssets and getMarkets map the core lists', () async {
    when(() => core.sideswapAssets()).thenAnswer(
      (_) async => [
        const SideswapAssetDto(
          assetId: _usdt,
          name: 'Tether USD',
          ticker: 'USDt',
          precision: 8,
          instantSwaps: true,
        ),
      ],
    );
    when(() => core.sideswapMarkets()).thenAnswer(
      (_) async => [
        const SideswapMarketDto(
          baseAssetId: _lbtc,
          quoteAssetId: _usdt,
          feeAsset: 'Quote',
          marketType: 'Stablecoin',
        ),
      ],
    );

    final assets = (await repo.getAssets().run()).getRight().toNullable()!;
    final markets = (await repo.getMarkets().run()).getRight().toNullable()!;

    expect(assets.single.ticker, 'USDt');
    expect(assets.single.instantSwaps, isTrue);
    expect(markets.single.type, 'Stablecoin');
    expect(markets.single.feeAsset, 'Quote');
  });

  test('normalizeSwapParams finds direct and inverse markets', () async {
    when(() => core.sideswapMarkets()).thenAnswer(
      (_) async => [
        const SideswapMarketDto(
          baseAssetId: _lbtc,
          quoteAssetId: _usdt,
          feeAsset: 'Quote',
          marketType: 'Stablecoin',
        ),
      ],
    );
    expect(
      repo.normalizeSwapParams(sendAsset: _lbtc, receiveAsset: _usdt),
      isNull,
      reason: 'no markets loaded yet',
    );
    await repo.getMarkets().run();

    final direct =
        repo.normalizeSwapParams(sendAsset: _lbtc, receiveAsset: _usdt)!;
    final inverse =
        repo.normalizeSwapParams(sendAsset: _usdt, receiveAsset: _lbtc)!;

    expect(direct.assetType, 'Base');
    expect(direct.baseAsset, _lbtc);
    expect(inverse.assetType, 'Quote');
    expect(inverse.baseAsset, _lbtc);
    expect(inverse.quoteAsset, _usdt);
  });

  group('quotes', () {
    test('startQuote opens the event stream and maps every quote kind',
        () async {
      final result = await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(1000),
      );
      final stream = result.getRight().toNullable()!;
      final received = <QuoteResponse>[];
      stream.listen(received.add);

      events
        ..add(_quoteEvent())
        ..add(_quoteEvent(status: QuoteStatusDto.lowBalance))
        ..add(_quoteEvent(status: QuoteStatusDto.error));
      await Future<void>.delayed(Duration.zero);

      verify(() => core.sideswapEvents()).called(1);
      verify(
        () => core.sideswapStartQuote(
          sendAssetId: _lbtc,
          receiveAssetId: _usdt,
          amount: BigInt.from(1000),
        ),
      ).called(1);
      expect(received, hasLength(3));
      final success = received[0];
      expect(success.quote!.quoteId, 11);
      expect(success.quote!.ttl, 30000);
      expect(
        success.matchesRequest(
          baseAssetId: _lbtc,
          quoteAssetId: _usdt,
          requestedAmount: 1000,
        ),
        isTrue,
      );
      expect(received[1].lowBalance!.available, 5);
      expect(received[2].error!.errorMessage, 'sem liquidez');
    });

    test('a quote lock held elsewhere is a Left', () async {
      when(
        () => core.sideswapStartQuote(
          sendAssetId: any(named: 'sendAssetId'),
          receiveAssetId: any(named: 'receiveAssetId'),
          amount: any(named: 'amount'),
        ),
      ).thenAnswer((_) async => const StartQuoteDto(started: false));

      final result = await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(1000),
      );

      expect(result.isLeft(), isTrue);
    });

    test('a disconnect restarts the active quote', () async {
      await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(1000),
      );

      events.add(
        const SideSwapEventDto(
          kind: SideSwapEventKind.disconnected,
          message: 'socket closed',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => core.sideswapStartQuote(
          sendAssetId: _lbtc,
          receiveAssetId: _usdt,
          amount: BigInt.from(1000),
        ),
      ).called(2);
    });

    test('after stopQuote a disconnect does not restart a quote', () async {
      await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(1000),
      );
      repo.stopQuote();

      events.add(
        const SideSwapEventDto(kind: SideSwapEventKind.disconnected),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => core.sideswapStartQuote(
          sendAssetId: any(named: 'sendAssetId'),
          receiveAssetId: any(named: 'receiveAssetId'),
          amount: any(named: 'amount'),
        ),
      ).called(1);
      verify(() => core.sideswapStopQuote()).called(1);
    });

    test('a closed stream reopens on the next quote', () async {
      await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(1000),
      );
      events.add(const SideSwapEventDto(kind: SideSwapEventKind.closed));
      await Future<void>.delayed(Duration.zero);

      await repo.startQuote(
        sendAsset: _lbtc,
        receiveAsset: _usdt,
        amount: BigInt.from(2000),
      );

      verify(() => core.sideswapEvents()).called(2);
    });
  });

  group('executeSwap', () {
    test('returns the core txid', () async {
      when(() => core.sideswapExecuteSwap(quoteId: BigInt.from(11)))
          .thenAnswer((_) async => 'txid-1');

      final result = await repo.executeSwap(11).run();

      expect(result.getRight().toNullable(), 'txid-1');
    });

    test('returns the core error text', () async {
      when(() => core.sideswapExecuteSwap(quoteId: any(named: 'quoteId')))
          .thenThrow(
        const CoreError(
          kind: CoreErrorKind.service,
          message: 'Quote pset não encontrado',
        ),
      );

      final result = await repo.executeSwap(11).run();

      expect(result.getLeft().toNullable(), 'Quote pset não encontrado');
    });
  });

  test('dispose stops the quote and the events but keeps the connection',
      () async {
    await repo.startQuote(
      sendAsset: _lbtc,
      receiveAsset: _usdt,
      amount: BigInt.from(1000),
    );

    repo.dispose();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    verify(() => core.sideswapStopQuote()).called(1);
    verify(() => core.sideswapCloseEvents()).called(1);
    verifyNever(() => core.sideswapDisconnect());
    expect(events.hasListener, isFalse);
  });

  test('forceReconnect drops and reopens the connection and the stream',
      () async {
    await repo.startQuote(
      sendAsset: _lbtc,
      receiveAsset: _usdt,
      amount: BigInt.from(1000),
    );

    await repo.forceReconnect();

    verify(() => core.sideswapDisconnect()).called(1);
    verify(() => core.sideswapEvents()).called(2);
  });
}
