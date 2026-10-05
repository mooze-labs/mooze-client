/// Pure conversions between the mooze-core bridge DTOs and the domain types.
///
/// The functions have no side effects and no state. The Core* wallet
/// services use them on every bridge call.
library;

import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show PlatformInt64, PlatformInt64Util;
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../domain/entities/balance.dart';
import '../../domain/entities/broadcast_result.dart';
import '../../domain/entities/chain.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/liquid_send_draft.dart';
import '../../domain/entities/liquid_utxo.dart';
import '../../domain/entities/receive_address.dart';
import '../../domain/entities/send_request.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';

// ─────────────────────────────────────────── scalars

/// Reads a `PlatformInt64` value. It is an `int` on native and a `BigInt`
/// on the web.
int _readI64(Object value) => value is BigInt ? value.toInt() : value as int;

DateTime _fromMs(BigInt ms) => DateTime.fromMillisecondsSinceEpoch(ms.toInt());

// ─────────────────────────────────────────── enums

ChainId chainFromDto(ChainDto c) => switch (c) {
      ChainDto.liquid => ChainId.liquid,
      ChainDto.bitcoin => ChainId.bitcoin,
      ChainDto.lightning => ChainId.lightning,
      ChainDto.aggregate => ChainId.aggregate,
    };

ChainDto chainToDto(ChainId c) => switch (c) {
      ChainId.liquid => ChainDto.liquid,
      ChainId.bitcoin => ChainDto.bitcoin,
      ChainId.lightning => ChainDto.lightning,
      ChainId.aggregate => ChainDto.aggregate,
    };

NetworkDto networkToDto(AppNetwork n) => switch (n) {
      AppNetwork.mainnet => NetworkDto.mainnet,
      AppNetwork.testnet => NetworkDto.testnet,
      AppNetwork.regtest => NetworkDto.regtest,
    };

TransactionDirection directionFromDto(DirectionDto d) => switch (d) {
      DirectionDto.incoming => TransactionDirection.incoming,
      DirectionDto.outgoing => TransactionDirection.outgoing,
      DirectionDto.internal => TransactionDirection.internal,
      DirectionDto.selfTransfer => TransactionDirection.selfTransfer,
      DirectionDto.swap => TransactionDirection.swap,
    };

DirectionDto directionToDto(TransactionDirection d) => switch (d) {
      TransactionDirection.incoming => DirectionDto.incoming,
      TransactionDirection.outgoing => DirectionDto.outgoing,
      TransactionDirection.internal => DirectionDto.internal,
      TransactionDirection.selfTransfer => DirectionDto.selfTransfer,
      TransactionDirection.swap => DirectionDto.swap,
    };

TransactionStatus statusFromDto(StatusDto s) => switch (s) {
      StatusDto.pending => TransactionStatus.pending,
      StatusDto.confirmed => TransactionStatus.confirmed,
      StatusDto.failed => TransactionStatus.failed,
    };

StatusDto statusToDto(TransactionStatus s) => switch (s) {
      TransactionStatus.pending => StatusDto.pending,
      TransactionStatus.confirmed => StatusDto.confirmed,
      TransactionStatus.failed => StatusDto.failed,
    };

TransactionSource sourceFromDto(SourceDto s) => switch (s) {
      SourceDto.lwk => TransactionSource.lwk,
      SourceDto.breez => TransactionSource.breez,
      SourceDto.bdk => TransactionSource.bdk,
    };

SourceDto sourceToDto(TransactionSource s) => switch (s) {
      TransactionSource.lwk => SourceDto.lwk,
      TransactionSource.breez => SourceDto.breez,
      TransactionSource.bdk => SourceDto.bdk,
    };

FeePriority feePriorityFromDto(FeePriorityDto p) => switch (p) {
      FeePriorityDto.low => FeePriority.low,
      FeePriorityDto.medium => FeePriority.medium,
      FeePriorityDto.high => FeePriority.high,
    };

FeePriorityDto feePriorityToDto(FeePriority p) => switch (p) {
      FeePriority.low => FeePriorityDto.low,
      FeePriority.medium => FeePriorityDto.medium,
      FeePriority.high => FeePriorityDto.high,
    };

