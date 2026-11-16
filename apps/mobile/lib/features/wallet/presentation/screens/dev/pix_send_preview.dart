import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;

import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_repository.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_withdrawal_wallet.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_send_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/send/pix_send_result_screen.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' show depixAssetId;

/// A Pix send for the dev previews, with how the provider answers it, read
/// after read.
///
/// [open] runs the real send flow on fakes: the backend answers from
/// [statuses], the wallet sends nothing, and the record of the withdrawal
/// stays in memory, out of the Pix history. The result screen then follows
/// the answers as it follows a real payment.
class PixSendPreview {
  const PixSendPreview({
    required this.label,
    required this.statuses,
    this.pollEvery = const Duration(seconds: 3),
    this.maxPolls = PixSendController.defaultMaxPolls,
    this.uncertain = false,
    this.atOutcome = false,
  });

  final String label;

  /// The status of each read, the first one right after the broadcast. The
  /// last one repeats.
  final List<PixWithdrawalStatus> statuses;

  /// Time between two reads.
  final Duration pollEvery;

  /// Reads before the screen stops reading by itself.
  final int maxPolls;

  /// Whether the broadcast ends uncertain, as on a timeout of the wallet.
  final bool uncertain;

  /// Whether the screen opens once the outcome is known, as a payment
  /// opened from the history.
  final bool atOutcome;

  static const all = [
    PixSendPreview(
      label: 'Pix send: delivered',
      statuses: [
        PixWithdrawalStatus.unsent,
        PixWithdrawalStatus.sending,
        PixWithdrawalStatus.sent,
      ],
    ),
    // The status comes before the coin is in place: the turn waits for it.
    PixSendPreview(
      label: 'Pix send: fast provider',
      statuses: [PixWithdrawalStatus.unsent, PixWithdrawalStatus.sent],
      pollEvery: Duration(milliseconds: 500),
    ),
    PixSendPreview(
      label: 'Pix send: slow provider',
      statuses: [
        PixWithdrawalStatus.unsent,
        PixWithdrawalStatus.unsent,
        PixWithdrawalStatus.unsent,
        PixWithdrawalStatus.sending,
        PixWithdrawalStatus.sending,
        PixWithdrawalStatus.sent,
      ],
      pollEvery: Duration(seconds: 5),
    ),
    PixSendPreview(
      label: 'Pix send: refunded',
      statuses: [
        PixWithdrawalStatus.unsent,
        PixWithdrawalStatus.sending,
        PixWithdrawalStatus.refunded,
      ],
    ),
    PixSendPreview(
      label: 'Pix send: failed',
      statuses: [PixWithdrawalStatus.unsent, PixWithdrawalStatus.error],
    ),
    PixSendPreview(
      label: 'Pix send: unconfirmed broadcast',
      statuses: [
        PixWithdrawalStatus.uncertain,
        PixWithdrawalStatus.uncertain,
        PixWithdrawalStatus.sending,
        PixWithdrawalStatus.sent,
      ],
      uncertain: true,
    ),
    // The reads stop before an outcome: the wait settles and rests.
    PixSendPreview(
      label: 'Pix send: no answer',
      statuses: [PixWithdrawalStatus.unsent],
      pollEvery: Duration(seconds: 2),
      maxPolls: 3,
    ),
    PixSendPreview(
      label: 'Pix send: from history',
      statuses: [PixWithdrawalStatus.sent],
      atOutcome: true,
    ),
  ];

