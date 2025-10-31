import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/di/providers/swap_repository_provider.dart';
import 'package:mooze_mobile/features/swap/domain/entities.dart';
import 'package:mooze_mobile/features/swap/data/models.dart';

class SwapState {
  final bool loading;
  final List<SideswapAsset> assets;
  final List<SideswapMarket> markets;
  final QuoteResponse? currentQuote;
  final String? error;
  final int? activeQuoteId;
  final int? ttlMilliseconds;
  final int? millisecondsRemaining;
  final String? lastSendAssetId;
  final String? lastReceiveAssetId;
  final BigInt? lastAmount;
  final bool? isInverseMarket;
  final String?
  feeAssetId;

  const SwapState({
    required this.loading,
    required this.assets,
    required this.markets,
    this.currentQuote,
    this.error,
    this.activeQuoteId,
    this.ttlMilliseconds,
    this.millisecondsRemaining,
    this.lastSendAssetId,
    this.lastReceiveAssetId,
    this.lastAmount,
    this.isInverseMarket,
    this.feeAssetId,
  });

  int? get sendAmount {
    if (currentQuote?.quote == null) return null;
    final quote = currentQuote!.quote!;
    return isInverseMarket == true ? quote.quoteAmount : quote.baseAmount;
  }

  int? get receiveAmount {
    if (currentQuote?.quote == null) return null;
    final quote = currentQuote!.quote!;
    return isInverseMarket == true ? quote.baseAmount : quote.quoteAmount;
  }

  double? get exchangeRate {
    final send = sendAmount;
    final receive = receiveAmount;
    if (send == null || receive == null || send == BigInt.zero) return null;
    return receive.toDouble() / send.toDouble();
  }

  SwapState copyWith({
    bool? loading,
    List<SideswapAsset>? assets,
    List<SideswapMarket>? markets,
    QuoteResponse? currentQuote,
    String? error,
    int? activeQuoteId,
    int? ttlMilliseconds,
    int? millisecondsRemaining,
    String? lastSendAssetId,
    String? lastReceiveAssetId,
    BigInt? lastAmount,
    bool? isInverseMarket,
    String? feeAssetId,
  }) => SwapState(
    loading: loading ?? this.loading,
    assets: assets ?? this.assets,
    markets: markets ?? this.markets,
    currentQuote: currentQuote ?? this.currentQuote,
    error: error,
    activeQuoteId: activeQuoteId ?? this.activeQuoteId,
    ttlMilliseconds: ttlMilliseconds ?? this.ttlMilliseconds,
    millisecondsRemaining: millisecondsRemaining ?? this.millisecondsRemaining,
    lastSendAssetId: lastSendAssetId ?? this.lastSendAssetId,
    lastReceiveAssetId: lastReceiveAssetId ?? this.lastReceiveAssetId,
    lastAmount: lastAmount ?? this.lastAmount,
    isInverseMarket: isInverseMarket ?? this.isInverseMarket,
    feeAssetId: feeAssetId ?? this.feeAssetId,
  );

  static const initial = SwapState(loading: false, assets: [], markets: []);
}

class SwapController extends StateNotifier<SwapState> {
  Future<void> resetQuote() async {
    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _ttlDeadline = null;
    final repository = await _repositoryFuture;
    repository.stopQuote();
    state = state.copyWith(
      currentQuote: null,
      activeQuoteId: null,
      ttlMilliseconds: null,
      millisecondsRemaining: null,
      lastSendAssetId: null,
      lastReceiveAssetId: null,
      lastAmount: null,
      isInverseMarket: null,
      feeAssetId: null,
      error: null,
    );
  }

  final Future<SwapRepository> _repositoryFuture;
  StreamSubscription<QuoteResponse>? _quoteSub;
  Timer? _ttlTimer;
  DateTime? _ttlDeadline;

  SwapController({required Future<SwapRepository> repositoryFuture})
    : _repositoryFuture = repositoryFuture,
      super(SwapState.initial);

  Future<void> loadMetadata() async {
    final repository = await _repositoryFuture;
    state = state.copyWith(loading: true, error: null);
    final assetsRes = await repository.getAssets().run();
    final marketsRes = await repository.getMarkets().run();
    state = state.copyWith(
      loading: false,
      assets: assetsRes.getOrElse((_) => []),
      markets: marketsRes.getOrElse((_) => []),
      error: assetsRes.match(
        (l) => l,
        (_) => marketsRes.match((l2) => l2, (_) => null),
      ),
    );
  }

