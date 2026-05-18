import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/di/providers/swap_repository_provider.dart';
import 'package:mooze_mobile/features/swap/domain/entities.dart';
import 'package:mooze_mobile/features/swap/data/models.dart';

/// Lifecycle of a quote subscription against the SideSwap stream.
///
/// - [idle]        : no quote, no subscription.
/// - [fetching]    : subscription is open but the first quote hasn't arrived.
/// - [valid]       : a quote is displayed and signable; countdown active.
/// - [refreshing]  : the displayed quote's TTL hit zero, but we keep the
///                   numbers visible (faded) while we wait for the next
///                   stream push to promote into a fresh cycle.
/// - [stale]       : we've been [refreshing] long enough that no new push
///                   arrived — surface a manual retry to the user.
enum QuoteStatus { idle, fetching, valid, refreshing, stale }

/// Stable error categories for swap failures, decoupled from user-facing copy
enum SwapErrorCode {
  noLiquidity,
  insufficientBalance,
  utxoBusy,
  noActiveQuote,
  timeout,
  unexpected,
  upstream,
}

/// Locale-agnostic swap error payload — UI calls [localize] to render it
class SwapError {
  final SwapErrorCode code;
  final String? rawMessage;
  final int? available;
  final int? required;

  const SwapError({
    required this.code,
    this.rawMessage,
    this.available,
    this.required,
  });

  String localize(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (code) {
      case SwapErrorCode.noLiquidity:
        return t.swap_no_liquidity_body;
      case SwapErrorCode.insufficientBalance:
        if (available != null && required != null) {
          return t.swap_error_insufficient_balance_detailed(
            available!,
            required!,
          );
        }
        return t.swap_insufficient_balance;
      case SwapErrorCode.utxoBusy:
        return t.swap_error_processing;
      case SwapErrorCode.noActiveQuote:
        return t.swap_error_no_active_quote;
      case SwapErrorCode.timeout:
        return t.swap_error_timeout;
      case SwapErrorCode.unexpected:
        return t.swap_error_unexpected(rawMessage ?? '');
      case SwapErrorCode.upstream:
        return rawMessage ?? t.swap_error_unexpected('');
    }
  }
}

class SwapState {
  /// `true` while a confirmation/sign-and-broadcast is in flight. Separate
  /// from the quote-lifecycle [status] because they're orthogonal: the
  /// quote can be valid while we're loading the swap submission.
  final bool loading;
  final List<SideswapAsset> assets;
  final List<SideswapMarket> markets;
  final QuoteResponse? currentQuote;
  final SwapError? error;
  final int? activeQuoteId;
  final int? ttlMilliseconds;
  final int? millisecondsRemaining;
  final String? lastSendAssetId;
  final String? lastReceiveAssetId;
  final BigInt? lastAmount;
  final bool? isInverseMarket;
  final String? feeAssetId;
  final QuoteStatus status;

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
    this.status = QuoteStatus.idle,
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
    SwapError? error,
    int? activeQuoteId,
    int? ttlMilliseconds,
    int? millisecondsRemaining,
    String? lastSendAssetId,
    String? lastReceiveAssetId,
    BigInt? lastAmount,
    bool? isInverseMarket,
    String? feeAssetId,
    QuoteStatus? status,
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
    status: status ?? this.status,
  );

  static const initial = SwapState(loading: false, assets: [], markets: []);
}

class SwapController extends StateNotifier<SwapState> {
  final _log = AppLoggerService();
  static const _tag = 'Swap';

  // SideSwap quote_ids carry a ~40s server-side TTL, but for a tighter
  // confirmation UX we cap the displayed countdown at 15s. If the server
  // ever returns a shorter TTL we honor that instead.
  static const int _maxDisplayTtlMs = 15000;

  // While in [QuoteStatus.refreshing], how long we wait for the next
  // stream push before giving up and showing the user an explicit retry.
  static const int _staleAfterRefreshingMs = 8000;

  Timer? _staleTimer;

  Future<void> resetQuote() async {
    _log.debug(_tag, 'Resetting quote state');
    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _staleTimer?.cancel();
    _ttlTimer = null;
    _quoteSub = null;
    _staleTimer = null;
    _ttlDeadline = null;
    final repository = await _repositoryFuture;
    repository.stopQuote();
    if (!mounted) return;
    // copyWith treats null as "keep existing" via `?? this.x`, so passing
    // nulls cannot clear transient fields. Construct SwapState directly to
    // truly invalidate the session.
    state = SwapState(
      loading: false,
      assets: state.assets,
      markets: state.markets,
      status: QuoteStatus.idle,
    );
  }