TransactionEventKind eventKindFromDto(TransactionEventKindDto k) =>
    switch (k) {
      TransactionEventKindDto.created => TransactionEventKind.created,
      TransactionEventKindDto.statusChanged =>
        TransactionEventKind.statusChanged,
      TransactionEventKindDto.confirmationsChanged =>
        TransactionEventKind.confirmationsChanged,
    };

// ─────────────────────────────────────────── transactions

Transaction transactionFromDto(TransactionDto t) {
  final sent = t.sentAmountSat;
  final received = t.receivedAmountSat;
  final source = t.source;
  return Transaction(
    id: t.id,
    chain: chainFromDto(t.chain),
    direction: directionFromDto(t.direction),
    status: statusFromDto(t.status),
    amountSat: _readI64(t.amountSat),
    feeSat: _readI64(t.feeSat),
    timestamp: _fromMs(t.timestampMs),
    confirmations: t.confirmations,
    assetId: t.assetId,
    address: t.address,
    label: t.label,
    fromAssetId: t.fromAssetId,
    toAssetId: t.toAssetId,
    sentAmountSat: sent == null ? null : _readI64(sent),
    receivedAmountSat: received == null ? null : _readI64(received),
    source: source == null ? null : sourceFromDto(source),
    swapLockupTxId: t.swapLockupTxId,
    swapClaimTxId: t.swapClaimTxId,
  );
}

/// Converts a domain transaction for `registerExternalBroadcast`.
///
/// NOTE(core): `TransactionDto` has no `breezSwapId`. The core drops it.
TransactionDto transactionToDto(Transaction t) {
  PlatformInt64 i64(int v) => PlatformInt64Util.from(v);
  final sent = t.sentAmountSat;
  final received = t.receivedAmountSat;
  final source = t.source;
  return TransactionDto(
    id: t.id,
    chain: chainToDto(t.chain),
    direction: directionToDto(t.direction),
    status: statusToDto(t.status),
    amountSat: i64(t.amountSat),
    feeSat: i64(t.feeSat),
    timestampMs: BigInt.from(t.timestamp.millisecondsSinceEpoch),
    confirmations: t.confirmations,
    assetId: t.assetId,
    address: t.address,
    label: t.label,
    fromAssetId: t.fromAssetId,
    toAssetId: t.toAssetId,
    sentAmountSat: sent == null ? null : i64(sent),
    receivedAmountSat: received == null ? null : i64(received),
    source: source == null ? null : sourceToDto(source),
    swapLockupTxId: t.swapLockupTxId,
    swapClaimTxId: t.swapClaimTxId,
  );
}

TransactionEvent transactionEventFromDto(TransactionEventDto e) {
  final prev = e.previousStatus;
  return TransactionEvent(
    kind: eventKindFromDto(e.kind),
    transaction: transactionFromDto(e.transaction),
    observedAt: _fromMs(e.observedAtMs),
    previousStatus: prev == null ? null : statusFromDto(prev),
    previousConfirmations: e.previousConfirmations,
  );
}

// ─────────────────────────────────────────── balances

AssetBalance assetBalanceFromDto(AssetBalanceDto a) => AssetBalance(
      chain: chainFromDto(a.chain),
      assetId: a.assetId,
      amountSat: a.amountSat.toInt(),
      precision: a.precision,
      ticker: a.ticker,
      pendingSat: a.pendingSat.toInt(),
    );

Balance balanceFromDto(BalanceDto b) => Balance(
      assets: b.assets.map(assetBalanceFromDto).toList(growable: false),
      snapshotAt: _fromMs(b.snapshotAtMs),
    );

// ─────────────────────────────────────────── send surface

FeeEstimate feeEstimateFromDto(FeeEstimateDto f) => FeeEstimate(
      chain: chainFromDto(f.chain),
      priority: feePriorityFromDto(f.priority),
      absoluteFeeSat: f.absoluteFeeSat.toInt(),
      feeRateSatPerVByte: f.feeRateSatPerVbyte,
      estimatedBlocks: f.estimatedBlocks,
    );

