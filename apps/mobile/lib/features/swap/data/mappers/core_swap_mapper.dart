import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../domain/entities/peg.dart';
import '../../domain/usecases/peg_orchestrator.dart';
import '../../domain/usecases/peg_tracker.dart';
import '../models.dart';

/// Maps mooze-core SideSwap and peg DTOs to the swap feature models.

SideswapAsset sideswapAssetFromDto(SideswapAssetDto dto) => SideswapAsset(
      assetId: dto.assetId,
      name: dto.name,
      ticker: dto.ticker,
      precision: dto.precision,
      iconUrl: dto.iconUrl,
      instantSwaps: dto.instantSwaps,
    );

SideswapMarket sideswapMarketFromDto(SideswapMarketDto dto) => SideswapMarket(
      baseAssetId: dto.baseAssetId,
      quoteAssetId: dto.quoteAssetId,
      feeAsset: dto.feeAsset,
      type: dto.marketType,
    );

int _int(BigInt? value) => value?.toInt() ?? 0;

QuoteResponse quoteResponseFromDto(QuoteDto dto) {
  final identity = (
    quoteSubId: dto.quoteSubId?.toInt(),
    requestedAmount: dto.requestedAmount?.toInt(),
    baseAssetId: dto.baseAssetId,
    quoteAssetId: dto.quoteAssetId,
  );
  return QuoteResponse(
    quote: dto.status == QuoteStatusDto.success
        ? SideswapQuote(
            quoteId: _int(dto.quoteId),
            baseAmount: _int(dto.baseAmount),
            quoteAmount: _int(dto.quoteAmount),
            serverFee: _int(dto.serverFee),
            fixedFee: _int(dto.fixedFee),
            ttl: _int(dto.ttlMs),
          )
        : null,
    lowBalance: dto.status == QuoteStatusDto.lowBalance
        ? QuoteLowBalance(
            available: _int(dto.available),
            baseAmount: _int(dto.baseAmount),
            quoteAmount: _int(dto.quoteAmount),
            serverFee: _int(dto.serverFee),
            fixedFee: _int(dto.fixedFee),
          )
        : null,
    error: dto.status == QuoteStatusDto.error
        ? QuoteError(errorMessage: dto.errorMessage ?? '')
        : null,
    quoteSubId: identity.quoteSubId,
    requestedAmount: identity.requestedAmount,
    baseAssetId: identity.baseAssetId,
    quoteAssetId: identity.quoteAssetId,
  );
}

PegDirection pegDirectionFromDto(PegDirectionDto dto) => switch (dto) {
      PegDirectionDto.pegIn => PegDirection.pegIn,
      PegDirectionDto.pegOut => PegDirection.pegOut,
    };

PegDirectionDto pegDirectionToDto(PegDirection direction) =>
    switch (direction) {
      PegDirection.pegIn => PegDirectionDto.pegIn,
      PegDirection.pegOut => PegDirectionDto.pegOut,
    };

/// The enum names of [PegPhaseDto] and [PegPhase] are equal.
PegPhase pegPhaseFromDto(PegPhaseDto dto) => PegPhase.values.byName(dto.name);

PegServerLimits pegLimitsFromDto(PegServerLimitsDto dto) => PegServerLimits(
      minPegInSat: dto.minPegInSat.toInt(),
      minPegOutSat: dto.minPegOutSat.toInt(),
      serverFeePercentPegIn: dto.serverFeePercentPegIn,
      serverFeePercentPegOut: dto.serverFeePercentPegOut,
    );

PegServerLimitsDto pegLimitsToDto(PegServerLimits limits) => PegServerLimitsDto(
      minPegInSat: BigInt.from(limits.minPegInSat),
      minPegOutSat: BigInt.from(limits.minPegOutSat),
      serverFeePercentPegIn: limits.serverFeePercentPegIn,
      serverFeePercentPegOut: limits.serverFeePercentPegOut,
    );

PegQuote pegQuoteFromDto(PegQuoteDto dto) => PegQuote(
      direction: pegDirectionFromDto(dto.direction),
      amountSat: dto.amountSat,
      networkFeeSat: dto.networkFeeSat,
      serviceFeeSat: dto.serviceFeeSat,
      minimumSat: dto.minimumSat,
    );

PegOrder pegOrderFromDto(PegOrderDto dto) => PegOrder(
      orderId: dto.orderId,
      direction: pegDirectionFromDto(dto.direction),
      depositAddress: dto.depositAddress,
      payoutAddress: dto.payoutAddress,
      createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdAtMs.toInt()),
      expiresAt: dto.expiresAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dto.expiresAtMs!.toInt()),
    );

PegExecution pegExecutionFromDto(PegExecutionDto dto) => PegExecution(
      order: pegOrderFromDto(dto.order),
      fundingTxId: dto.fundingTxId,
    );

TrackedPeg trackedPegFromDto(TrackedPegDto dto) => TrackedPeg(
      orderId: dto.orderId,
      direction: pegDirectionFromDto(dto.direction),
      phase: pegPhaseFromDto(dto.phase),
      amountSat: dto.amountSat,
      depositAddress: dto.depositAddress,
      fundingTxId: dto.fundingTxId,
      payoutTxId: dto.payoutTxId,
      confirmations: dto.confirmations,
      requiredConfirmations: dto.requiredConfirmations,
      errorMessage: dto.errorMessage,
    );