  Future<void> startQuote({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
    List<SwapUtxo>? explicitUtxos,
    String? explicitReceiveAddress,
    String? explicitChangeAddress,
  }) async {
    final repository = await _repositoryFuture;
    _quoteSub?.cancel();
    state = state.copyWith(
      loading: true,
      error: null,
      currentQuote: null,
      activeQuoteId: null,
      ttlMilliseconds: null,
      millisecondsRemaining: null,
    );
    _ttlTimer?.cancel();
    _ttlDeadline = null;

    final normalizedParams = repository.normalizeSwapParams(
      sendAsset: sendAsset,
      receiveAsset: receiveAsset,
    );

    if (normalizedParams == null) {
      final errMsg =
          'Par de ativos não suportado para swap. Selecione um par válido.';
      state = state.copyWith(loading: false, error: errMsg);
      return;
    }

    final baseAsset = normalizedParams.baseAsset;
    final quoteAsset = normalizedParams.quoteAsset;
    final direction = normalizedParams.direction;
    final assetType = normalizedParams.assetType;

    final isInverse = assetType == 'Quote';

    final feeAsset = baseAsset;

    final utxoAsset = assetType == 'Base' ? baseAsset : quoteAsset;

    if (utxoAsset != sendAsset) {
      final errMsg =
          'Erro interno: normalização incorreta (utxo=$utxoAsset, send=$sendAsset)';
      state = state.copyWith(loading: false, error: errMsg);
      return;
    }

    final addrRes = await repository.getNewAddress().run();
    final utxosRes =
        await repository.selectUtxos(assetId: utxoAsset, amount: amount).run();
    if (addrRes.isLeft() || utxosRes.isLeft()) {
      final err = addrRes.match(
        (l) => l,
        (_) => utxosRes.match((l2) => l2, (_) => 'Erro inesperado'),
      );
      state = state.copyWith(loading: false, error: err);
      return;
    }
    final receiveAddress =
        explicitReceiveAddress ?? addrRes.getRight().toNullable()!;
    final changeAddress = explicitChangeAddress ?? receiveAddress;
    final utxos = explicitUtxos ?? utxosRes.getOrElse((_) => []);
    final result = repository.startQuote(
      baseAsset: baseAsset,
      quoteAsset: quoteAsset,
      assetType: assetType,
      amount: amount,
      direction: direction,
      utxos: utxos,
      receiveAddress: receiveAddress,
      changeAddress: changeAddress,
    );
    result.match((err) => state = state.copyWith(loading: false, error: err), (
      stream,
    ) {
      _quoteSub = stream.listen((quote) {
        String? msg = quote.error?.errorMessage;
        if (msg == null && quote.lowBalance != null) {
          final lb = quote.lowBalance!;
          final totalFees = lb.fixedFee + lb.serverFee;
          msg =
              'Saldo insuficiente para este swap. Disponível: ${lb.available} sats. Necessário (enviado + taxas): ${lb.baseAmount + totalFees} sats.';
        }

        final ttlMs = quote.quote?.ttl;
        final initializeDeadline = _ttlDeadline == null && ttlMs != null;
        if (initializeDeadline) {
          _ttlDeadline = DateTime.now().add(Duration(milliseconds: ttlMs));
        }

        state = state.copyWith(
          loading: false,
          currentQuote: quote,
          error: msg,
          activeQuoteId: quote.quote?.quoteId,
          ttlMilliseconds: initializeDeadline ? ttlMs : state.ttlMilliseconds,
          millisecondsRemaining:
              initializeDeadline ? ttlMs : state.millisecondsRemaining,
          lastSendAssetId: sendAsset,
          lastReceiveAssetId: receiveAsset,
          lastAmount: amount,
          isInverseMarket: isInverse,
          feeAssetId: feeAsset,
        );
        if (initializeDeadline) {
          _startTtlCountdown();
        }
      });
    });
  }

  void _startTtlCountdown() {
    _ttlTimer?.cancel();
    if (_ttlDeadline == null) return;
    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remainingMs =
          _ttlDeadline!.difference(DateTime.now()).inMilliseconds;
      if (remainingMs <= 0) {
        t.cancel();
        _ttlDeadline = null;
        state = state.copyWith(millisecondsRemaining: 0);
        final paramsOk =
            state.lastSendAssetId != null &&
            state.lastReceiveAssetId != null &&
            state.lastAmount != null;
        if (paramsOk) {
          startQuote(
            sendAsset: state.lastSendAssetId!,
            receiveAsset: state.lastReceiveAssetId!,
            amount: state.lastAmount!,
          );
        }
      } else {
        state = state.copyWith(millisecondsRemaining: remainingMs);
      }
    });
  }

  void cancelQuote() {
    _ttlTimer?.cancel();
    _repositoryFuture.then((r) => r.stopQuote());
    _quoteSub?.cancel();
    _ttlDeadline = null;
    state = state.copyWith(
      currentQuote: null,
      activeQuoteId: null,
      ttlMilliseconds: null,
      millisecondsRemaining: null,
    );
  }

  Future<Either<String, String>> confirmSwap() async {
    final repository = await _repositoryFuture;
    final quote = state.currentQuote?.quote;
    if (quote == null) {
      return Either.left('Nenhum quote ativo');
    }
    state = state.copyWith(loading: true, error: null);
    final psetRes = await repository.getQuotePset(quote.quoteId).run();
    return await psetRes.match(
      (err) async {
        state = state.copyWith(loading: false, error: err);
        return Either.left(err);
      },
      (pset) async {
        final txidRes =
            await repository
                .signAndBroadcast(quoteId: quote.quoteId, pset: pset)
                .run();
        return txidRes.match(
          (err) {
            state = state.copyWith(loading: false, error: err);
            return Either.left(err);
          },
          (txid) {
            state = state.copyWith(loading: false);
            return Either.right(txid);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _quoteSub?.cancel();
    _ttlTimer?.cancel();
    _repositoryFuture.then((r) => r.stopQuote());
    _ttlDeadline = null;
    super.dispose();
  }
}

final swapControllerProvider = StateNotifierProvider.autoDispose<
  SwapController,
  SwapState
>((ref) {
  final repoFuture = ref.watch(swapRepositoryProvider.future);
  final controller = SwapController(repositoryFuture: repoFuture);
  return controller;
});
