import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';

import '../../domain/entities/peg.dart';
import '../../domain/entities/peg_error.dart';
import '../../domain/usecases/peg_orchestrator.dart';
import '../mappers/core_swap_mapper.dart';
import '../services/core_sideswap_session.dart';

/// [PegOrchestrator] backed by mooze-core.
///
/// The core creates the order, stores it under the wallet id, funds it from
/// the wallet (mnemonic from the secure store) and starts tracking it. This
/// class adds what the core does not own: the shared Liquid spend lock for
/// peg-outs and the swap audit row that the home history reads.
class CorePegOrchestrator implements PegOrchestrator {
  CorePegOrchestrator({
    required CoreSideswapSession session,
    required Future<String> walletId,
    SwapAuditRepository? audit,
    LiquidSpendCoordinator? coordinator,
  })  : _session = session,
        _walletId = walletId,
        _audit = audit,
        _coordinator = coordinator ?? LiquidSpendCoordinator.instance;

  final CoreSideswapSession _session;
  final Future<String> _walletId;
  final SwapAuditRepository? _audit;
  final LiquidSpendCoordinator _coordinator;

  @override
  TaskEither<PegError, PegServerLimits> limits() => _guard(
        (core) async => pegLimitsFromDto(await core.pegLimits()),
      );

  @override
  TaskEither<PegError, PegQuote> quote({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) =>
      _guard((core) async {
        final dto = await core.pegQuote(
          direction: pegDirectionToDto(direction),
          amountSat: amountSat,
          feeRateSatPerVbyte: feeRateSatPerVByte,
          drain: drain,
        );
        return pegQuoteFromDto(dto);
      });

  @override
  TaskEither<PegError, PegExecution> execute({
    required PegDirection direction,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
    String? externalPayoutAddress,
  }) {
    final external = externalPayoutAddress?.trim();
    if (external != null && external.isNotEmpty && direction.isPegIn) {
      return TaskEither.left(
        const PegWalletFailure(
          'peg-in deve receber em endereço da própria carteira',
        ),
      );
    }
    return _guard((core) async {
      final walletId = await _walletId;
      Future<PegExecutionDto> run() => core.pegExecute(
            walletId: walletId,
            direction: pegDirectionToDto(direction),
            amountSat: amountSat,
            feeRateSatPerVbyte: feeRateSatPerVByte,
            drain: drain,
            externalPayoutAddress:
                external == null || external.isEmpty ? null : external,
          );
      // A peg-out spends Liquid UTXOs: hold the lock that the other Liquid
      // spends (sends, asset swaps) use.
      final dto = direction.isPegIn
          ? await run()
          : await _coordinator.protect('sideswap:pegOutFunding', run);
      final execution = pegExecutionFromDto(dto);
      await _recordAudit(execution.order, amountSat);
      return execution;
    });
  }

  Future<void> _recordAudit(PegOrder order, BigInt amountSat) async {
    final audit = _audit;
    if (audit == null) return;
    try {
      await audit.recordPending(
        provider: 'sideswap',
        direction: order.direction.auditDirection,
        sendAsset: order.direction.isPegIn ? 'BTC' : 'LBTC',
        receiveAsset: order.direction.isPegIn ? 'LBTC' : 'BTC',
        sendAmount: amountSat,
        receiveAmount: amountSat,
        metadata: {
          'orderId': order.orderId,
          'depositAddress': order.depositAddress,
          'payoutAddress': order.payoutAddress,
        },
      );
    } catch (_) {
      // History annotation is never worth failing a peg over.
    }
  }

  TaskEither<PegError, T> _guard<T>(Future<T> Function(MoozeCore core) body) =>
      TaskEither.tryCatch(
        () async => body(await _session.connected()),
        (e, _) => pegErrorFromCore(e),
      );
}

/// Maps a bridge error to the [PegError] the UI shows.
PegError pegErrorFromCore(Object error) {
  if (error is PegError) return error;
  if (error is LiquidSpendLockTimeout) return PegWalletBusy(error.toString());
  if (error is CoreError) {
    return switch (error.kind) {
      CoreErrorKind.timeout => PegUnknownOutcome(
          stage: 'core',
          detail: error.message,
        ),
      _ => PegCoreFailure(error.message),
    };
  }
  return PegCoreFailure(error.toString());
}