ReceiveAddress receiveAddressFromDto(ReceiveAddressDto r) => ReceiveAddress(
      chain: chainFromDto(r.chain),
      address: r.address,
      assetId: r.assetId,
      label: r.label,
      amountSat: r.amountSat?.toInt(),
    );

BroadcastResult broadcastResultFromDto(BroadcastResultDto r) => BroadcastResult(
      chain: chainFromDto(r.chain),
      txId: r.txId,
      transaction: transactionFromDto(r.transaction),
      feePaidSat: r.feePaidSat?.toInt(),
    );

LiquidSendDraft liquidSendDraftFromDto(LiquidSendDraftDto d) => LiquidSendDraft(
      pset: d.pset,
      destination: d.destination,
      amountSat: d.amountSat,
      feeSat: d.feeSat,
      feeRateSatPerKvb: d.feeRateSatPerKvb,
      drain: d.drain,
    );

LiquidUtxo liquidUtxoFromDto(LiquidUtxoDto u) => LiquidUtxo(
      txid: u.txid,
      vout: u.vout,
      assetId: u.assetId,
      assetBlindingFactor: u.assetBlindingFactor,
      valueSat: u.valueSat,
      valueBlindingFactor: u.valueBlindingFactor,
    );

SyncOutcome syncOutcomeFromDto(SyncOutcomeDto s) => SyncOutcome(
      chain: chainFromDto(s.chain),
      fetched: s.fetched,
      changed: s.changed,
      duration: Duration(milliseconds: s.durationMs.toInt()),
    );

/// Converts a domain send request. The DTO has no chain: the core method
/// sets it. The caller validates `request.chain` first.
///
/// Negative amounts become zero, because the core field is unsigned.
SendRequestDto sendRequestToDto(SendRequest r) => SendRequestDto(
      destination: r.destination,
      amountSat: BigInt.from(r.amountSat < 0 ? 0 : r.amountSat),
      assetId: r.assetId,
      feePriority: feePriorityToDto(r.feePriority),
      label: r.label,
      subtractFeeFromAmount: r.subtractFeeFromAmount,
      feeRateOverrideSatPerVbyte: r.feeRateOverrideSatPerVByte,
      drain: r.drain,
    );

// ─────────────────────────────────────────── errors

/// Prefixes that `mooze_core::Error::to_string` adds before the message.
/// The old Dart services did not have them, so the mapper removes them.
final RegExp _corePrefix = RegExp(
  r'^(wallet service failed on \w+|sync failed on \w+): ',
);

/// Returns the [CoreError] message without the core's variant prefix.
///
/// A `service` error then carries the same text as the old lwk/bdk
/// services, for example `bdk sync failed: ...`.
String coreErrorMessage(CoreError e) => e.message.replaceFirst(_corePrefix, '');

/// Maps a [CoreError] to a [ServiceFailure] for [chain].
///
/// - `service` errors keep the core text, which already names the operation.
/// - Other kinds get [operation] as a prefix when it is set, for example
///   `bdk sync failed: network: ...`.
ServiceFailure serviceFailureFromCoreError(
  CoreError e,
  ChainId chain, {
  String? operation,
  StackTrace? stackTrace,
}) {
  final text = coreErrorMessage(e);
  final message = (e.kind == CoreErrorKind.service || operation == null)
      ? text
      : '$operation failed: $text';
  return ServiceFailure(message,
      chain: chain, cause: e, stackTrace: stackTrace);
}

/// Maps any error thrown by a bridge call to a [ServiceFailure].
///
/// [operation] names the call the way the old services did, for example
/// `bdk sync` or `lwk getUtxos`. A [TimeoutException] becomes
/// `<operation> timeout`.
ServiceFailure serviceFailureFrom(
  Object error,
  ChainId chain, {
  required String operation,
  StackTrace? stackTrace,
}) {
  if (error is ServiceFailure) return error;
  if (error is CoreError) {
    return serviceFailureFromCoreError(error, chain,
        operation: operation, stackTrace: stackTrace);
  }
  if (error is TimeoutException) {
    return ServiceFailure('$operation timeout',
        chain: chain, cause: error, stackTrace: stackTrace);
  }
  return ServiceFailure('$operation failed: $error',
      chain: chain, cause: error, stackTrace: stackTrace);
}