  /// Sends a sample payment of R$ 45,90 to a sample key on fakes, and opens
  /// its result. Its button closes the preview.
  Future<void> open(BuildContext context) async {
    final controller = PixSendController(
      repository: _PreviewWithdrawals(statuses),
      wallet: _PreviewWallet(uncertain: uncertain),
      records: _MemoryRecords(),
      pollInterval: pollEvery,
      maxPolls: maxPolls,
    );
    controller
      ..startFromKey(PixKeyType.email, 'ana@exemplo.com.br')
      ..setTaxId('52998224725')
      ..setAmount(4590);
    await controller.requestQuote();
    await controller.confirmAndFund();
    if (atOutcome) {
      await controller.stream
          .firstWhere((state) => state.details?.status.isFinal ?? false)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => const PixSendState(),
          );
    }
    if (!context.mounted) {
      controller.dispose();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        // The scope owns the controller: it stops the reads when the
        // preview closes.
        builder: (route) => ProviderScope(
          overrides: [
            pixSendControllerProvider.overrideWith((ref) => controller),
          ],
          child: PixSendResultScreen(onClose: () => Navigator.of(route).pop()),
        ),
      ),
    );
  }
}

/// The backend of a preview: it creates one withdrawal and answers its
/// status from a script.
class _PreviewWithdrawals implements PixWithdrawalRepository {
  _PreviewWithdrawals(this._statuses);

  final List<PixWithdrawalStatus> _statuses;
  int _reads = 0;

  static const _id = 'preview-withdrawal';
  static const _feeInCents = 99;

  @override
  TaskEither<PixHubFailure, PixWithdrawal> create({
    required String pixKey,
    required int payoutAmountInCents,
    required String taxId,
    required String refundAddress,
  }) {
    final deposit = payoutAmountInCents + _feeInCents;
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    return TaskEither.right(
      PixWithdrawal(
        id: _id,
        providerId: 'preview',
        depositAddress: 'lq1qqpreviewdeposit',
        assetId: depixAssetId,
        depositAmountInCents: deposit,
        depositAmountSats: deposit * PixWithdrawal.depixUnitsPerCent,
        payoutAmountInCents: payoutAmountInCents,
        expiresAt: deadline,
        fundingDeadline: deadline,
      ),
    );
  }

  @override
  TaskEither<PixHubFailure, List<PixWithdrawalDetails>> statuses(
    List<String> ids,
  ) {
    final status = _statuses[math.min(_reads++, _statuses.length - 1)];
    final paid = status.isCompleted;
    return TaskEither.right([
      PixWithdrawalDetails(
        id: _id,
        status: status,
        createdAt: DateTime.now(),
        receiverName: paid ? 'Ana Souza' : null,
        receiverTaxNumber: paid ? '***.982.247-**' : null,
        transferDate: paid ? DateTime.now() : null,
      ),
    ]);
  }
}

/// The wallet of a preview: it has DePix and L-BTC, and sends nothing.
class _PreviewWallet implements PixWithdrawalWallet {
  _PreviewWallet({required this.uncertain});

  final bool uncertain;

  @override
  Future<Either<PixHubFailure, String>> refundAddress() async =>
      const Right('lq1qqpreviewrefund');

  @override
  Future<Either<PixHubFailure, int>> depixBalanceSats() async =>
      const Right(1000 * 100 * PixWithdrawal.depixUnitsPerCent);

  @override
  Future<Either<PixHubFailure, int>> estimateNetworkFeeSats({
    required String address,
    required int amountSats,
  }) async => const Right(26);

  @override
  Future<PixFundingResult> send({
    required String address,
    required int amountSats,
  }) async => uncertain
      ? const PixFundingUncertain(rawMessage: 'preview')
      : PixFundingSent(txid: 'f${'0' * 62}1');
}

/// The records of a preview, in memory, out of the Pix history.
class _MemoryRecords implements PixWithdrawalRecordStore {
  final _records = <PixWithdrawalRecord>[];

  @override
  List<PixWithdrawalRecord> load() => List.unmodifiable(_records);

  @override
  List<PixWithdrawalRecord> pending() =>
      _records.where((r) => r.needsAttention).toList();

  @override
  Future<void> save(PixWithdrawalRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index == -1) {
      _records.insert(0, record);
    } else {
      _records[index] = record;
    }
  }

  @override
  Future<void> clear() async => _records.clear();
}
