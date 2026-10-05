import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/pix/data/mappers/core_pix_mapper.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// [PixRepository] backed by mooze-core.
///
/// The core stores the deposits, calls the backend with the session token
/// and tracks the deposit statuses. This class owns the poll timer: while
/// the core polls at least one deposit, a `Timer.periodic` calls
/// `pixPollTick` and forwards the changes to [statusUpdates].
class CorePixRepository implements PixRepository {
  /// Creates the repository before the core is open. Every call awaits
  /// [core]. [pollInterval] defaults to the core `pixPollIntervalMs`.
  CorePixRepository({required Future<MoozeCore> core, Duration? pollInterval})
      : _core = core,
        _pollInterval = pollInterval {
    // Stops an unhandled-error report when the core fails before the first
    // call. Each call still sees the error when it awaits.
    _core.ignore();
  }

  final Future<MoozeCore> _core;
  final Duration? _pollInterval;
  final _statusUpdates = StreamController<PixStatusEvent>.broadcast();

  Timer? _pollTimer;
  bool _tickRunning = false;
  bool _disposed = false;

  @override
  Stream<PixStatusEvent> get statusUpdates => _statusUpdates.stream;

  /// True while the poll timer runs.
  @visibleForTesting
  bool get isPolling => _pollTimer?.isActive ?? false;

  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents, {
    String? address,
    Asset asset = Asset.depix,
    String? taxIdNumber,
  }) {
    return _guard((core) async {
      final dto = await core.pixCreateDeposit(
        amountInCents: BigInt.from(amountInCents),
        assetId: asset.id,
        taxIdNumber: taxIdNumber,
        address: address,
      );
      final deposit = pixDepositFromDto(dto);
      _emit(
        PixStatusEvent(
          depositId: deposit.depositId,
          status: DepositStatus.pending,
        ),
      );
      _startPolling();
      return deposit;
    });
  }

  @override
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId) =>
      _guard((core) async {
        final dto = await core.pixGetDeposit(depositId: depositId);
        return Option.fromNullable(dto).map(pixDepositFromDto);
      });

  @override
  TaskEither<String, List<PixDeposit>> getDeposits({int? limit, int? offset}) =>
      _guard((core) async {
        final list = await core.pixListDeposits(limit: limit, offset: offset);
        return list.map(pixDepositFromDto).toList(growable: false);
      });

  @override
  TaskEither<String, List<PixDeposit>> updateDepositDetails(
    List<String> depositIds,
  ) =>
      _guard((core) async {
        final list = await core.pixUpdateDepositDetails(depositIds: depositIds);
        return list.map(pixDepositFromDto).toList(growable: false);
      });

  @override
  TaskEither<String, List<PixDeposit>> getHistory({int? limit, int? offset}) =>
      _guard((core) async {
        final list = await core.pixHistory(limit: limit, offset: offset);
        return list.map(pixDepositFromDto).toList(growable: false);
      });

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    unawaited(
      _core.then((core) => core.pixCancelPolls()).catchError((Object _) {}),
    );
    _statusUpdates.close();
  }

  void _startPolling() {
    if (_disposed || isPolling) return;
    final interval = _pollInterval ??
        Duration(milliseconds: CoreSyncHelpers.instance.pixPollIntervalMs());
    _pollTimer = Timer.periodic(interval, (_) => unawaited(_tick()));
  }

  /// Runs one core poll tick. Stops the timer when the core polls nothing.
  Future<void> _tick() async {
    if (_disposed || _tickRunning) return;
    _tickRunning = true;
    try {
      final core = await _core;
      final events = await core.pixPollTick();
      if (_disposed) return;
      events.map(pixStatusEventFromDto).forEach(_emit);
      if (await core.pixActivePolls() == 0) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (e) {
      // A failed tick keeps the timer. The next tick tries again.
      if (kDebugMode) debugPrint('[CorePixRepository] poll tick failed: $e');
    } finally {
      _tickRunning = false;
    }
  }

  void _emit(PixStatusEvent event) {
    if (_disposed || _statusUpdates.isClosed) return;
    _statusUpdates.add(event);
  }

  TaskEither<String, T> _guard<T>(Future<T> Function(MoozeCore core) body) =>
      TaskEither.tryCatch(
        () async => body(await _core),
        (e, _) => coreErrorMessage(e),
      );
}
