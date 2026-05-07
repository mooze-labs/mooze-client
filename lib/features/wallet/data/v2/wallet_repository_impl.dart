import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../domain/entities/asset.dart';
import '../../../../domain/entities/balance.dart';
import '../../../../domain/entities/broadcast_result.dart';
import '../../../../domain/entities/chain.dart';
import '../../../../domain/entities/fee_estimate.dart';
import '../../../../domain/entities/liquid_utxo.dart';
import '../../../../domain/entities/payment_limits.dart';
import '../../../../domain/entities/peg.dart';
import '../../../../domain/entities/receive_address.dart';
import '../../../../domain/entities/refund.dart';
import '../../../../domain/entities/send_request.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/events/transaction_event.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/transaction_store.dart';
import '../../../../domain/repositories/wallet_repository.dart';
import '../../../../domain/services/bitcoin_wallet_service.dart';
import '../../../../domain/services/lightning_wallet_service.dart';
import '../../../../domain/services/liquid_wallet_service.dart';
import '../../../../domain/services/wallet_service.dart';
import '../../../../shared/clock/clock.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required this.transactionStore,
    required this.liquid,
    required this.bitcoin,
    required this.lightning,
    required this.clock,
    Stream<TransactionEvent>? balanceTriggerStream,
  }) : _balanceTriggerStream = balanceTriggerStream;

  final TransactionStore transactionStore;
  final LiquidWalletService liquid;
  final BitcoinWalletService bitcoin;
  final LightningWalletService lightning;
  final Clock clock;

  /// The orchestrator's merged transaction-event stream. Used by
  /// [watchBalanceFor] to know when balance might have shifted. Optional —
  /// when null, [watchBalanceFor] still emits the current value once on
  /// subscribe and stays open, but only re-emits if the consumer calls
  /// `balanceFor` themselves. Production wiring always supplies this.
  final Stream<TransactionEvent>? _balanceTriggerStream;

  @override
  Stream<List<Transaction>> watchTransactions({ChainFilter? filter}) =>
      transactionStore.watch(filter: filter);

  @override
  Future<Either<Failure, List<Transaction>>> listTransactions(
      {ChainFilter? filter, int? limit}) async {
    final r = await transactionStore.list(filter: filter, limit: limit);
    return r.fold((f) => Left<Failure, List<Transaction>>(f),
        (xs) => Right<Failure, List<Transaction>>(xs));
  }

  @override
  Future<Either<Failure, Balance>> aggregateBalance() async {
    final services = <WalletService>[liquid, bitcoin, lightning];
    final assets = <AssetBalance>[];
    Failure? firstError;

    for (final s in services) {
      if (!s.currentState.isOperational) continue;
      final r = await s.getBalance();
      r.match(
        (f) {
          firstError ??= f;
        },
        (b) => assets.addAll(b.assets),
      );
    }

    if (assets.isEmpty && firstError != null) {
      return Left(firstError!);
    }
    return Right(Balance(assets: assets, snapshotAt: clock.now()));
  }

  // ─────────────────────────────────────────── per-asset API

  @override
  Future<Either<Failure, BigInt>> balanceFor(Asset asset) async {
    final perChain = await _fetchPerChainSnapshots();
    return _resolveAssetFromSnapshots(asset, perChain);
  }

  @override
  Future<Either<Failure, Map<Asset, BigInt>>> balanceMap(
      List<Asset> assets) async {
    final perChain = await _fetchPerChainSnapshots();
    final out = <Asset, BigInt>{};
    Failure? firstFailure;
    for (final a in assets) {
      final r = _resolveAssetFromSnapshots(a, perChain);
      r.match((f) => firstFailure ??= f, (v) => out[a] = v);
    }
    if (out.isEmpty && firstFailure != null) {
      return Left<Failure, Map<Asset, BigInt>>(firstFailure!);
    }
    // Fill assets that weren't resolved (no chain has a balance) with zero —
    // matches legacy `allBalancesProvider` behaviour where missing keys are
    // surfaced as zero rather than absent.
    for (final a in assets) {
      out.putIfAbsent(a, () => BigInt.zero);
    }
    return Right(out);
  }

  @override
  Stream<BigInt> watchBalanceFor(Asset asset) {
    final controller = StreamController<BigInt>();
    Timer? debounce;
    StreamSubscription<TransactionEvent>? sub;
    var disposed = false;

    Future<void> emitNow() async {
      if (disposed) return;
      final r = await balanceFor(asset);
      if (disposed || controller.isClosed) return;
      r.match(
        (_) => controller.add(BigInt.zero),
        (v) => controller.add(v),
      );
    }

    void scheduleEmit() {
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 200), emitNow);
    }

    controller.onListen = () {
      // Initial value on subscribe, then debounced re-emits on tx events.
      unawaited(emitNow());
      final trigger = _balanceTriggerStream;
      if (trigger != null) {
        sub = trigger.listen(
          (_) => scheduleEmit(),
          onError: (_) {/* upstream errors don't kill the balance stream */},
        );
      }
    };

    controller.onCancel = () async {
      disposed = true;
      debounce?.cancel();
      await sub?.cancel();
    };

    return controller.stream;
  }

  // ─────────────────────────────────────────── send / receive (Liquid)
  //
  // All three Liquid methods delegate to the Breez Liquid service
  // (`lightning` here, despite the name — see the docstring on
  // `LightningWalletService`). Failures are folded into the domain
  // [Failure] hierarchy: `ServiceFailure` from the service is preserved
  // unwrapped because it already carries chain + cause + stackTrace.

  @override
  Future<Either<Failure, FeeEstimate>> estimateLiquidSend(
      SendRequest request) async {
    if (request.chain != ChainId.liquid) {
      return Left(ServiceFailure(
        'estimateLiquidSend requires chain == liquid (got: '
        '${request.chain.name})',
        chain: ChainId.liquid,
      ));
    }
    final r = await lightning.estimateFee(request);
    return r.fold(
      (f) => Left<Failure, FeeEstimate>(f),
      (e) => Right<Failure, FeeEstimate>(e),
    );
  }

  @override
  Future<Either<Failure, ReceiveAddress>> liquidReceiveAddress({
    String? assetId,
    String? label,
  }) async {
    final r = await lightning.nextReceiveAddress(
      assetId: assetId,
      label: label,
    );
    return r.fold(
      (f) => Left<Failure, ReceiveAddress>(f),
      (a) => Right<Failure, ReceiveAddress>(a),
    );
  }

  @override
  Future<Either<Failure, BroadcastResult>> sendLiquid(
      SendRequest request) async {
    if (request.chain != ChainId.liquid) {
      return Left(ServiceFailure(
        'sendLiquid requires chain == liquid (got: ${request.chain.name})',
        chain: ChainId.liquid,
      ));
    }
    final r = await lightning.sendOnchain(request);
    return r.fold(
      (f) => Left<Failure, BroadcastResult>(f),
      (b) => Right<Failure, BroadcastResult>(b),
    );
  }

  // ─────────────────────────────────────────── send / receive (Bitcoin)
  //
  // Same shape as Liquid above: validate chain, delegate to the BDK-backed
  // `bitcoin` service, fold ServiceFailure into Failure (subtype
  // relationship preserved — no wrapping).

  @override
  Future<Either<Failure, FeeEstimate>> estimateBitcoinSend(
      SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'estimateBitcoinSend requires chain == bitcoin (got: '
        '${request.chain.name})',
        chain: ChainId.bitcoin,
      ));
    }
    final r = await bitcoin.estimateFee(request);
    return r.fold(
      (f) => Left<Failure, FeeEstimate>(f),
      (e) => Right<Failure, FeeEstimate>(e),
    );
  }

  @override
  Future<Either<Failure, ReceiveAddress>> bitcoinReceiveAddress({
    String? label,
  }) async {
    final r = await bitcoin.nextReceiveAddress(label: label);
    return r.fold(
      (f) => Left<Failure, ReceiveAddress>(f),
      (a) => Right<Failure, ReceiveAddress>(a),
    );
  }

  @override
  Future<Either<Failure, BroadcastResult>> sendBitcoin(
      SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'sendBitcoin requires chain == bitcoin (got: ${request.chain.name})',
        chain: ChainId.bitcoin,
      ));
    }
    final r = await bitcoin.sendOnchain(request);
    return r.fold(
      (f) => Left<Failure, BroadcastResult>(f),
      (b) => Right<Failure, BroadcastResult>(b),
    );
  }

  // ─────────────────────────────────────────── send / receive (Lightning)
  //
  // All three Lightning entry points delegate to the Breez-backed
  // `lightning` service. The service implements both
  // `SpendableLightningService` (prepare/send/createInvoice) and the
  // Liquid spendable surface — the V2 model treats Lightning as a rail
  // on top of the unified Liquid balance, NOT a separate balance domain.

  @override
  Future<Either<Failure, PreparedLightningSend>> prepareLightningSend(
      LightningSendRequest request) async {
    final r = await lightning.prepareSend(request);
    return r.fold(
      (f) => Left<Failure, PreparedLightningSend>(f),
      (p) => Right<Failure, PreparedLightningSend>(p),
    );
  }

  @override
  Future<Either<Failure, BroadcastResult>> sendLightning(
      PreparedLightningSend prepared) async {
    final r = await lightning.sendLightning(prepared);
    return r.fold(
      (f) => Left<Failure, BroadcastResult>(f),
      (b) => Right<Failure, BroadcastResult>(b),
    );
  }

  @override
  Future<Either<Failure, ReceiveAddress>> createLightningInvoice({
    required int amountSat,
    String? description,
    Duration? expiry,
  }) async {
    final r = await lightning.createInvoice(
      amountSat: amountSat,
      description: description,
      expiry: expiry,
    );
    return r.fold(
      (f) => Left<Failure, ReceiveAddress>(f),
      (a) => Right<Failure, ReceiveAddress>(a),
    );
  }

  // ─────────────────────────────────────────── chain metadata

  @override
  Future<Either<Failure, int>> getCurrentBitcoinBlockHeight() async {
    final r = await bitcoin.getBlockHeight();
    return r.fold(
      (f) => Left<Failure, int>(f),
      (h) => Right<Failure, int>(h),
    );
  }

  // ─────────────────────────────────────────── refund surface
  //
  // All refund methods delegate to the Breez-backed lightning service
  // (the SDK exposes refund APIs on the Breez Liquid client; LWK has no
  // refund concept). Errors fold cleanly — `ServiceFailure` is already
  // a `Failure` subtype so no wrapping needed.

  @override
  Future<Either<Failure, List<RefundableSwap>>> listRefundableSwaps() async {
    final r = await lightning.listRefundables();
    return r.fold(
      (f) => Left<Failure, List<RefundableSwap>>(f),
      (xs) => Right<Failure, List<RefundableSwap>>(xs),
    );
  }

  @override
  Future<Either<Failure, MempoolFees>> getRecommendedFees() async {
    final r = await lightning.recommendedFees();
    return r.fold(
      (f) => Left<Failure, MempoolFees>(f),
      (fees) => Right<Failure, MempoolFees>(fees),
    );
  }

  @override
  Future<Either<Failure, PrepareRefundOutcome>> prepareRefund(
      PrepareRefundParams params) async {
    final r = await lightning.prepareRefund(params);
    return r.fold(
      (f) => Left<Failure, PrepareRefundOutcome>(f),
      (o) => Right<Failure, PrepareRefundOutcome>(o),
    );
  }

  @override
  Future<Either<Failure, RefundOutcome>> executeRefund(
      ExecuteRefundParams params) async {
    final r = await lightning.executeRefund(params);
    return r.fold(
      (f) => Left<Failure, RefundOutcome>(f),
      (o) => Right<Failure, RefundOutcome>(o),
    );
  }

  // ─────────────────────────────────────────── swap surface (LWK-backed)
  //
  // Routes to the LWK service. PSET signing + UTXO enumeration are
  // LWK-only because Breez Liquid SDK doesn't expose raw signing /
  // unblinded UTXO listings.

  @override
  Future<Either<Failure, List<LiquidUtxo>>> getLiquidUtxos() async {
    final r = await liquid.getUtxos();
    return r.fold(
      (f) => Left<Failure, List<LiquidUtxo>>(f),
      (xs) => Right<Failure, List<LiquidUtxo>>(xs),
    );
  }

  @override
  Future<Either<Failure, String>> signSwapPset({
    required String pset,
    required String mnemonic,
  }) async {
    final r = await liquid.signSwapPset(pset: pset, mnemonic: mnemonic);
    return r.fold(
      (f) => Left<Failure, String>(f),
      (s) => Right<Failure, String>(s),
    );
  }

  @override
  Future<Either<Failure, String>> getLiquidSwapAddress() async {
    final r = await liquid.getReceiveAddress();
    return r.fold(
      (f) => Left<Failure, String>(f),
      (a) => Right<Failure, String>(a),
    );
  }

  // ─────────────────────────────────────────── payment limits
  //
  // Single normalised shape over Lightning, Liquid, and Bitcoin. Lightning
  // and Liquid go through the LSP-aware Breez service; Bitcoin returns
  // sensible network defaults (BDK has no SDK-level limits API — there is
  // only network dust on the low end and balance on the high end, which
  // is the caller's concern).

  @override
  Future<Either<Failure, PaymentLimits>> fetchLimits(ChainId chain) async {
    switch (chain) {
      case ChainId.lightning:
        final r = await lightning.fetchLightningLimits();
        return r.fold(
          (f) => Left<Failure, PaymentLimits>(f),
          (l) => Right<Failure, PaymentLimits>(PaymentLimits(
            chain: ChainId.lightning,
            sendMinSat: l.minSendSat,
            sendMaxSat: l.maxSendSat,
            receiveMinSat: l.minReceiveSat,
            receiveMaxSat: l.maxReceiveSat,
          )),
        );
      case ChainId.liquid:
        final r = await lightning.fetchOnchainLimits();
        return r.fold(
          (f) => Left<Failure, PaymentLimits>(f),
          (l) => Right<Failure, PaymentLimits>(PaymentLimits(
            chain: ChainId.liquid,
            sendMinSat: l.minSendSat,
            sendMaxSat: l.maxSendSat,
            receiveMinSat: l.minReceiveSat,
            receiveMaxSat: l.maxReceiveSat,
          )),
        );
      case ChainId.bitcoin:
        // BDK has no LSP — limits are network-level only. Dust = 546 sats
        // (post-segwit-output threshold); upper bound is effectively
        // unbounded from the SDK's view (caller gates on balance).
        return Right(const PaymentLimits(
          chain: ChainId.bitcoin,
          sendMinSat: 546,
          sendMaxSat: 0x7FFFFFFFFFFFFFFF,
          receiveMinSat: null,
          receiveMaxSat: null,
        ));
      case ChainId.aggregate:
        return Left(ServiceFailure(
          'fetchLimits requires a specific chain (got: aggregate)',
          chain: chain,
        ));
    }
  }

  // ─────────────────────────────────────────── peg-in / peg-out
  //
  // Cross-stack balance transitions. Peg-in spans both services — Breez
  // allocates a one-time BTC deposit address, BDK builds + signs +
  // broadcasts the funding tx. Peg-out is Breez-end-to-end. All four
  // entry points are stateless: `execute` re-derives state from the
  // canonical request, no opaque prepared tokens round-trip through UI.

  @override
  Future<Either<Failure, PegInQuote>> preparePegIn(PegInRequest request) async {
    final depositResult = await lightning.preparePegInDeposit(
      payerAmountSat: request.payerAmountSat,
    );
    return depositResult.match(
      (f) async => Left<Failure, PegInQuote>(f),
      (deposit) async {
        // Estimate the BDK-side fee for funding the deposit address. We
        // re-use the SendRequest shape so drain semantics + fee-rate
        // override flow through the same validation as a normal Bitcoin
        // send.
        final fundingRequest = SendRequest(
          chain: ChainId.bitcoin,
          destination: deposit.bitcoinAddress,
          amountSat: request.payerAmountSat,
          drain: request.drain,
          feeRateOverrideSatPerVByte: request.feeRateSatPerVByte,
        );
        final feeResult = await bitcoin.estimateFee(fundingRequest);
        return feeResult.fold(
          (f) => Left<Failure, PegInQuote>(f),
          (fee) => Right<Failure, PegInQuote>(PegInQuote(
            bitcoinAddress: deposit.bitcoinAddress,
            payerAmountSat: request.payerAmountSat,
            breezFeesSat: deposit.breezFeesSat,
            bdkFeesSat: fee.absoluteFeeSat,
            totalFeesSat: deposit.breezFeesSat + fee.absoluteFeeSat,
          )),
        );
      },
    );
  }

  @override
  Future<Either<Failure, BroadcastResult>> executePegIn(
      PegInRequest request) async {
    // Allocate a fresh deposit address (Breez addresses are one-time —
    // we can't reuse the prepare-step address). Rest of the orchestration
    // mirrors the prepare path but commits the BDK send.
    final depositResult = await lightning.preparePegInDeposit(
      payerAmountSat: request.payerAmountSat,
    );
    return depositResult.match(
      (f) async => Left<Failure, BroadcastResult>(f),
      (deposit) async {
        final fundingRequest = SendRequest(
          chain: ChainId.bitcoin,
          destination: deposit.bitcoinAddress,
          amountSat: request.payerAmountSat,
          drain: request.drain,
          feeRateOverrideSatPerVByte: request.feeRateSatPerVByte,
        );
        final sendResult = await bitcoin.sendOnchain(fundingRequest);
        return sendResult.fold(
          (f) => Left<Failure, BroadcastResult>(f),
          (b) => Right<Failure, BroadcastResult>(b),
        );
      },
    );
  }

  @override
  Future<Either<Failure, PegOutQuote>> preparePegOut(
      PegOutRequest request) async {
    final r = await lightning.preparePegOut(request);
    return r.fold(
      (f) => Left<Failure, PegOutQuote>(f),
      (q) => Right<Failure, PegOutQuote>(q),
    );
  }

  @override
  Future<Either<Failure, BroadcastResult>> executePegOut(
      PegOutRequest request) async {
    final r = await lightning.executePegOut(request);
    return r.fold(
      (f) => Left<Failure, BroadcastResult>(f),
      (b) => Right<Failure, BroadcastResult>(b),
    );
  }

  // ─────────────────────────────────────────── helpers

  /// Cached-per-call snapshot of each chain service's balance. Avoids
  /// re-hitting a service's SDK 4× when [balanceMap] resolves all assets.
  Future<_PerChainSnapshots> _fetchPerChainSnapshots() async {
    Either<Failure, Balance>? bitcoinSnap;
    Either<Failure, Balance>? liquidSnap;
    Either<Failure, Balance>? lightningSnap;

    final futures = <Future<void>>[];
    if (bitcoin.currentState.isOperational) {
      futures.add(bitcoin.getBalance().then((r) => bitcoinSnap = r));
    }
    if (liquid.currentState.isOperational) {
      futures.add(liquid.getBalance().then((r) => liquidSnap = r));
    }
    if (lightning.currentState.isOperational) {
      futures.add(lightning.getBalance().then((r) => lightningSnap = r));
    }
    await Future.wait(futures);

    return _PerChainSnapshots(
      bitcoin: bitcoinSnap,
      liquid: liquidSnap,
      lightning: lightningSnap,
    );
  }

  /// Walk the asset's `resolutionChains` priority list. First chain that
  /// returns a value (even zero) wins — matches legacy `putIfAbsent`
  /// semantics where Breez "fills" the entry first and LWK only acts as a
  /// fallback when Breez doesn't have it.
  Either<Failure, BigInt> _resolveAssetFromSnapshots(
    Asset asset,
    _PerChainSnapshots snapshots,
  ) {
    Failure? lastError;

    for (final chain in asset.resolutionChains) {
      final snap = snapshots.forChain(chain);
      if (snap == null) continue; // service not operational
      if (snap.isLeft()) {
        snap.match((f) => lastError = f, (_) {});
        continue; // try next priority chain
      }
      final balance = snap.getOrElse((_) => Balance.empty());
      final amount = _extractAssetAmount(balance, asset, chain);
      if (amount != null) {
        return Right<Failure, BigInt>(amount);
      }
    }

    // No chain reported the asset. Legacy treats this as zero (not error) —
    // matches `allBalancesProvider`'s `?? BigInt.zero` lookup.
    if (lastError != null && _everyChainErrored(asset, snapshots)) {
      return Left<Failure, BigInt>(lastError!);
    }
    return Right<Failure, BigInt>(BigInt.zero);
  }

  /// Pull the amount for [asset] from a chain-specific balance snapshot.
  /// Returns null when the asset is not represented on that chain (so the
  /// caller can try the next priority chain).
  BigInt? _extractAssetAmount(
      Balance balance, Asset asset, ChainId fromChain) {
    if (asset.isNativeBitcoin) {
      // BTC: sum entries on the bitcoin chain. The V2 BDK service emits a
      // single asset with `assetId == null`; if multiple were ever emitted
      // we'd still want to sum them. Lightning's `assetId == null` BTC entry
      // is intentionally NOT routed here — see `Asset.btc.resolutionChains`.
      var sum = BigInt.zero;
      var sawAny = false;
      for (final ab in balance.assets) {
        if (ab.chain != fromChain) continue;
        if (ab.assetId != null) continue;
        sum += BigInt.from(ab.amountSat);
        sawAny = true;
      }
      return sawAny ? sum : null;
    }

    // Liquid asset: match by asset id. Sum across multiple entries (defensive —
    // Breez Liquid currently emits one row per asset, but this keeps the
    // implementation correct if that ever changes).
    final assetId = asset.id;
    var sum = BigInt.zero;
    var sawAny = false;
    for (final ab in balance.assets) {
      if (ab.chain != fromChain) continue;
      if (ab.assetId != assetId) continue;
      sum += BigInt.from(ab.amountSat);
      sawAny = true;
    }
    return sawAny ? sum : null;
  }

  bool _everyChainErrored(Asset asset, _PerChainSnapshots snapshots) {
    for (final chain in asset.resolutionChains) {
      final snap = snapshots.forChain(chain);
      if (snap == null) continue;
      if (snap.isRight()) return false;
    }
    return true;
  }
}

class _PerChainSnapshots {
  const _PerChainSnapshots({
    required this.bitcoin,
    required this.liquid,
    required this.lightning,
  });

  final Either<Failure, Balance>? bitcoin;
  final Either<Failure, Balance>? liquid;
  final Either<Failure, Balance>? lightning;

  Either<Failure, Balance>? forChain(ChainId chain) => switch (chain) {
        ChainId.bitcoin => bitcoin,
        ChainId.liquid => liquid,
        ChainId.lightning => lightning,
        ChainId.aggregate => null,
      };
}
