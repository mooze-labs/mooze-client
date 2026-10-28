import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_draft.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';

/// Steps of the send flow.
enum PixSendPhase {
  /// The user composes the draft.
  editing,

  /// The app checks the wallet and asks the backend for a withdrawal.
  quoting,

  /// The withdrawal exists and waits for the review.
  readyForReview,

  /// The wallet builds, signs and broadcasts the DePix deposit.
  funding,

  /// The deposit left the wallet. The provider has not paid the Pix yet.
  awaitingSettlement,

  /// The backend reports `sent`: the recipient received the Pix.
  completed,

  /// The backend reports a final status other than `sent`.
  failed,

  /// The app cannot prove whether the deposit reached the network.
  outcomeUnknown,
}

/// The withdrawal under review and what the wallet found about funding it.
class PixSendQuote {
  final PixWithdrawal withdrawal;

  /// Liquid network fee in L-BTC satoshis, or null when the build failed.
  final int? networkFeeSats;

  /// Why the wallet cannot fund the withdrawal, or null when it can.
  final PixHubFailure? fundingBlocker;

  /// Last moment, on the device clock, at which the app still sends funds.
  final DateTime fundingCutoff;

  const PixSendQuote({
    required this.withdrawal,
    required this.fundingCutoff,
    this.networkFeeSats,
    this.fundingBlocker,
  });

  bool get canFund => networkFeeSats != null && fundingBlocker == null;
}

/// State of the send flow, shared by its screens.
class PixSendState {
  final PixSendPhase phase;

  /// The payment being composed, or null before the flow starts.
  final PixSendDraft? draft;

  /// The withdrawal created for the current draft.
  final PixSendQuote? quote;

  /// Local record of the funding attempt. Set from the broadcast on, and when
  /// the flow resumes a stored withdrawal.
  final PixWithdrawalRecord? record;

  /// Last status read from the backend.
  final PixWithdrawalDetails? details;

  /// The last failure of the draft, quote or funding steps.
  final PixHubFailure? failure;

  /// The last failure of a status read. Polling continues after it.
  final PixHubFailure? statusFailure;

  /// True while a status read runs.
  final bool isRefreshing;

  /// True when automatic polling stopped before a final status.
  final bool pollingExhausted;

  const PixSendState({
    this.phase = PixSendPhase.editing,
    this.draft,
    this.quote,
    this.record,
    this.details,
    this.failure,
    this.statusFailure,
    this.isRefreshing = false,
    this.pollingExhausted = false,
  });

  /// True while the controller waits for the wallet or the backend.
  bool get isBusy =>
      phase == PixSendPhase.quoting || phase == PixSendPhase.funding;

  PixSendState copyWith({
    PixSendPhase? phase,
    PixSendDraft? draft,
    PixSendQuote? quote,
    PixWithdrawalRecord? record,
    PixWithdrawalDetails? details,
    PixHubFailure? failure,
    PixHubFailure? statusFailure,
    bool? isRefreshing,
    bool? pollingExhausted,
    bool clearQuote = false,
    bool clearRecord = false,
    bool clearFailure = false,
    bool clearStatusFailure = false,
  }) {
    return PixSendState(
      phase: phase ?? this.phase,
      draft: draft ?? this.draft,
      quote: clearQuote ? null : (quote ?? this.quote),
      record: clearRecord ? null : (record ?? this.record),
      details: details ?? this.details,
      failure: clearFailure ? null : (failure ?? this.failure),
      statusFailure: clearStatusFailure
          ? null
          : (statusFailure ?? this.statusFailure),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pollingExhausted: pollingExhausted ?? this.pollingExhausted,
    );
  }
}

/// Schedules [callback] after [delay]. Tests replace it to run polls by hand.
typedef PixPollScheduler = Timer Function(Duration delay, void Function());

