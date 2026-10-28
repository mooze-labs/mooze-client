import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../check_digit_core_sync_helpers.dart';
import '../pix_send_fakes.dart';

/// Lets the queued futures and microtasks finish.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A static Pix code that carries [key].
String _staticCode(String key, {int? amountInCents}) => PixBrCodeParser.build(
  pixKey: key,
  merchantName: 'Padaria Central',
  merchantCity: 'Sao Paulo',
  amountInCents: amountInCents,
);

/// A dynamic Pix code: a URL in place of the key.
String _dynamicCode() {
  String field(String id, String value) =>
      '$id${value.length.toString().padLeft(2, '0')}$value';
  final account =
      field('00', 'BR.GOV.BCB.PIX') + field('25', 'pix.exemplo.com/qr/abc');
  final body =
      '${field('00', '01')}${field('26', account)}${field('52', '0000')}'
      '${field('53', '986')}${field('58', 'BR')}${field('59', 'LOJA')}'
      '${field('60', 'RIO')}${field('62', field('05', '***'))}6304';
  return '$body${PixBrCodeParser.crc16(body)}';
}

const _cpf = '52998224725';
const _email = 'ana@exemplo.com.br';

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  late FakeWithdrawalRepository repository;
  late FakeWithdrawalWallet wallet;
  late PixWithdrawalRecordStore store;
  late DateTime now;
  late List<void Function()> scheduled;
  late List<FakeTimer> timers;
  late int fundedCalls;
  late PixSendController controller;

  PixSendController build({int maxPolls = 60}) {
    return PixSendController(
      repository: repository,
      wallet: wallet,
      records: store,
      now: () => now,
      maxPolls: maxPolls,
      schedule: (delay, callback) {
        scheduled.add(callback);
        final timer = FakeTimer();
        timers.add(timer);
        return timer;
      },
      onFunded: () async => fundedCalls++,
    );
  }

  /// Runs the next scheduled poll.
  Future<void> runNextPoll() async {
    scheduled.removeAt(0)();
    await _settle();
  }

  /// A CPF-key draft of [amount] cents with its quote ready for review.
  Future<void> quoted({int amount = 4590}) async {
    controller.startFromKey(PixKeyType.cpf, _cpf);
    controller.setAmount(amount);
    expect(await controller.requestQuote(), isTrue);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PixWithdrawalRecordStore(await SharedPreferences.getInstance());
    repository = FakeWithdrawalRepository();
    wallet = FakeWithdrawalWallet();
    now = testStart;
    scheduled = [];
    timers = [];
    fundedCalls = 0;
    controller = build();
  });

  tearDown(() {
    if (controller.mounted) controller.dispose();
  });

  group('drafts', () {
    test('a CPF key is its own tax ID', () {
      controller.startFromKey(PixKeyType.cpf, _cpf);

      final draft = controller.state.draft!;
      expect(draft.method, PixSendMethod.key);
      expect(draft.taxId, _cpf);
      expect(draft.asksForTaxId, isFalse);
    });

    test('an email key asks for the tax ID of the owner', () {
      controller.startFromKey(PixKeyType.email, _email);

      expect(controller.state.draft!.taxId, isNull);
      expect(controller.state.draft!.asksForTaxId, isTrue);

      controller.setTaxId('529.982.247-25');
      expect(controller.state.draft!.taxId, _cpf);
    });

    test('a static code carries its key, amount and name', () {
      final failure = controller.startFromCode(
        _staticCode(_email, amountInCents: 8450),
        scanned: true,
      );

      expect(failure, isNull);
      final draft = controller.state.draft!;
      expect(draft.method, PixSendMethod.qrCode);
      expect(draft.pixKey, _email);
      expect(draft.keyType, PixKeyType.email);
      expect(draft.amountInCents, 8450);
      expect(draft.amountIsFixed, isTrue);
      expect(draft.merchantName, 'PADARIA CENTRAL');
    });

    test('a fixed amount does not change', () {
      controller.startFromCode(
        _staticCode(_email, amountInCents: 8450),
        scanned: false,
      );
      controller.setAmount(100);

      expect(controller.state.draft!.amountInCents, 8450);
    });

    test('a dynamic code is refused and keeps the previous state', () {
      controller.startFromKey(PixKeyType.cpf, _cpf);

      final failure = controller.startFromCode(_dynamicCode(), scanned: false);

      expect(failure?.code, PixHubErrorCode.unsupportedCode);
      expect(controller.state.draft!.pixKey, _cpf);
    });
  });

  group('requestQuote', () {
    test('checks the wallet, then creates the withdrawal', () async {
      await quoted();

      expect(repository.creates.single, {
        'pix_key': _cpf,
        'payout': 4590,
        'tax_id': _cpf,
        'refund_address': 'lq1qqrefund',
      });
      // The preflight builds to the wallet's own address before the backend
      // opens a withdrawal. The second build uses the deposit instructions.
      expect(wallet.estimates, [
        ('lq1qqrefund', 4590 * PixWithdrawal.depixUnitsPerCent),
        ('lq1qqdepositw-1', 4689 * PixWithdrawal.depixUnitsPerCent),
      ]);
      final state = controller.state;
      expect(state.phase, PixSendPhase.readyForReview);
      expect(state.quote!.networkFeeSats, 152);
      expect(state.quote!.canFund, isTrue);
      expect(state.quote!.withdrawal.feeInCents, 99);
      expect(
        state.quote!.fundingCutoff,
        testStart
            .add(const Duration(minutes: 30))
            .subtract(PixSendController.fundingSafetyMargin),
      );
    });

    test('a balance below the payout opens no withdrawal', () async {
      wallet.balance = 4589 * PixWithdrawal.depixUnitsPerCent;
      controller.startFromKey(PixKeyType.cpf, _cpf);
      controller.setAmount(4590);

      expect(await controller.requestQuote(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.insufficientFunds);
      expect(controller.state.phase, PixSendPhase.editing);
      expect(repository.creates, isEmpty);
    });

    test('missing L-BTC for the fee opens no withdrawal', () async {
      wallet.onEstimate = (_, _) =>
          const Left(PixHubFailure(PixHubErrorCode.insufficientFeeAsset));
      controller.startFromKey(PixKeyType.cpf, _cpf);
      controller.setAmount(4590);

      expect(await controller.requestQuote(), isFalse);
      expect(
        controller.state.failure?.code,
        PixHubErrorCode.insufficientFeeAsset,
      );
      expect(repository.creates, isEmpty);
    });

    test('an amount outside the API bounds sends nothing', () async {
      controller.startFromKey(PixKeyType.cpf, _cpf);
      controller.setAmount(199);

      expect(await controller.requestQuote(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.amountOutOfBounds);
      expect(wallet.estimates, isEmpty);
      expect(repository.creates, isEmpty);
    });

    test('a key without a tax ID sends nothing', () async {
      controller.startFromKey(PixKeyType.email, _email);
      controller.setAmount(4590);

      expect(await controller.requestQuote(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.invalidRequest);
      expect(repository.creates, isEmpty);
    });

    test('keeps the backend failure', () async {
      repository.onCreate = (_) =>
          const Left(PixHubFailure(PixHubErrorCode.providerRefused));
      controller.startFromKey(PixKeyType.cpf, _cpf);
      controller.setAmount(4590);

      expect(await controller.requestQuote(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.providerRefused);
      expect(controller.state.phase, PixSendPhase.editing);
      expect(controller.state.quote, isNull);
    });

    test('a deposit above the balance shows the quote, blocked', () async {
      // Enough for the payout, not for the payout plus the fee.
      wallet.balance = 4600 * PixWithdrawal.depixUnitsPerCent;
      await quoted();

      final quote = controller.state.quote!;
      expect(quote.canFund, isFalse);
      expect(quote.fundingBlocker?.code, PixHubErrorCode.insufficientFunds);

      expect(await controller.confirmAndFund(), isFalse);
      expect(wallet.sends, isEmpty);
    });

    test('reuses a quote that still fits the draft', () async {
      await quoted();
      now = now.add(const Duration(minutes: 5));

      expect(await controller.requestQuote(), isTrue);
      expect(repository.creates, hasLength(1));
    });

    test('a new amount drops the quote', () async {
      await quoted();
      controller.setAmount(5000);

      expect(controller.state.quote, isNull);
      expect(await controller.requestQuote(), isTrue);
      expect(repository.creates.last['payout'], 5000);
    });

    test('an expired quote is replaced by a new withdrawal', () async {
      await quoted();
      now = now.add(const Duration(minutes: 29, seconds: 30));
      repository.onCreate = (payout) =>
          Right(testWithdrawal(payout: payout, id: 'w-2', now: now));

      expect(await controller.requestQuote(), isTrue);
      expect(repository.creates, hasLength(2));
      expect(controller.state.quote!.withdrawal.id, 'w-2');
    });

    test('a deadline inside the safety margin is refused', () async {
      repository.onCreate = (payout) => Right(
        testWithdrawal(payout: payout, validFor: const Duration(seconds: 30)),
      );
      controller.startFromKey(PixKeyType.cpf, _cpf);
      controller.setAmount(4590);

      expect(await controller.requestQuote(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.quoteExpired);
    });
  });

  group('confirmAndFund', () {
    test('writes the record, sends the exact deposit and polls', () async {
      await quoted();
      PixWithdrawalRecord? recordDuringSend;
      wallet.onSend = () => recordDuringSend = store.load().firstOrNull;

      expect(await controller.confirmAndFund(), isTrue);
      await _settle();

      // Write-ahead: the record existed before the broadcast.
      expect(recordDuringSend?.id, 'w-1');
      expect(recordDuringSend?.fundingStatus, PixFundingStatus.attempting);
      expect(wallet.sends.single, (
        'lq1qqdepositw-1',
        4689 * PixWithdrawal.depixUnitsPerCent,
      ));

      final stored = store.load().single;
      expect(stored.fundingStatus, PixFundingStatus.sent);
      expect(stored.fundingTxid, 'txid-1');
      expect(stored.maskedKey, '***.982.247-**');
      expect(controller.state.phase, PixSendPhase.awaitingSettlement);
      expect(fundedCalls, 1);
      expect(repository.statusReads.single, ['w-1']);
    });

    test('two taps send one transfer', () async {
      await quoted();
      wallet.sendGate = Completer();

      final first = controller.confirmAndFund();
      final second = controller.confirmAndFund();
      await _settle();
      wallet.sendGate!.complete(const PixFundingSent(txid: 'txid-1'));

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(wallet.sends, hasLength(1));
    });

    test('sends nothing after the funding cutoff', () async {
      await quoted();
      now = now.add(const Duration(minutes: 29, seconds: 1));

      expect(await controller.confirmAndFund(), isFalse);
      expect(controller.state.failure?.code, PixHubErrorCode.quoteExpired);
      expect(wallet.sends, isEmpty);
      expect(store.load(), isEmpty);
    });

    test('an uncertain broadcast is never sent again', () async {
      await quoted();
      wallet.sendResult = const PixFundingUncertain(rawMessage: 'timeout');

      expect(await controller.confirmAndFund(), isTrue);
      await _settle();

      expect(controller.state.phase, PixSendPhase.outcomeUnknown);
      expect(store.load().single.fundingStatus, PixFundingStatus.uncertain);
      expect(store.pending(), hasLength(1));

      expect(await controller.confirmAndFund(), isFalse);
      expect(await controller.requestQuote(), isFalse);
      expect(wallet.sends, hasLength(1));
    });

    test('a transfer stopped before the broadcast can be retried', () async {
      await quoted();
      wallet.sendResult = const PixFundingNotSent(
        PixHubFailure(PixHubErrorCode.insufficientFeeAsset),
      );

      expect(await controller.confirmAndFund(), isFalse);
      expect(controller.state.phase, PixSendPhase.readyForReview);
      expect(controller.state.record, isNull);
      expect(
        controller.state.failure?.code,
        PixHubErrorCode.insufficientFeeAsset,
      );
      expect(store.load().single.fundingStatus, PixFundingStatus.notSent);
      expect(store.pending(), isEmpty);

      wallet.sendResult = const PixFundingSent(txid: 'txid-2');
      expect(await controller.confirmAndFund(), isTrue);
      expect(wallet.sends, hasLength(2));
      expect(store.load().single.fundingTxid, 'txid-2');
    });

    test('a reset before the broadcast sends nothing', () async {
      await quoted();

      // The reset runs while the write-ahead record is being saved.
      final funding = controller.confirmAndFund();
      controller.reset();

      expect(await funding, isFalse);
      expect(wallet.sends, isEmpty);
      expect(store.load().single.fundingStatus, PixFundingStatus.notSent);
      expect(store.pending(), isEmpty);
    });

    test('a reset during the broadcast still records its outcome', () async {
      await quoted();
      wallet.sendGate = Completer();

      final funding = controller.confirmAndFund();
      await _settle();
      controller.reset();
      wallet.sendGate!.complete(const PixFundingSent(txid: 'txid-1'));

      expect(await funding, isTrue);
      expect(controller.state.draft, isNull);
      expect(controller.state.record, isNull);
      expect(store.load().single.fundingStatus, PixFundingStatus.sent);
      expect(repository.statusReads, isEmpty);
    });
  });

  group('settlement', () {
    test('only the status sent completes the payment', () async {
      repository.statusAnswers.addAll([
        Right([testDetails('w-1', PixWithdrawalStatus.unsent)]),
        Right([testDetails('w-1', PixWithdrawalStatus.sending)]),
        Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
      ]);
      await quoted();
      await controller.confirmAndFund();
      await _settle();
      expect(controller.state.phase, PixSendPhase.awaitingSettlement);

      await runNextPoll();
      expect(controller.state.details?.status, PixWithdrawalStatus.sending);
      expect(controller.state.phase, PixSendPhase.awaitingSettlement);

      await runNextPoll();
      expect(controller.state.phase, PixSendPhase.completed);
      expect(scheduled, isEmpty);
      expect(store.load().single.lastStatus, PixWithdrawalStatus.sent);
      expect(store.pending(), isEmpty);
    });

    test('a refund ends the flow as failed', () async {
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.refunded)]),
      );
      await quoted();
      await controller.confirmAndFund();
      await _settle();

      expect(controller.state.phase, PixSendPhase.failed);
      expect(scheduled, isEmpty);
    });

    test('sending settles an uncertain broadcast', () async {
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.sending)]),
      );
      wallet.sendResult = const PixFundingUncertain();
      await quoted();
      await controller.confirmAndFund();
      await _settle();

      expect(controller.state.phase, PixSendPhase.awaitingSettlement);
    });

    test('polling stops after the attempt limit', () async {
      controller.dispose();
      controller = build(maxPolls: 2);
      await quoted();
      await controller.confirmAndFund();
      await _settle();
      expect(controller.state.pollingExhausted, isFalse);

      await runNextPoll();

      expect(controller.state.pollingExhausted, isTrue);
      expect(scheduled, isEmpty);
      expect(repository.statusReads, hasLength(2));
    });

    test('a failed status read keeps polling', () async {
      repository.statusAnswers.addAll([
        const Left(PixHubFailure(PixHubErrorCode.network)),
        Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
      ]);
      await quoted();
      await controller.confirmAndFund();
      await _settle();

      expect(controller.state.statusFailure?.code, PixHubErrorCode.network);
      expect(scheduled, hasLength(1));

      await runNextPoll();
      expect(controller.state.statusFailure, isNull);
      expect(controller.state.phase, PixSendPhase.completed);
    });

    test('resume reads the status of a stored withdrawal', () async {
      final record = PixWithdrawalRecord.attempt(
        testWithdrawal(),
        maskedKey: '***.982.247-**',
        now: testStart,
      ).copyWith(fundingStatus: PixFundingStatus.uncertain);
      await store.save(record);
      repository.statusAnswers.add(
        Right([testDetails('w-1', PixWithdrawalStatus.sent)]),
      );

      controller.resume(record);
      expect(controller.state.phase, PixSendPhase.outcomeUnknown);
      await _settle();

      expect(controller.state.phase, PixSendPhase.completed);
      expect(store.pending(), isEmpty);
    });

    test('reset cancels the polling', () async {
      await quoted();
      await controller.confirmAndFund();
      await _settle();

      controller.reset();

      expect(timers.single.cancelled, isTrue);
    });
  });
}
