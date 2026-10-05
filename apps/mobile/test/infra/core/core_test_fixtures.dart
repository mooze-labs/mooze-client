import 'dart:async';

import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/shared/clock/clock.dart';
import 'package:mooze_mobile/shared/logging/structured_logger.dart';

/// Builds a [TransactionDto] with test defaults.
TransactionDto txDto({
  required String id,
  ChainDto chain = ChainDto.bitcoin,
  DirectionDto direction = DirectionDto.incoming,
  StatusDto status = StatusDto.pending,
  int amountSat = 1000,
  int feeSat = 10,
  int timestampMs = 1700000000000,
  int confirmations = 0,
  String? assetId,
  String? address,
  String? label,
  String? fromAssetId,
  String? toAssetId,
  int? sentAmountSat,
  int? receivedAmountSat,
  SourceDto? source,
  String? swapLockupTxId,
  String? swapClaimTxId,
}) =>
    TransactionDto(
      id: id,
      chain: chain,
      direction: direction,
      status: status,
      amountSat: amountSat,
      feeSat: feeSat,
      timestampMs: BigInt.from(timestampMs),
      confirmations: confirmations,
      assetId: assetId,
      address: address,
      label: label,
      fromAssetId: fromAssetId,
      toAssetId: toAssetId,
      sentAmountSat: sentAmountSat,
      receivedAmountSat: receivedAmountSat,
      source: source,
      swapLockupTxId: swapLockupTxId,
      swapClaimTxId: swapClaimTxId,
    );

/// Builds a `created` [TransactionEventDto] for [tx].
TransactionEventDto createdEvent(TransactionDto tx) => TransactionEventDto(
      kind: TransactionEventKindDto.created,
      transaction: tx,
      observedAtMs: BigInt.from(1700000005000),
    );

SyncOutcomeDto syncDto(ChainDto chain, {int fetched = 0, int changed = 0}) =>
    SyncOutcomeDto(
      chain: chain,
      fetched: fetched,
      changed: changed,
      durationMs: BigInt.from(12),
    );

BalanceDto balanceDto(ChainDto chain, Map<String?, int> amounts) => BalanceDto(
      assets: [
        for (final e in amounts.entries)
          AssetBalanceDto(
            chain: chain,
            assetId: e.key,
            amountSat: BigInt.from(e.value),
            precision: 8,
            pendingSat: BigInt.zero,
          ),
      ],
      snapshotAtMs: BigInt.from(1700000000000),
    );

/// Fallback value for mocktail `any()` on [SendRequestDto] arguments.
final SendRequestDto fallbackSendRequestDto = SendRequestDto(
  destination: '',
  amountSat: BigInt.zero,
  feePriority: FeePriorityDto.medium,
  subtractFeeFromAmount: false,
  drain: false,
);

/// Logger that keeps records in memory and prints nothing.
class MemoryLogger implements StructuredLogger {
  final List<LogRecord> logs = [];
  final StreamController<LogRecord> _c = StreamController.broadcast();

  void _add(LogLevel level, String tag, Map<String, Object?> fields,
      Object? error, StackTrace? st) {
    final r = LogRecord(
      timestamp: DateTime(2026),
      level: level,
      tag: tag,
      fields: fields,
      error: error,
      stackTrace: st,
    );
    logs.add(r);
    _c.add(r);
  }

  bool hasTag(String tag) => logs.any((r) => r.tag == tag);

  @override
  void debug(String tag, Map<String, Object?> fields,
          {Object? error, StackTrace? stackTrace}) =>
      _add(LogLevel.debug, tag, fields, error, stackTrace);
  @override
  void info(String tag, Map<String, Object?> fields,
          {Object? error, StackTrace? stackTrace}) =>
      _add(LogLevel.info, tag, fields, error, stackTrace);
  @override
  void warn(String tag, Map<String, Object?> fields,
          {Object? error, StackTrace? stackTrace}) =>
      _add(LogLevel.warn, tag, fields, error, stackTrace);
  @override
  void error(String tag, Map<String, Object?> fields,
          {Object? error, StackTrace? stackTrace}) =>
      _add(LogLevel.error, tag, fields, error, stackTrace);
  @override
  Stream<LogRecord> get records => _c.stream;
}

/// Clock fixed at one instant.
class FixedClock implements Clock {
  FixedClock([DateTime? now]) : _now = now ?? DateTime(2026, 10, 5, 12);
  final DateTime _now;
  @override
  DateTime now() => _now;
  @override
  Future<void> sleep(Duration duration) async {}
}