/// Drives the Pix send flow: draft, withdrawal, DePix deposit and settlement.
///
/// The backend creates the withdrawal and the provider pays the Pix. The app
/// funds the withdrawal with one DePix transfer from the wallet. The rules
/// below protect that transfer:
/// - The app writes a local record before the broadcast.
/// - A withdrawal gets one broadcast. A second one is possible only when the
///   wallet proves that the first stopped before the broadcast.
/// - The app sends nothing after the funding cutoff.
/// - Only the backend status `sent` counts as a completed payment.
class PixSendController extends StateNotifier<PixSendState> {
  PixSendController({
    required PixWithdrawalRepository repository,
    required PixWithdrawalWallet wallet,
    required PixWithdrawalRecordStore records,
    DateTime Function()? now,
    PixPollScheduler? schedule,
    this.pollInterval = defaultPollInterval,
    this.maxPolls = defaultMaxPolls,
    Future<void> Function()? onFunded,
  }) : _repository = repository,
       _wallet = wallet,
       _records = records,
       _now = now ?? DateTime.now,
       _schedule = schedule ?? Timer.new,
       _onFunded = onFunded,
       super(const PixSendState());

  /// Time kept before the funding deadline. A transfer sent later may reach
  /// the provider after the deadline, and the provider then refunds it.
  static const Duration fundingSafetyMargin = Duration(seconds: 60);

  /// Status poll interval. The value follows `WITHDRAW_POLL_INTERVAL_MS` of
  /// mooze-core.
  static const Duration defaultPollInterval = Duration(seconds: 3);

  /// Automatic status polls. The value follows `WITHDRAW_POLL_MAX_ATTEMPTS` of
  /// mooze-core.
  static const int defaultMaxPolls = 60;

  final Duration pollInterval;
  final int maxPolls;

  final PixWithdrawalRepository _repository;
  final PixWithdrawalWallet _wallet;
  final PixWithdrawalRecordStore _records;
  final DateTime Function() _now;
  final PixPollScheduler _schedule;
  final Future<void> Function()? _onFunded;

  /// Changes on every new flow. An async step that started in an older flow
  /// drops its result instead of writing it into the new flow.
  int _generation = 0;

  Timer? _pollTimer;
  int _polls = 0;

  /// True from the funding lock to the stored broadcast outcome.
  bool _fundingInFlight = false;

  @override
  void dispose() {
    _cancelPolling();
    super.dispose();
  }

  /// Clears the previous payment before a new flow starts.
  ///
  /// A broadcast in progress still updates its local record.
  void reset() {
    _beginFlow();
    state = const PixSendState();
  }

  /// Starts the flow from a typed Pix key, already validated and normalized.
  void startFromKey(PixKeyType type, String pixKey) {
    _beginFlow();
    state = PixSendState(
      draft: PixSendDraft.forKey(
        method: PixSendMethod.key,
        keyType: type,
        pixKey: pixKey,
      ),
    );
  }

  /// Starts the flow from a scanned or pasted code.
  ///
  /// The backend pays a Pix key, so the code must carry one. A dynamic code
  /// carries a URL instead and is refused. The amount is carried over only
  /// when the code fixes it.
  ///
  /// Returns null on success, or the failure that stops the flow.
  PixHubFailure? startFromCode(String code, {required bool scanned}) {
    final parsed = PixBrCodeParser.parse(code);
    final key = parsed.pixKey;
    if (!parsed.isStructurallyValid || key == null) {
      return const PixHubFailure(PixHubErrorCode.unsupportedCode);
    }
    final validation = PixKeyValidator.validate(key);
    if (!validation.isValid) {
      return const PixHubFailure(PixHubErrorCode.unsupportedCode);
    }

    _beginFlow();
    state = PixSendState(
      draft: PixSendDraft.forKey(
        method: scanned ? PixSendMethod.qrCode : PixSendMethod.copyPaste,
        keyType: validation.type!,
        pixKey: validation.normalized,
        amountInCents: parsed.amountInCents ?? 0,
        amountIsFixed: parsed.amountInCents != null,
        merchantName: parsed.merchantName,
        sourceCode: code,
      ),
    );
    return null;
  }

