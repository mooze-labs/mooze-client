import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

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
  final String? feeAssetId;

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
  final _log = AppLoggerService();
  static const _tag = 'Swap';

  Future<void> resetQuote() async {
    _log.debug(_tag, 'Resetting quote state');
    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _ttlDeadline = null;
    final repository = await _repositoryFuture;
    repository.stopQuote();
    if (!mounted) return;
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

  Future<void> forceReconnectAndReset() async {
    _log.warning(
      _tag,
      'Forcing WebSocket reconnect and resetting all swap state',
    );
    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _ttlDeadline = null;

    final repository = await _repositoryFuture;
    try {
      await repository.forceReconnect();
      repository.resetQuoteProgress();
      _log.info(_tag, 'Force reconnect succeeded');
    } catch (e, stackTrace) {
      _log.error(
        _tag,
        'Error during force reconnect',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) return;
    state = state.copyWith(
      loading: false,
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
  bool _mounted = true;

  @override
  bool get mounted => _mounted;

  SwapController({required Future<SwapRepository> repositoryFuture})
    : _repositoryFuture = repositoryFuture,
      super(SwapState.initial);

  Future<void> loadMetadata() async {
    _log.debug(_tag, 'Loading swap metadata (assets and markets)');
    final repository = await _repositoryFuture;
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);
    final assetsRes = await repository.getAssets().run();
    final marketsRes = await repository.getMarkets().run();
    if (!mounted) return;

    assetsRes.match(
      (err) => _log.error(_tag, 'Failed to load assets: $err'),
      (assets) => _log.info(_tag, 'Loaded ${assets.length} swap assets'),
    );
    marketsRes.match(
      (err) => _log.error(_tag, 'Failed to load markets: $err'),
      (markets) => _log.info(_tag, 'Loaded ${markets.length} swap markets'),
    );

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
    _log.info(
      _tag,
      'Starting quote — send: $sendAsset, receive: $receiveAsset, amount: $amount sats',
    );
    final repository = await _repositoryFuture;
    if (!mounted) return;
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

    var normalizedParams = repository.normalizeSwapParams(
      sendAsset: sendAsset,
      receiveAsset: receiveAsset,
    );

    if (normalizedParams == null) {
      _log.warning(
        _tag,
        'normalizeSwapParams returned null — reloading markets for send=$sendAsset, receive=$receiveAsset',
      );
      final marketsRes = await repository.getMarkets().run();
      if (!mounted) return;
      if (marketsRes.isRight()) {
        normalizedParams = repository.normalizeSwapParams(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
        );
      }
    }

    if (normalizedParams == null) {
      _log.error(
        _tag,
        'Trading pair not found even after reloading markets — send=$sendAsset, receive=$receiveAsset',
      );
      if (!mounted) return;
      state = state.copyWith(loading: false, error: null);
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
      _log.error(
        _tag,
        'Internal normalization mismatch: utxoAsset=$utxoAsset != sendAsset=$sendAsset',
      );
      if (!mounted) return;
      state = state.copyWith(loading: false, error: errMsg);
      return;
    }

    _log.debug(
      _tag,
      'Fetching new receive address and selecting UTXOs for asset=$utxoAsset, amount=$amount sats',
    );
    final addrRes = await repository.getNewAddress().run();
    final utxosRes =
        await repository.selectUtxos(assetId: utxoAsset, amount: amount).run();
    if (!mounted) return;
    if (addrRes.isLeft() || utxosRes.isLeft()) {
      final err = addrRes.match(
        (l) => l,
        (_) => utxosRes.match((l2) => l2, (_) => 'Erro inesperado'),
      );
      _log.error(_tag, 'Failed to get address or UTXOs: $err');
      if (!mounted) return;
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
    _log.debug(
      _tag,
      'Quote request sent — baseAsset=$baseAsset, quoteAsset=$quoteAsset, '
      'assetType=$assetType, direction=$direction, isInverse=$isInverse',
    );
    result.match(
      (err) {
        _log.error(_tag, 'Failed to start quote stream: $err');
        if (!mounted) return;
        state = state.copyWith(loading: false, error: err);
      },
      (stream) {
        _quoteSub = stream.listen((quote) {
          if (!mounted) return;
          String? msg = quote.error?.errorMessage;

          if (msg != null &&
              (msg.toLowerCase().contains('invalid utxo') ||
                  msg.toLowerCase().contains('unknown utxo') ||
                  msg.toLowerCase().contains('wait for wallet sync'))) {
            msg =
                'Aguarde alguns instantes antes de realizar outro swap. '
                'Sua transação anterior ainda está sendo processada.';
          }

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

          if (msg != null) {
            _log.warning(_tag, 'Quote stream received error message: $msg');
          } else if (quote.quote != null) {
            _log.info(
              _tag,
              'Quote received — id: ${quote.quote!.quoteId}, '
              'baseAmount: ${quote.quote!.baseAmount} sats, '
              'quoteAmount: ${quote.quote!.quoteAmount} sats, '
              'ttl: ${ttlMs}ms',
            );
          }

          if (!mounted) return;
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
      },
    );
  }

  void _startTtlCountdown() {
    _ttlTimer?.cancel();
    if (_ttlDeadline == null) return;
    _log.debug(_tag, 'TTL countdown started');
    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remainingMs =
          _ttlDeadline!.difference(DateTime.now()).inMilliseconds;
      if (remainingMs <= 0) {
        t.cancel();
        _ttlDeadline = null;
        _log.info(
          _tag,
          'Quote TTL expired — auto-renewing quote for '
          'send=${state.lastSendAssetId}, receive=${state.lastReceiveAssetId}, amount=${state.lastAmount}',
        );
        if (!mounted) return;
        state = state.copyWith(millisecondsRemaining: 0);
        final paramsOk =
            state.lastSendAssetId != null &&
            state.lastReceiveAssetId != null &&
            state.lastAmount != null;
        if (paramsOk && mounted) {
          startQuote(
            sendAsset: state.lastSendAssetId!,
            receiveAsset: state.lastReceiveAssetId!,
            amount: state.lastAmount!,
          );
        }
      } else {
        if (!mounted) return;
        state = state.copyWith(millisecondsRemaining: remainingMs);
      }
    });
  }

  void cancelQuote() {
    _log.info(_tag, 'Quote cancelled by user');
    _ttlTimer?.cancel();
    _repositoryFuture.then((r) => r.stopQuote());
    _quoteSub?.cancel();
    _ttlDeadline = null;
    if (!mounted) return;
    state = state.copyWith(
      currentQuote: null,
      activeQuoteId: null,
      ttlMilliseconds: null,
      millisecondsRemaining: null,
    );
  }

  Future<Either<String, String>> confirmSwap() async {
    _log.info(
      _tag,
      'User confirmed swap — stopping quote stream and proceeding',
    );

    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _ttlDeadline = null;

    final repository = await _repositoryFuture;
    repository.stopQuote();

    if (!mounted) {
      _log.warning(_tag, 'confirmSwap: controller disposed before starting');
      return Either.left('Controller disposed');
    }
    final quote = state.currentQuote?.quote;
    if (quote == null) {
      _log.warning(_tag, 'confirmSwap: no active quote found');
      return Either.left('Nenhum quote ativo');
    }
    _log.debug(_tag, 'Confirming swap with quote id=${quote.quoteId}');
    state = state.copyWith(loading: true, error: null);

    try {
      _log.debug(
        _tag,
        'Executing swap with 60s timeout — quoteId=${quote.quoteId}',
      );
      final result = await Future.any([
        _performSwap(repository, quote.quoteId),
        Future.delayed(const Duration(seconds: 60), () {
          _log.error(
            _tag,
            'Swap confirmation timed out after 60s — quoteId=${quote.quoteId}',
          );
          return Either.left(
                'Timeout: A operação demorou muito. Tente novamente.',
              )
              as Either<String, String>;
        }),
      ]);

      if (!mounted) {
        _log.warning(
          _tag,
          'confirmSwap: controller disposed after swap execution',
        );
        return Either.left('Controller disposed');
      }

      return result.match(
        (err) {
          _log.error(_tag, 'Swap confirmation failed: $err');
          if (!mounted) return Either.left(err);
          state = state.copyWith(
            loading: false,
            error: err,
            currentQuote: null,
            activeQuoteId: null,
            ttlMilliseconds: null,
            millisecondsRemaining: null,
            lastSendAssetId: null,
            lastReceiveAssetId: null,
            lastAmount: null,
            isInverseMarket: null,
            feeAssetId: null,
          );
          return Either.left(err);
        },
        (txid) {
          _log.info(_tag, 'Swap completed successfully — txid: $txid');
          if (!mounted) return Either.right(txid);
          state = state.copyWith(
            loading: false,
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
          return Either.right(txid);
        },
      );
    } catch (e, stackTrace) {
      _log.critical(
        _tag,
        'Unhandled exception during swap confirmation',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return Either.left('Erro inesperado: ${e.toString()}');
      state = state.copyWith(
        loading: false,
        error: 'Erro inesperado: ${e.toString()}',
        currentQuote: null,
        activeQuoteId: null,
        ttlMilliseconds: null,
        millisecondsRemaining: null,
        lastSendAssetId: null,
        lastReceiveAssetId: null,
        lastAmount: null,
        isInverseMarket: null,
        feeAssetId: null,
      );
      return Either.left('Erro inesperado: ${e.toString()}');
    }
  }

  Future<Either<String, String>> _performSwap(
    SwapRepository repository,
    int quoteId,
  ) async {
    _log.debug(_tag, 'Fetching PSET for quoteId=$quoteId');
    final psetRes = await repository.getQuotePset(quoteId).run();
    if (!mounted) {
      _log.warning(
        _tag,
        '_performSwap: controller disposed after fetching PSET',
      );
      return Either.left('Controller disposed');
    }

    return await psetRes.match(
      (err) async {
        _log.error(_tag, 'Failed to get PSET for quoteId=$quoteId: $err');
        if (!mounted) return Either.left(err);
        return Either.left(err);
      },
      (pset) async {
        _log.debug(
          _tag,
          'PSET obtained for quoteId=$quoteId — signing and broadcasting',
        );
        final txidRes =
            await repository
                .signAndBroadcast(quoteId: quoteId, pset: pset)
                .run();
        if (!mounted) {
          _log.warning(
            _tag,
            '_performSwap: controller disposed after signAndBroadcast',
          );
          return Either.left('Controller disposed');
        }
        txidRes.match(
          (err) => _log.error(
            _tag,
            'signAndBroadcast failed for quoteId=$quoteId: $err',
          ),
          (txid) => _log.info(_tag, 'signAndBroadcast succeeded — txid: $txid'),
        );
        return txidRes;
      },
    );
  }

  @override
  void dispose() {
    _log.debug(
      _tag,
      'SwapController disposing — cancelling timers and subscriptions',
    );
    _mounted = false;
    _quoteSub?.cancel();
    _ttlTimer?.cancel();

    _repositoryFuture
        .then((r) {
          r.stopQuote();
          _log.debug(_tag, 'Quote stopped on controller dispose');
        })
        .catchError((e) {
          _log.warning(_tag, 'Error stopping quote on dispose: $e');
        });

    _ttlDeadline = null;
    super.dispose();
  }
}

final swapControllerProvider =
    StateNotifierProvider.autoDispose<SwapController, SwapState>((ref) {
      final repoFuture = ref.watch(swapRepositoryProvider.future);
      final controller = SwapController(repositoryFuture: repoFuture);
      return controller;
    });
