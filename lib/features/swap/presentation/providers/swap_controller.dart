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
    if (send == null || receive == null || send == 0) return null;
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

  // Upper bound on how long [QuoteStatus.fetching] is allowed to last
  // before we declare the request lost. Belt-and-suspenders against:
  //  - WebSocket dropping during/after `start_quotes` send (the server
  //    never registers the subscription, no quote ever returns),
  //  - SideswapService's `_isQuoteInProgress` lock being released
  //    early by stale quote emissions, defeating its own 8s timeout,
  //  - any other path that prevents a matching emission from arriving.
  static const int _fetchingTimeoutMs = 10000;

  // Connection-error / timeout auto-retry policy. The WebSocket layer
  // already reconnects on its own; we just need to stop surfacing
  // transient transport errors to the user while that's happening.
  // Each retry replays the full `startQuote` (fresh UTXOs / receive
  // address / `start_quotes` send) with the same user intent.
  // Backoff schedule is `[1s, 2s, 3s]` — after `_maxStartupRetries`
  // failures we give up and surface the error so the user can decide.
  // Three retries covers WS reconnect windows of ~30-40s, which is the
  // observed worst case before the underlying transport recovers.
  static const int _maxStartupRetries = 5;

  Timer? _staleTimer;
  Timer? _fetchingWatchdog;
  Timer? _startupRetryTimer;
  int _consecutiveStartupTimeouts = 0;

  // Generation counter for in-flight [startQuote] invocations.
  // Each invocation captures the current value at its synchronous
  // entry, then re-checks after every `await`. If a newer invocation
  // has incremented the counter in the meantime, the older one
  // aborts before sending an outdated `start_quotes` to the server.
  //
  // Why this exists:
  //   The user can trigger `startQuote` faster than the preflight
  //   completes — typing into the amount field, switching the asset
  //   pair, toggling fiat mode, manual refresh, the auto-retry timer,
  //   and `loadMetadata` all funnel here. Each invocation does an
  //   `await getNewAddress()` and `await selectUtxos()` between the
  //   token-free entry and the actual `repository.startQuote()` send.
  //   With nothing serializing concurrent invocations, two of them
  //   interleave: the older one wins the race to `repository.startQuote()`,
  //   sets the service-side `_isQuoteInProgress` lock with its own
  //   `(base,quote,amount)`, and when the newer one finally calls
  //   `repository.startQuote()` the lock is held so the SideSwap
  //   service drops the call on the floor — no `start_quotes` is sent
  //   for the user's latest intent. Controller installs a listener
  //   for that latest intent, no matching emission ever arrives,
  //   watchdog trips at 10s, user sees infinite shimmer.
  int _startQuoteToken = 0;

  Future<void> resetQuote() async {
    _log.debug(_tag, 'Resetting quote state');
    _ttlTimer?.cancel();
    _quoteSub?.cancel();
    _staleTimer?.cancel();
    _fetchingWatchdog?.cancel();
    _startupRetryTimer?.cancel();
    _ttlTimer = null;
    _quoteSub = null;
    _staleTimer = null;
    _fetchingWatchdog = null;
    _startupRetryTimer = null;
    _consecutiveStartupTimeouts = 0;
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
    _fetchingWatchdog?.cancel();
    _fetchingWatchdog = null;
    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;
    _consecutiveStartupTimeouts = 0;
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
    // When `true`, the displayed quote (`state.currentQuote`) stays on
    // screen while we open a new subscription — status transitions to
    // [QuoteStatus.refreshing] rather than wiping to
    // [QuoteStatus.fetching]. The UI fades the deal card to 55%
    // opacity (matching the soft-expiry path) instead of replacing
    // values with shimmer. The first matching emission promotes
    // through the existing `refreshing → valid` listener path.
    //
    // Used by manual refresh (e.g. user tapping the expiration
    // indicator). For the initial request and after errors, leave
    // this `false` so the user sees a fresh-fetch state.
    bool preserveDisplayedQuote = false,
    // Internal — set by the auto-retry timer when re-issuing a failed
    // startup attempt. Public callers should leave this `false` so each
    // user-initiated fetch begins with a fresh retry budget. When
    // `true`, [_consecutiveStartupTimeouts] is preserved so the backoff
    // strategy can escalate across attempts.
    bool isAutomaticRetry = false,
  }) async {
    // Capture the token synchronously at function entry, BEFORE any
    // `await`. Any later invocation will increment `_startQuoteToken`
    // synchronously at its own entry, so the post-await checks below
    // can detect that this invocation has been superseded.
    final myToken = ++_startQuoteToken;
    _log.info(
      _tag,
      'Starting quote (token=$myToken) — send: $sendAsset, '
      'receive: $receiveAsset, amount: $amount sats, '
      'preserveDisplayed: $preserveDisplayedQuote, '
      'autoRetry: $isAutomaticRetry',
    );
    final repository = await _repositoryFuture;
    if (!mounted) return;
    if (myToken != _startQuoteToken) {
      _log.debug(
        _tag,
        'startQuote token=$myToken superseded by '
        '$_startQuoteToken — aborting at _repositoryFuture',
      );
      return;
    }
    _quoteSub?.cancel();
    _quoteSub = null;
    _ttlTimer?.cancel();
    _ttlTimer = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    _fetchingWatchdog?.cancel();
    _fetchingWatchdog = null;
    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;
    // Reset the auto-retry budget for any non-retry entry into
    // startQuote — typing-debounced refetches, manual swap clicks,
    // resetQuote-then-startQuote — so each user-initiated attempt
    // starts with the full budget. The retry path passes
    // `isAutomaticRetry: true` to preserve the counter across
    // backoff attempts.
    if (!isAutomaticRetry) {
      _consecutiveStartupTimeouts = 0;
    }
    _ttlDeadline = null;
    // Hygiene: tell SideSwap to stop the prior subscription before we
    // open a new one. The controller's listener filter is the actual
    // correctness guard, but explicitly stopping reduces the volume of
    // orphan emissions we'd otherwise be discarding.
    repository.stopQuote();

    // The soft path is only meaningful when we actually have a quote
    // to keep visible. If `preserveDisplayedQuote` was requested but
    // there's nothing on screen yet, fall through to the hard reset
    // so the UI doesn't end up in an awkward "refreshing nothing"
    // state.
    final canSoftRefresh =
        preserveDisplayedQuote && state.currentQuote?.quote != null;

    if (canSoftRefresh) {
      // Keep displayed values intact; transition to `refreshing` so
      // the deal card fades but doesn't unmount. Stale fallback fires
      // if no matching emission lands within
      // [_staleAfterRefreshingMs].
      state = state.copyWith(
        loading: false,
        lastSendAssetId: sendAsset,
        lastReceiveAssetId: receiveAsset,
        lastAmount: amount,
        status: QuoteStatus.refreshing,
        millisecondsRemaining: 0,
        error: null,
      );
      _staleTimer = Timer(
        const Duration(milliseconds: _staleAfterRefreshingMs),
        () {
          if (!mounted) return;
          if (state.status != QuoteStatus.refreshing) return;
          _log.warning(
            _tag,
            'Soft-refresh stalled — surfacing manual retry',
          );
          state = state.copyWith(status: QuoteStatus.stale);
        },
      );
    } else {
      // Hard path: full reset to `fetching` + shimmer. Used for the
      // first quote of a session and for recovery from idle/error.
      state = SwapState(
        loading: true,
        assets: state.assets,
        markets: state.markets,
        lastSendAssetId: sendAsset,
        lastReceiveAssetId: receiveAsset,
        lastAmount: amount,
        status: QuoteStatus.fetching,
      );

      // Arm the fetching watchdog. If a matching emission lands the
      // listener cancels it; otherwise it fires at
      // [_fetchingTimeoutMs] and routes through the shared retry
      // helper — same backoff budget as transient stream errors, so
      // the UI stays in shimmer until the budget is exhausted instead
      // of flashing an error the user just has to retry manually.
      _fetchingWatchdog = Timer(
        const Duration(milliseconds: _fetchingTimeoutMs),
        () {
          if (!mounted) return;
          if (state.status != QuoteStatus.fetching) return;
          _log.warning(
            _tag,
            'Fetching watchdog tripped — no matching quote within '
            '${_fetchingTimeoutMs}ms.',
          );
          _scheduleStartupRetryOrSurface(
            sendAsset: sendAsset,
            receiveAsset: receiveAsset,
            amount: amount,
            reason: 'fetching watchdog tripped',
          );
        },
      );
    }

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
      if (myToken != _startQuoteToken) {
        _log.debug(
          _tag,
          'startQuote token=$myToken superseded — aborting after getMarkets',
        );
        return;
      }
      if (marketsRes.isRight()) {
        normalizedParams = repository.normalizeSwapParams(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
        );
      }
    }

    if (normalizedParams == null) {
      // `getMarkets()` couldn't repopulate the list — almost always
      // means the WebSocket is currently down. We can't open a fresh
      // subscription right now, but a previously-opened subscription
      // for the same pair / amount may still be emitting matching
      // quotes on the shared broadcast stream (SideSwap pushes a
      // rolling quote_id every ~3s). Attach a permissive listener so
      // those in-flight emissions can be adopted as the active quote
      // — without it, valid quotes flow past the controller and the
      // user stays stuck in shimmer / retry loops.
      //
      // We still schedule the auto-retry so that if no emission
      // lands, we eventually re-attempt the full subscription path
      // (the retry will tear down this permissive listener and
      // either succeed via a fresh `start_quotes` or attach another
      // permissive listener if markets are still empty).
      _log.warning(
        _tag,
        'Trading pair not found even after reloading markets — '
        'attaching permissive listener and scheduling retry. '
        'send=$sendAsset, receive=$receiveAsset',
      );
      if (!mounted) return;
      _quoteSub = repository.quoteStream.listen((q) {
        _handleQuoteEmission(
          q,
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
          amount: amount,
        );
      });
      _scheduleStartupRetryOrSurface(
        sendAsset: sendAsset,
        receiveAsset: receiveAsset,
        amount: amount,
        reason: 'markets reload failed',
      );
      return;
    }

    final baseAsset = normalizedParams.baseAsset;
    final quoteAsset = normalizedParams.quoteAsset;
    final direction = normalizedParams.direction;
    final assetType = normalizedParams.assetType;

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
    // The two awaits above can take long enough (UTXO selection
    // sometimes 100–500 ms on slow devices) that a later
    // `startQuote` invocation has fully landed by the time we resume.
    // Abort here so we never reach the synchronous
    // `repository.startQuote(...)` below — that would set the
    // SideSwap service's `_isQuoteInProgress` lock for our stale
    // intent and silently block the newer invocation's `start_quotes`
    // from being sent, leaving the UI stuck in shimmer.
    if (myToken != _startQuoteToken) {
      _log.debug(
        _tag,
        'startQuote token=$myToken superseded — '
        'aborting after address/utxo selection',
      );
      return;
    }
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
      'assetType=$assetType, direction=$direction',
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
          _handleQuoteEmission(
            quote,
            sendAsset: sendAsset,
            receiveAsset: receiveAsset,
            amount: amount,
          );
        });
      },
    );
  }

  /// Process one emission from the shared SideSwap broadcast stream.
  ///
  /// Called from two attachment points:
  /// - the per-request `stream.listen` installed after a successful
  ///   `start_quotes` send, and
  /// - the permissive `repository.quoteStream` listener installed by
  ///   the markets-reload-failed branch, where we couldn't open a new
  ///   subscription but want to adopt any matching in-flight emission.
  ///
  /// The identity filter is intentionally permissive on base/quote
  /// ordering: the user's intent is `sendAsset` → `receiveAsset`, but
  /// SideSwap may have a market in either direction. We accept any
  /// emission whose `{baseAssetId, quoteAssetId}` set equals
  /// `{sendAsset, receiveAsset}` and whose `requestedAmount` matches
  /// the user's amount. The emission itself dictates `isInverse` and
  /// `feeAsset` for this cycle, derived from `baseAssetId == sendAsset`
  /// (direct) vs `baseAssetId == receiveAsset` (inverse).
  void _handleQuoteEmission(
    QuoteResponse quote, {
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
  }) {
    if (!mounted) return;

    // ── Permissive subscription-identity filter ─────────────────────
    // `sideswapService.quoteResponseStream` is a single broadcast
    // firehose that receives EVERY quote message on the SideSwap WS
    // — including emissions from previous subscriptions whose
    // `quote_sub_id` we never explicitly stopped. Without this guard
    // the controller would happily process a quote answering an old
    // request (different pair or different amount) as if it were the
    // current one.
    //
    // We accept an emission if (a) its requested amount matches and
    // (b) its asset pair equals {sendAsset, receiveAsset} in either
    // order. The directionality (`isInverse`) and fee asset are then
    // derived from the emission's own `baseAssetId` — that way an
    // emission from a previously-opened subscription can still drive
    // the active cycle even if `normalizeSwapParams` is unavailable.
    final emissionBase = quote.baseAssetId;
    final emissionQuote = quote.quoteAssetId;
    final pairMatches = emissionBase != null &&
        emissionQuote != null &&
        ((emissionBase == sendAsset && emissionQuote == receiveAsset) ||
            (emissionBase == receiveAsset && emissionQuote == sendAsset));
    final amountMatches = quote.requestedAmount == amount.toInt();
    if (!pairMatches || !amountMatches) {
      _log.debug(
        _tag,
        'Dropped stale stream emission: pair='
            '${quote.baseAssetId}/${quote.quoteAssetId}, '
            'amount=${quote.requestedAmount} '
            '(intent: $sendAsset→$receiveAsset, ${amount.toInt()})',
      );
      return;
    }

    final emissionIsInverse = emissionBase != sendAsset;
    final emissionFeeAsset = emissionBase;

    // A matching emission is in flight — the fetching watchdog is no
    // longer needed and any pending startup retry should be cancelled
    // (we no longer need to re-issue the subscription; the current
    // broadcast stream is producing the quote we wanted).
    _fetchingWatchdog?.cancel();
    _fetchingWatchdog = null;
    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;

    final rawMsg = quote.error?.errorMessage;
    SwapError? swapErr;

    if (rawMsg != null) {
      final lower = rawMsg.toLowerCase();

      // ── Transient transport errors ────────────────────────────
      // Two related classes of error end up here:
      //   • "Tempo limite excedido…" — SideswapService's 8 s
      //     watchdog firing because no quote response arrived
      //     (typically caused by a flaky / reconnecting WS).
      //   • "Erro de conexão…" — synthetic emission when
      //     `ensureConnection()` couldn't bring the WS back up.
      // The WebSocket layer is already retrying its connect on
      // its own. We just need to stop surfacing these to the
      // user while that's happening:
      //   - If a working subscription exists (status valid /
      //     refreshing), the next stream push will recover us
      //     naturally — suppress silently.
      //   - Otherwise (still in `fetching`), attempt a few
      //     automatic retries with exponential backoff before
      //     giving up. The UI stays in shimmer the whole time
      //     so the user doesn't see error flashes for what is
      //     essentially a reconnect cycle.
      final isTransient = lower.contains('tempo limite') ||
          lower.contains('timeout') ||
          lower.contains('timed out') ||
          lower.contains('tiempo límite') ||
          lower.contains('tiempo agotado') ||
          lower.contains('erro de conexão') ||
          lower.contains('connection error') ||
          lower.contains('disconnected');
      if (isTransient) {
        final hasWorkingSubscription = state.status == QuoteStatus.valid ||
            state.status == QuoteStatus.refreshing;
        if (hasWorkingSubscription) {
          _log.debug(
            _tag,
            'Suppressed recoverable upstream transient: $rawMsg',
          );
          return;
        }
        // No working subscription — route through the shared
        // auto-retry helper (same budget as the watchdog path
        // and the markets-reload-failed path).
        _scheduleStartupRetryOrSurface(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
          amount: amount,
          reason: 'stream transient: $rawMsg',
        );
        return;
      } else if (lower.contains('invalid utxo') ||
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
    final isPromotingFromRefreshing = swapErr == null &&
        newQuote != null &&
        state.status == QuoteStatus.refreshing;

    if (isPromotingFromRefreshing) {
      _staleTimer?.cancel();
      _staleTimer = null;
      // Successful promotion ends the auto-retry cycle.
      _consecutiveStartupTimeouts = 0;
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
        isInverseMarket: emissionIsInverse,
        feeAssetId: emissionFeeAsset,
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
    // A successful first quote ends the auto-retry cycle.
    if (swapErr == null && newQuote != null) {
      _consecutiveStartupTimeouts = 0;
    }
    // An error during `fetching` means we never received a first
    // successful quote — staying in `fetching` would leave the
    // UI in shimmer alongside the error banner. Exit to `idle`
    // so the error card stands alone. For other statuses (valid /
    // refreshing) we already have something on screen, so a
    // transient error doesn't reset the displayed quote.
    final QuoteStatus nextStatus;
    if (swapErr != null) {
      nextStatus = state.status == QuoteStatus.fetching
          ? QuoteStatus.idle
          : state.status;
    } else if (newQuote != null) {
      nextStatus = QuoteStatus.valid;
    } else {
      nextStatus = state.status;
    }
    state = state.copyWith(
      loading: false,
      currentQuote: quote,
      error: swapErr,
      activeQuoteId: newQuote?.quoteId,
      ttlMilliseconds: ttlMs ?? state.ttlMilliseconds,
      lastSendAssetId: sendAsset,
      lastReceiveAssetId: receiveAsset,
      lastAmount: amount,
      isInverseMarket: emissionIsInverse,
      feeAssetId: emissionFeeAsset,
      status: nextStatus,
    );
    if (shouldStartTimer) {
      _startTtlCountdown();
    }
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

  /// Either schedule an automatic retry of the current `startQuote`
  /// with backoff, or — if the retry budget is exhausted — surface
  /// the failure to the user as a [SwapErrorCode.timeout].
  ///
  /// Three different failure paths funnel through here so the auto-
  /// retry behavior is consistent across them:
  ///
  /// - The quote-stream listener catching a transient transport error
  ///   ("Tempo limite excedido…", "Erro de conexão…").
  /// - The fetching watchdog tripping because no matching emission
  ///   landed within `_fetchingTimeoutMs`.
  /// - `startQuote`'s own preflight failing to normalize the asset
  ///   pair after a markets-reload attempt (typically because the
  ///   WebSocket is down and `getMarkets()` couldn't return).
  ///
  /// In all three cases the user's intent is preserved (we re-issue
  /// `startQuote` with the same send/receive/amount) and the UI stays
  /// in `fetching` shimmer rather than flashing an error banner the
  /// user would just have to dismiss and tap retry on.
  void _scheduleStartupRetryOrSurface({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
    required String reason,
  }) {
    _fetchingWatchdog?.cancel();
    _fetchingWatchdog = null;
    // Intentionally do NOT cancel `_quoteSub` here. We want any
    // currently-attached listener (per-subscription OR the permissive
    // broadcast listener installed by the markets-fail branch) to
    // stay alive during the backoff window — if a matching emission
    // lands before the retry fires, `_handleQuoteEmission` will
    // adopt it and cancel the retry timer. The next call to
    // `startQuote` (from either the retry or a user action) cancels
    // and re-creates the listener cleanly at its preamble.

    if (_consecutiveStartupTimeouts < _maxStartupRetries) {
      _consecutiveStartupTimeouts++;
      final delaySeconds = _consecutiveStartupTimeouts;
      _log.info(
        _tag,
        'Auto-retry $_consecutiveStartupTimeouts/$_maxStartupRetries '
        'in ${delaySeconds}s ($reason)',
      );
      _startupRetryTimer?.cancel();
      _startupRetryTimer = Timer(Duration(seconds: delaySeconds), () {
        if (!mounted) return;
        startQuote(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
          amount: amount,
          isAutomaticRetry: true,
        );
      });
      return;
    }

    _log.warning(
      _tag,
      'Auto-retry budget exhausted after $_consecutiveStartupTimeouts '
      'attempts — surfacing timeout ($reason)',
    );
    _consecutiveStartupTimeouts = 0;
    if (!mounted) return;
    state = state.copyWith(
      loading: false,
      status: QuoteStatus.idle,
      error: const SwapError(code: SwapErrorCode.timeout),
    );
  }

  /// Re-open the subscription with the current send/receive/amount.
  ///
  /// Called from:
  /// - the bottom sheet's timer chip tap (user wants a fresher quote)
  /// - the stale-state retry button
  /// - any other "give me a new quote" affordance
  ///
  /// **Soft vs. hard path:** if a quote is currently displayed,
  /// passes `preserveDisplayedQuote: true` to [startQuote]. The deal
  /// card stays on screen and fades to 55 % opacity (via
  /// [QuoteStatus.refreshing]) until the next matching emission
  /// promotes through to `valid` — same UX as the soft-expiry path.
  /// If there's no displayed quote (e.g. we're recovering from an
  /// error/idle state), we fall back to the full
  /// `resetQuote + startQuote` so the shimmer state correctly signals
  /// "we're fetching from scratch".
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

    final hasDisplayedQuote = state.currentQuote?.quote != null;
    if (hasDisplayedQuote) {
      // Soft path — keep the deal card on screen while fetching.
      await startQuote(
        sendAsset: sendId,
        receiveAsset: receiveId,
        amount: amount,
        preserveDisplayedQuote: true,
      );
      return;
    }

    // No quote to preserve — full reset so the user sees a clean
    // fetch state.
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
    _fetchingWatchdog?.cancel();
    _fetchingWatchdog = null;
    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;
    _consecutiveStartupTimeouts = 0;
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
    _fetchingWatchdog?.cancel();
    _startupRetryTimer?.cancel();

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