  /// Stores the payout typed on the amount screen.
  ///
  /// A new value drops the quote, because the quote was made for the old one.
  void setAmount(int amountInCents) {
    final draft = state.draft;
    if (draft == null || state.record != null) return;
    if (draft.amountIsFixed || draft.amountInCents == amountInCents) return;
    state = state.copyWith(
      phase: PixSendPhase.editing,
      draft: draft.copyWith(amountInCents: amountInCents),
      clearQuote: true,
      clearFailure: true,
    );
  }

  /// Stores the CPF or CNPJ of the key owner, as digits.
  void setTaxId(String input) {
    final draft = state.draft;
    if (draft == null || state.record != null || !draft.asksForTaxId) return;
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (draft.taxId == digits) return;
    state = state.copyWith(
      phase: PixSendPhase.editing,
      draft: draft.copyWith(taxId: digits),
      clearQuote: true,
      clearFailure: true,
    );
  }

  /// Creates the withdrawal of the draft and checks that the wallet can fund
  /// it.
  ///
  /// The wallet checks run first, so a wallet without DePix or L-BTC does not
  /// open a withdrawal. A quote that still fits the draft and the cutoff is
  /// reused: a second withdrawal only counts against the open-withdrawal
  /// limit.
  ///
  /// Returns true when the quote is ready for review.
  Future<bool> requestQuote() async {
    final draft = state.draft;
    if (draft == null || state.isBusy || state.record != null) return false;

    final current = state.quote;
    if (current != null &&
        current.withdrawal.payoutAmountInCents == draft.amountInCents &&
        _now().isBefore(current.fundingCutoff)) {
      state = state.copyWith(
        phase: PixSendPhase.readyForReview,
        clearFailure: true,
      );
      return true;
    }

    if (!draft.hasValidAmount) {
      return _quoteFailed(
        const PixHubFailure(PixHubErrorCode.amountOutOfBounds),
      );
    }
    final taxId = draft.taxId;
    if (taxId == null || (taxId.length != 11 && taxId.length != 14)) {
      return _quoteFailed(
        const PixHubFailure(
          PixHubErrorCode.invalidRequest,
          rawMessage: 'missing tax id',
        ),
      );
    }

    // An expired quote stays until a new one replaces it, so the review screen
    // keeps its content. The cutoff check stops any funding of it.
    final generation = _generation;
    state = state.copyWith(phase: PixSendPhase.quoting, clearFailure: true);

    final refundAddress = await _wallet.refundAddress();
    if (_isStale(generation)) return false;
    final address = refundAddress.toNullable();
    if (address == null) {
      return _quoteFailed(refundAddress.getLeft().toNullable()!);
    }

    final balanceResult = await _wallet.depixBalanceSats();
    if (_isStale(generation)) return false;
    final balance = balanceResult.toNullable();
    if (balance == null) {
      return _quoteFailed(balanceResult.getLeft().toNullable()!);
    }

    final payoutSats = draft.amountInCents * PixWithdrawal.depixUnitsPerCent;
    if (balance < payoutSats) {
      return _quoteFailed(
        const PixHubFailure(PixHubErrorCode.insufficientFunds),
      );
    }

    // A build to the wallet's own address checks the DePix and the L-BTC
    // before the backend opens a withdrawal. The build signs nothing.
    final preflight = await _wallet.estimateNetworkFeeSats(
      address: address,
      amountSats: payoutSats,
    );
    if (_isStale(generation)) return false;
    final preflightFailure = preflight.getLeft().toNullable();
    if (preflightFailure != null) return _quoteFailed(preflightFailure);

    final created = await _repository
        .create(
          pixKey: draft.pixKey,
          payoutAmountInCents: draft.amountInCents,
          taxId: taxId,
          refundAddress: address,
        )
        .run();
    if (_isStale(generation)) return false;
    final withdrawal = created.toNullable();
    if (withdrawal == null) {
      return _quoteFailed(created.getLeft().toNullable()!);
    }

    final cutoff = withdrawal.fundingDeadline.subtract(fundingSafetyMargin);
    if (!_now().isBefore(cutoff)) {
      return _quoteFailed(const PixHubFailure(PixHubErrorCode.quoteExpired));
    }

    final fee = await _wallet.estimateNetworkFeeSats(
      address: withdrawal.depositAddress,
      amountSats: withdrawal.depositAmountSats,
    );
    if (_isStale(generation)) return false;

    // The quote stays visible when the wallet cannot fund it, so the user
    // sees the provider fee and the reason.
    final blocker = balance < withdrawal.depositAmountSats
        ? const PixHubFailure(PixHubErrorCode.insufficientFunds)
        : fee.getLeft().toNullable();
    state = state.copyWith(
      phase: PixSendPhase.readyForReview,
      quote: PixSendQuote(
        withdrawal: withdrawal,
        fundingCutoff: cutoff,
        networkFeeSats: blocker == null ? fee.toNullable() : null,
        fundingBlocker: blocker,
      ),
    );
    return true;
  }

