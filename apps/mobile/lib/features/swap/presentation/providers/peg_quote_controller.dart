import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';

import '../../di/providers/peg_providers.dart';
import '../../domain/entities/peg.dart';
import '../../domain/entities/peg_error.dart';
import '../../domain/usecases/peg_orchestrator.dart';

/// The speed a peg-in is priced at until the user picks another one in the
/// confirm sheet: the economic one when the advanced settings turn it on,
/// else the normal one.
FeeSpeed pegDefaultFeeSpeed({required bool lowFeeEnabled}) =>
    lowFeeEnabled ? FeeSpeed.low : FeeSpeed.medium;

/// The rate of [speed] in [fees].
int feeRateFor(BitcoinFeeEstimate fees, FeeSpeed speed) => switch (speed) {
  FeeSpeed.low => fees.lowFeeSatPerVByte,
  FeeSpeed.medium => fees.mediumFeeSatPerVByte,
  FeeSpeed.fast => fees.fastFeeSatPerVByte,
};

/// The amount the user wants to peg, as the swap screen holds it.
class PegQuoteRequest {
  const PegQuoteRequest({
    required this.direction,
    required this.amountSat,
    required this.drain,
  });

  final PegDirection direction;

  /// The typed amount. A drain (Max) sends the balance less the network fee
  /// instead, and the quote reports that amount.
  final BigInt amountSat;
  final bool drain;

  @override
  bool operator ==(Object other) =>
      other is PegQuoteRequest &&
      other.direction == direction &&
      other.amountSat == amountSat &&
      other.drain == drain;

  @override
  int get hashCode => Object.hash(direction, amountSat, drain);
}

enum PegQuoteStatus { idle, loading, ready, failed }

/// The live quote of a peg, and the request it answers.
class PegQuoteState {
  const PegQuoteState._(
    this.status, {
    this.request,
    this.quote,
    this.feeEstimate,
    this.feeSpeed,
    this.error,
  });

  const PegQuoteState.idle() : this._(PegQuoteStatus.idle);

  final PegQuoteStatus status;
  final PegQuoteRequest? request;
  final PegQuote? quote;

  /// The Bitcoin fee rates a peg-in was priced with. Null for a peg-out, or
  /// when no rate could be fetched and the wallet chose the rate.
  final BitcoinFeeEstimate? feeEstimate;

  /// The speed of [feeEstimate] the peg-in was priced at, from
  /// [pegDefaultFeeSpeed]. The confirm sheet opens on it. Null with no
  /// [feeEstimate].
  final FeeSpeed? feeSpeed;
  final PegError? error;

  /// True when a quote of [current] is ready. A quote of another amount, or
  /// of the same amount without Max, does not count.
  bool isReadyFor(PegQuoteRequest current) =>
      status == PegQuoteStatus.ready && request == current;

  bool isLoadingFor(PegQuoteRequest current) =>
      status == PegQuoteStatus.loading && request == current;

  /// Why mooze-core refused [current], for example an amount below the
  /// minimum of SideSwap.
  PegError? errorFor(PegQuoteRequest current) =>
      status == PegQuoteStatus.failed && request == current ? error : null;
}

/// Live quote of a peg on the swap screen, like the market quote of the
/// other pairs.
///
/// mooze-core prices the peg: it reads the minimum of SideSwap, sizes the
/// funding and refuses an amount below the minimum, Max included. A newer
/// request supersedes an older one, so a late answer never shows.
///
/// A peg has no TTL: SideSwap locks no price, and mooze-core sizes the
/// funding again when it executes. The confirm sheet opens on this quote
/// and asks for a new one only when the user picks another fee speed.
class PegQuoteController extends AutoDisposeNotifier<PegQuoteState> {
  /// Counts the requests. An answer whose number is no longer the last one
  /// belongs to an older amount.
  int _latest = 0;

  /// The Bitcoin fee rates, fetched once for the screen.
  Future<BitcoinFeeEstimate?>? _fees;

  @override
  PegQuoteState build() {
    // An answer that lands after the screen closed is dropped.
    ref.onDispose(() => _latest++);
    // The economy fee setting changes the default speed, so the peg-in on
    // screen is priced again at the new one.
    ref.listen(pegLowFeeEnabledProvider, (_, _) {
      final last = state.request;
      if (last != null && last.direction.isPegIn) request(last);
    });
    return const PegQuoteState.idle();
  }

  /// The fee rates of a peg-in. A failed fetch is tried again by the next
  /// request.
  Future<BitcoinFeeEstimate?> _bitcoinFees() async {
    final fees = _fees ??= ref
        .read(bitcoinFeeServiceProvider)
        .fetchFeeEstimate();
    final estimate = await fees;
    if (estimate == null && identical(_fees, fees)) _fees = null;
    return estimate;
  }

  Future<void> request(PegQuoteRequest request) async {
    final number = ++_latest;
    state = PegQuoteState._(PegQuoteStatus.loading, request: request);
    final feeEstimate = request.direction.isPegIn ? await _bitcoinFees() : null;
    if (number != _latest) return;
    final feeSpeed = pegDefaultFeeSpeed(
      lowFeeEnabled: ref.read(pegLowFeeEnabledProvider),
    );
    final result = await ref
        .read(pegOrchestratorProvider)
        .quote(
          direction: request.direction,
          amountSat: request.amountSat,
          feeRateSatPerVByte: feeEstimate == null
              ? null
              : feeRateFor(feeEstimate, feeSpeed),
          drain: request.drain,
        )
        .run();
    if (number != _latest) return;
    state = result.match(
      (error) => PegQuoteState._(
        PegQuoteStatus.failed,
        request: request,
        error: error,
      ),
      (quote) => PegQuoteState._(
        PegQuoteStatus.ready,
        request: request,
        quote: quote,
        feeEstimate: feeEstimate,
        feeSpeed: feeEstimate == null ? null : feeSpeed,
      ),
    );
  }

  /// Forgets the quote, for example when the amount is empty or fails the
  /// rules before any quote.
  void clear() {
    _latest++;
    state = const PegQuoteState.idle();
  }
}

final pegQuoteControllerProvider =
    NotifierProvider.autoDispose<PegQuoteController, PegQuoteState>(
      PegQuoteController.new,
    );