  Future<void> forceReconnectAndReset() async {
    _log.warning(
      _tag,
      'Forcing WebSocket reconnect and resetting all swap state',
    );
    _ttlTimer?.cancel();
    _staleTimer?.cancel();
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

    final upstreamErr = assetsRes.match(
      (l) => l,
      (_) => marketsRes.match((l2) => l2, (_) => null),
    );
    state = state.copyWith(
      loading: false,
      assets: assetsRes.getOrElse((_) => []),
      markets: marketsRes.getOrElse((_) => []),
      error:
          upstreamErr != null
              ? SwapError(
                code: SwapErrorCode.upstream,
                rawMessage: upstreamErr,
              )
              : null,
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
    _quoteSub = null;
    _ttlTimer?.cancel();
    _ttlTimer = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    _ttlDeadline = null;
    // Reset transient quote fields and seed the user's intent so the
    // bottom sheet can render the requested asset pair + amount while the
    // first quote is in flight.
    state = SwapState(
      loading: true,
      assets: state.assets,
      markets: state.markets,
      lastSendAssetId: sendAsset,
      lastReceiveAssetId: receiveAsset,
      lastAmount: amount,
      status: QuoteStatus.fetching,
    );

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
      _log.error(
        _tag,
        'Internal normalization mismatch: utxoAsset=$utxoAsset != sendAsset=$sendAsset',
      );
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: SwapError(
          code: SwapErrorCode.unexpected,
          rawMessage:
              'Internal normalization mismatch (utxo=$utxoAsset, send=$sendAsset)',
        ),
      );
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
        (_) => utxosRes.match((l2) => l2, (_) => 'Unexpected error'),
      );
      _log.error(_tag, 'Failed to get address or UTXOs: $err');
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: SwapError(code: SwapErrorCode.upstream, rawMessage: err),
      );
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
        state = state.copyWith(
          loading: false,
          error: SwapError(code: SwapErrorCode.upstream, rawMessage: err),
        );
      },
      (stream) {
        _quoteSub = stream.listen((quote) {
          if (!mounted) return;
          final rawMsg = quote.error?.errorMessage;
          SwapError? swapErr;

          if (rawMsg != null) {
            final lower = rawMsg.toLowerCase();
            if (lower.contains('invalid utxo') ||
                lower.contains('unknown utxo') ||
                lower.contains('wait for wallet sync')) {
              swapErr = const SwapError(code: SwapErrorCode.utxoBusy);
            } else if (lower.contains('no matching orders') ||
                lower.contains('matching orders')) {
              swapErr = const SwapError(code: SwapErrorCode.noLiquidity);
            } else {
              swapErr = SwapError(
                code: SwapErrorCode.upstream,
                rawMessage: rawMsg,
              );
            }
          }

          if (swapErr == null && quote.lowBalance != null) {
            final lb = quote.lowBalance!;
            final totalFees = lb.fixedFee + lb.serverFee;
            swapErr = SwapError(
              code: SwapErrorCode.insufficientBalance,
              available: lb.available,
              required: lb.baseAmount + totalFees,
            );
          }

          final rawTtlMs = quote.quote?.ttl;
          // Cap displayed TTL — honor a shorter server TTL but clamp any
          // longer one down to _maxDisplayTtlMs so the confirmation
          // countdown stays tight.
          final ttlMs = rawTtlMs == null
              ? null
              : (rawTtlMs > _maxDisplayTtlMs ? _maxDisplayTtlMs : rawTtlMs);
          final newQuote = quote.quote;
          final prevQuote = state.currentQuote?.quote;

          // SideSwap streams a fresh quote_id every ~3s on the same
          // subscription (~40s TTL per quote_id). While we're still inside
          // the locked TTL window of the first quote of this cycle, treat
          // every push as a rolling refresh — silently adopt the latest
          // quote_id for signing fallback, but DO NOT replace the displayed
          // quote, reset the countdown, or surface rate drift to the UI.
          // The displayed amounts and timer stay anchored to the locked
          // quote until its TTL naturally expires; the next push after
          // expiry starts a fresh cycle. Works uniformly for stable pegs
          // and volatile pairs.
          final isWithinLockWindow =
              _ttlDeadline != null && DateTime.now().isBefore(_ttlDeadline!);
          final isRollingRefresh = swapErr == null &&
              newQuote != null &&
              prevQuote != null &&
              isWithinLockWindow &&
              state.status == QuoteStatus.valid;

          // ── Rolling refresh ───────────────────────────────────────
          // SideSwap rotates the quote_id every ~3s on the same
          // subscription. While the displayed quote's TTL is still
          // alive, treat the push as a silent renewal — only the
          // signable id moves forward, everything else stays anchored.
          if (isRollingRefresh) {
            if (!mounted) return;
            state = state.copyWith(activeQuoteId: newQuote.quoteId);
            return;
          }

          // ── Promotion from `refreshing` ───────────────────────────
          // Our soft-expiry handler left displayedQuote on screen but
          // flipped status to `refreshing`. The first push after that
          // becomes the new locked quote and we re-arm the countdown.
          final isPromotingFromRefreshing =
              swapErr == null &&
              newQuote != null &&
              state.status == QuoteStatus.refreshing;

          if (isPromotingFromRefreshing) {
            _staleTimer?.cancel();
            _staleTimer = null;
            if (ttlMs != null) {
              _ttlDeadline = DateTime.now().add(
                Duration(milliseconds: ttlMs),
              );
            }
            _log.debug(
              _tag,
              'Promoting refreshed quote — id: ${newQuote.quoteId}, '
              'ttl: ${ttlMs}ms',
            );
            if (!mounted) return;
            state = state.copyWith(
              loading: false,
              currentQuote: quote,
              activeQuoteId: newQuote.quoteId,
              ttlMilliseconds: ttlMs ?? state.ttlMilliseconds,
              millisecondsRemaining: ttlMs,
              isInverseMarket: isInverse,
              feeAssetId: feeAsset,
              status: QuoteStatus.valid,
              error: null,
            );
            _startTtlCountdown();
            return;
          }

          // ── First quote of a cycle / error / unrelated push ──────
          final shouldStartTimer = _ttlDeadline == null && ttlMs != null;
          if (ttlMs != null) {
            _ttlDeadline = DateTime.now().add(Duration(milliseconds: ttlMs));
          }

          if (swapErr != null) {
            _log.warning(
              _tag,
              'Quote stream received error: code=${swapErr.code}, raw=$rawMsg',
            );
          } else if (newQuote != null) {
            _log.debug(
              _tag,
              'Quote update — id: ${newQuote.quoteId}, '
              'baseAmount: ${newQuote.baseAmount} sats, '
              'quoteAmount: ${newQuote.quoteAmount} sats, '
              'ttl: ${ttlMs}ms',
            );
          }

          if (!mounted) return;
          final nextStatus = swapErr != null
              ? state.status // keep prior status; error is surfaced separately
              : newQuote != null
                  ? QuoteStatus.valid
                  : state.status;
          state = state.copyWith(
            loading: false,
            currentQuote: quote,
            error: swapErr,
            activeQuoteId: newQuote?.quoteId,
            ttlMilliseconds: ttlMs ?? state.ttlMilliseconds,
            lastSendAssetId: sendAsset,
            lastReceiveAssetId: receiveAsset,
            lastAmount: amount,
            isInverseMarket: isInverse,
            feeAssetId: feeAsset,
            status: nextStatus,
          );
          if (shouldStartTimer) {
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
          'Quote TTL expired — entering refreshing, awaiting next push',
        );
        if (!mounted) return;
        // Soft expiry: KEEP the displayed quote on screen and flip
        // status to `refreshing`. The bottom sheet will fade the card,
        // disable confirm, and shimmer the timer. The next stream push
        // promotes into a fresh cycle. If no push arrives within
        // [_staleAfterRefreshingMs], we fall back to `stale` so the
        // user gets an explicit retry.
        state = state.copyWith(
          millisecondsRemaining: 0,
          status: QuoteStatus.refreshing,
        );
        _staleTimer?.cancel();
        _staleTimer = Timer(
          const Duration(milliseconds: _staleAfterRefreshingMs),
          () {
            if (!mounted) return;
            if (state.status != QuoteStatus.refreshing) return;
            _log.warning(
              _tag,
              'Quote refresh stalled — surfacing manual retry',
            );
            state = state.copyWith(status: QuoteStatus.stale);
          },
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(millisecondsRemaining: remainingMs);
      }
    });
  }

  /// Re-open the subscription with the current send/receive/amount.
  ///
  /// Called from:
  /// - the bottom sheet's timer chip tap (user wants a fresher quote)
  /// - the stale-state retry button
  /// - any other "give me a new quote" affordance
  Future<void> requestFreshQuote() async {
    final sendId = state.lastSendAssetId;
    final receiveId = state.lastReceiveAssetId;
    final amount = state.lastAmount;
    if (sendId == null || receiveId == null || amount == null ||
        amount <= BigInt.zero) {
      _log.warning(_tag, 'requestFreshQuote: missing context — aborting');
      return;
    }
    _log.info(_tag, 'Manual quote refresh requested');
    await resetQuote();
    if (!mounted) return;
    await startQuote(
      sendAsset: sendId,
      receiveAsset: receiveId,
      amount: amount,
    );
  }

  /// If the currently-displayed quote is about to die (remaining TTL
  /// under [thresholdMs]), preempt by transitioning to `refreshing`
  /// immediately so the bottom sheet doesn't show a 1–2 second "expired"
  /// flicker right after opening. The subscription is left running; the
  /// next push promotes naturally.
  ///
  /// Called by the bottom sheet on first build.
  void preemptIfLowTtl({int thresholdMs = 5000}) {
    if (state.status != QuoteStatus.valid) return;
    final remaining = state.millisecondsRemaining ?? 0;
    if (remaining >= thresholdMs) return;
    _log.debug(
      _tag,
      'Preempting low-TTL quote (${remaining}ms remaining) → refreshing',
    );
    _ttlTimer?.cancel();
    _ttlTimer = null;
    _ttlDeadline = null;
    if (!mounted) return;
    state = state.copyWith(
      millisecondsRemaining: 0,
      status: QuoteStatus.refreshing,
    );
    _staleTimer?.cancel();
    _staleTimer = Timer(
      const Duration(milliseconds: _staleAfterRefreshingMs),
      () {
        if (!mounted) return;
        if (state.status != QuoteStatus.refreshing) return;
        state = state.copyWith(status: QuoteStatus.stale);
      },
    );
  }

  void cancelQuote() {
    _log.info(_tag, 'Quote cancelled by user');
    _ttlTimer?.cancel();
    _staleTimer?.cancel();
    _repositoryFuture.then((r) => r.stopQuote());
    _quoteSub?.cancel();
    _ttlDeadline = null;
    if (!mounted) return;
    state = state.copyWith(status: QuoteStatus.idle);
  }

  Future<Either<SwapError, String>> confirmSwap() async {
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
      return Either.left(
        const SwapError(
          code: SwapErrorCode.upstream,
          rawMessage: 'Controller disposed',
        ),
      );
    }
    final quote = state.currentQuote?.quote;
    final signingQuoteId = state.activeQuoteId ?? quote?.quoteId;
    if (quote == null || signingQuoteId == null) {
      _log.warning(_tag, 'confirmSwap: no active quote found');
      return Either.left(const SwapError(code: SwapErrorCode.noActiveQuote));
    }
    _log.debug(_tag, 'Confirming swap with quote id=$signingQuoteId');
    state = state.copyWith(loading: true, error: null);

    try {
      _log.debug(
        _tag,
        'Executing swap with 60s timeout — quoteId=$signingQuoteId',
      );
      final result = await Future.any([
        _performSwap(repository, signingQuoteId),
        Future.delayed(const Duration(seconds: 60), () {
          _log.error(
            _tag,
            'Swap confirmation timed out after 60s — quoteId=${quote.quoteId}',
          );
          return Either.left(const SwapError(code: SwapErrorCode.timeout))
              as Either<SwapError, String>;
        }),
      ]);

      if (!mounted) {
        _log.warning(
          _tag,
          'confirmSwap: controller disposed after swap execution',
        );
        return Either.left(
          const SwapError(
            code: SwapErrorCode.upstream,
            rawMessage: 'Controller disposed',
          ),
        );
      }

      return result.match(
        (err) {
          _log.error(_tag, 'Swap confirmation failed: ${err.rawMessage}');
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
      final unexpected = SwapError(
        code: SwapErrorCode.unexpected,
        rawMessage: e.toString(),
      );
      if (!mounted) return Either.left(unexpected);
      state = state.copyWith(
        loading: false,
        error: unexpected,
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
      return Either.left(unexpected);
    }
  }

  Future<Either<SwapError, String>> _performSwap(
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
      return Either.left(
        const SwapError(
          code: SwapErrorCode.upstream,
          rawMessage: 'Controller disposed',
        ),
      );
    }

    return await psetRes.match(
      (err) async {
        _log.error(_tag, 'Failed to get PSET for quoteId=$quoteId: $err');
        return Either.left(
          SwapError(code: SwapErrorCode.upstream, rawMessage: err),
        );
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
          return Either.left(
            const SwapError(
              code: SwapErrorCode.upstream,
              rawMessage: 'Controller disposed',
            ),
          );
        }
        return txidRes.match(
          (err) {
            _log.error(
              _tag,
              'signAndBroadcast failed for quoteId=$quoteId: $err',
            );
            return Either.left(
              SwapError(code: SwapErrorCode.upstream, rawMessage: err),
            );
          },
          (txid) {
            _log.info(_tag, 'signAndBroadcast succeeded — txid: $txid');
            return Either.right(txid);
          },
        );
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
    _staleTimer?.cancel();

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