  /// Sends the DePix deposit of the reviewed withdrawal.
  ///
  /// Returns true when the flow moves to the result: the broadcast succeeded,
  /// or its outcome is uncertain. Returns false when nothing was sent.
  Future<bool> confirmAndFund() async {
    final draft = state.draft;
    final quote = state.quote;
    if (draft == null ||
        quote == null ||
        state.phase != PixSendPhase.readyForReview ||
        state.record != null) {
      return false;
    }
    if (!quote.canFund) {
      state = state.copyWith(
        failure:
            quote.fundingBlocker ??
            const PixHubFailure(PixHubErrorCode.fundingFailed),
      );
      return false;
    }
    if (!_now().isBefore(quote.fundingCutoff)) {
      state = state.copyWith(
        failure: const PixHubFailure(PixHubErrorCode.quoteExpired),
      );
      return false;
    }

    // One broadcast at a time, in any flow.
    if (_fundingInFlight) return false;

    final withdrawal = quote.withdrawal;
    final generation = _generation;
    var record = PixWithdrawalRecord.attempt(
      withdrawal,
      maskedKey: draft.maskedKey,
      now: _now(),
    );

    // Lock before the first await. A second call during the awaits below sees
    // the flag and the funding phase, and stops.
    _fundingInFlight = true;
    state = state.copyWith(
      phase: PixSendPhase.funding,
      record: record,
      clearFailure: true,
    );

    try {
      // Write-ahead: without the record, an interrupted broadcast leaves no
      // trace of the withdrawal, so the app does not send.
      if (!await _saveRecord(record)) {
        if (!_isStale(generation)) {
          state = state.copyWith(
            phase: PixSendPhase.readyForReview,
            failure: const PixHubFailure(
              PixHubErrorCode.fundingFailed,
              rawMessage: 'record not saved',
            ),
            clearRecord: true,
          );
        }
        return false;
      }
      if (_isStale(generation)) {
        // The flow ended before the broadcast: nothing was sent.
        await _saveRecord(
          record.copyWith(fundingStatus: PixFundingStatus.notSent),
        );
        return false;
      }

      final result = await _wallet.send(
        address: withdrawal.depositAddress,
        amountSats: withdrawal.depositAmountSats,
      );
      return await _recordFunding(result, record, generation);
    } finally {
      _fundingInFlight = false;
    }
  }

  /// Stores the outcome of a broadcast and moves the flow on.
  Future<bool> _recordFunding(
    PixFundingResult result,
    PixWithdrawalRecord attempt,
    int generation,
  ) async {
    var record = attempt;
    switch (result) {
      case PixFundingSent(:final txid):
        record = record.copyWith(
          fundingStatus: PixFundingStatus.sent,
          fundingTxid: txid,
        );
        await _saveRecord(record);
        _notifyFunded();
        if (_isStale(generation)) return true;
        state = state.copyWith(
          phase: PixSendPhase.awaitingSettlement,
          record: record,
        );
        _startPolling();
        return true;

      case PixFundingUncertain():
        record = record.copyWith(fundingStatus: PixFundingStatus.uncertain);
        await _saveRecord(record);
        // A wallet sync can reveal the transaction if it reached the network.
        _notifyFunded();
        if (_isStale(generation)) return true;
        state = state.copyWith(
          phase: PixSendPhase.outcomeUnknown,
          record: record,
        );
        _startPolling();
        return true;

      case PixFundingNotSent(:final failure):
        await _saveRecord(
          record.copyWith(fundingStatus: PixFundingStatus.notSent),
        );
        if (_isStale(generation)) return false;
        // Nothing left the wallet, so the same withdrawal can be funded again
        // before the cutoff.
        state = state.copyWith(
          phase: PixSendPhase.readyForReview,
          failure: failure,
          clearRecord: true,
        );
        return false;
    }
  }

