import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/data/datasources/pix_withdrawal_record_store.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

PixWithdrawalRecord _record(
  String id, {
  PixFundingStatus funding = PixFundingStatus.sent,
  PixWithdrawalStatus? lastStatus,
}) {
  return PixWithdrawalRecord(
    id: id,
    createdAt: DateTime.utc(2026, 10, 24, 12),
    payoutAmountInCents: 4590,
    depositAmountInCents: 4689,
    depositAmountSats: 4689000000,
    depositAddress: 'lq1qqdeposit',
    expiresAt: DateTime.utc(2026, 10, 24, 12, 30),
    maskedKey: 'a***@exemplo.com.br',
    fundingStatus: funding,
    fundingTxid: funding == PixFundingStatus.sent ? 'txid-$id' : null,
    lastStatus: lastStatus,
  );
}

void main() {
  late SharedPreferences prefs;
  late PixWithdrawalRecordStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PixWithdrawalRecordStore(prefs);
  });

  test('keeps every field across a save and a load', () async {
    await store.save(_record('w-1', lastStatus: PixWithdrawalStatus.sending));

    final loaded = PixWithdrawalRecordStore(prefs).load().single;
    expect(loaded.id, 'w-1');
    expect(loaded.createdAt, DateTime.utc(2026, 10, 24, 12));
    expect(loaded.payoutAmountInCents, 4590);
    expect(loaded.depositAmountInCents, 4689);
    expect(loaded.depositAmountSats, 4689000000);
    expect(loaded.feeInCents, 99);
    expect(loaded.depositAddress, 'lq1qqdeposit');
    expect(loaded.expiresAt, DateTime.utc(2026, 10, 24, 12, 30));
    expect(loaded.maskedKey, 'a***@exemplo.com.br');
    expect(loaded.fundingStatus, PixFundingStatus.sent);
    expect(loaded.fundingTxid, 'txid-w-1');
    expect(loaded.lastStatus, PixWithdrawalStatus.sending);
  });

  test('puts new records first and updates a record in place', () async {
    await store.save(_record('w-1'));
    await store.save(_record('w-2'));
    await store.save(_record('w-1', lastStatus: PixWithdrawalStatus.sent));

    final ids = store.load().map((r) => r.id).toList();
    expect(ids, ['w-2', 'w-1']);
    expect(store.load().last.lastStatus, PixWithdrawalStatus.sent);
  });

  test('keeps the newest records only', () async {
    for (var i = 0; i < PixWithdrawalRecordStore.maxRecords + 3; i++) {
      await store.save(_record('w-$i'));
    }

    final records = store.load();
    expect(records, hasLength(PixWithdrawalRecordStore.maxRecords));
    expect(records.first.id, 'w-${PixWithdrawalRecordStore.maxRecords + 2}');
  });

  test('pending lists funded records without a final status', () async {
    await store.save(
      _record('sending', lastStatus: PixWithdrawalStatus.sending),
    );
    await store.save(_record('sent', lastStatus: PixWithdrawalStatus.sent));
    await store.save(_record('unread'));
    await store.save(_record('uncertain', funding: PixFundingStatus.uncertain));
    await store.save(_record('crashed', funding: PixFundingStatus.attempting));
    await store.save(_record('not-sent', funding: PixFundingStatus.notSent));

    final ids = store.pending().map((r) => r.id).toSet();
    expect(ids, {'sending', 'unread', 'uncertain', 'crashed'});
  });

  test('skips unreadable data', () async {
    SharedPreferences.setMockInitialValues({
      'pix_withdrawal_records': '[{"id": 1}, "x", null]',
    });
    final broken = PixWithdrawalRecordStore(
      await SharedPreferences.getInstance(),
    );
    expect(broken.load(), isEmpty);

    SharedPreferences.setMockInitialValues({'pix_withdrawal_records': '{'});
    final invalid = PixWithdrawalRecordStore(
      await SharedPreferences.getInstance(),
    );
    expect(invalid.load(), isEmpty);
  });

  test('clear removes every record', () async {
    await store.save(_record('w-1'));
    await store.clear();
    expect(store.load(), isEmpty);
  });
}