  /// Opens a stored withdrawal on the result screen and polls its status.
  void resume(PixWithdrawalRecord record) {
    _beginFlow();
    state = PixSendState(
      phase: _phaseFor(record.lastStatus, record.fundingStatus),
      record: record,
    );
    _startPolling();
  }

  /// Reads the status once more. Used by the refresh button.
  Future<void> refreshStatus() async {
    if (state.record == null || state.isRefreshing) return;
    await _refresh(_generation);
  }

  // ─────────────────────────────────────────── polling

  void _startPolling() {
    _cancelPolling();
    _polls = 0;
    state = state.copyWith(pollingExhausted: false);
    _poll(_generation);
  }

  Future<void> _poll(int generation) async {
    await _refresh(generation);
    if (_isStale(generation)) return;
    if (state.details?.status.isFinal ?? false) return;

    _polls++;
    if (_polls >= maxPolls) {
      state = state.copyWith(pollingExhausted: true);
      return;
    }
    _pollTimer = _schedule(pollInterval, () => _poll(generation));
  }

  Future<void> _refresh(int generation) async {
    final record = state.record;
    if (record == null) return;
    state = state.copyWith(isRefreshing: true);

    final result = await _repository.statuses([record.id]).run();
    if (_isStale(generation)) return;

    result.match(
      (failure) =>
          state = state.copyWith(isRefreshing: false, statusFailure: failure),
      (list) {
        final details = list.where((d) => d.id == record.id).firstOrNull;
        if (details == null) {
          // The backend does not list unknown IDs. Keep the last status.
          state = state.copyWith(isRefreshing: false, clearStatusFailure: true);
          return;
        }
        final updated = record.copyWith(lastStatus: details.status);
        unawaited(_saveRecord(updated));
        state = state.copyWith(
          phase: _phaseFor(details.status, record.fundingStatus),
          record: updated,
          details: details,
          isRefreshing: false,
          clearStatusFailure: true,
        );
      },
    );
  }

  /// Maps the backend status and the funding result to a phase.
  ///
  /// The status `sending` means that the provider has the deposit, so it
  /// settles an uncertain broadcast. Other open statuses keep it uncertain.
  static PixSendPhase _phaseFor(
    PixWithdrawalStatus? status,
    PixFundingStatus funding,
  ) {
    if (status != null && status.isCompleted) return PixSendPhase.completed;
    if (status != null && status.isFinal) return PixSendPhase.failed;
    if (status == PixWithdrawalStatus.sending) {
      return PixSendPhase.awaitingSettlement;
    }
    return funding == PixFundingStatus.sent
        ? PixSendPhase.awaitingSettlement
        : PixSendPhase.outcomeUnknown;
  }

  // ─────────────────────────────────────────── helpers

  void _beginFlow() {
    _cancelPolling();
    _generation++;
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _isStale(int generation) => !mounted || generation != _generation;

  bool _quoteFailed(PixHubFailure failure) {
    state = state.copyWith(phase: PixSendPhase.editing, failure: failure);
    return false;
  }

  Future<bool> _saveRecord(PixWithdrawalRecord record) async {
    try {
      await _records.save(record);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Asks the wallet to sync. A failure here is not a funding failure.
  void _notifyFunded() {
    final onFunded = _onFunded;
    if (onFunded == null) return;
    unawaited(onFunded().catchError((Object _) {}));
  }
}
