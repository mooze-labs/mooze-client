import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/v2_legacy_transactions_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/test_app.dart';
import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

class _NoPendingSwaps extends PendingSwapsNotifier {
  @override
  List<PendingSwap> build() => const [];
}

Transaction _tx(String id, {TransactionType type = TransactionType.receive}) {
  return Transaction(
    id: id,
    amount: BigInt.from(1000),
    blockchain: Blockchain.liquid,
    asset: Asset.lbtc,
    type: type,
    status: TransactionStatus.confirmed,
    createdAt: DateTime(2026, 10, 27, 12),
  );
}

/// Pumps the home transaction list fed by [transactions].
Future<void> _pumpList(
  WidgetTester tester,
  StreamController<List<Transaction>> transactions,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        v2LegacyTransactionsProvider.overrideWith((ref) => transactions.stream),
        pendingSwapsProvider.overrideWith(_NoPendingSwaps.new),
        pendingSwapsReconciliationProvider.overrideWith((ref) {}),
      ],
      child: wrapForTest(
        const Scaffold(body: SingleChildScrollView(child: TransactionList())),
      ),
    ),
  );
}

/// Sends [list] and waits until the list shows it.
Future<void> _emit(
  WidgetTester tester,
  StreamController<List<Transaction>> transactions,
  List<Transaction> list,
) async {
  transactions.add(list);
  await tester.pump();
  await tester.pump();
}

final _inserts = find.byType(SizeTransition);

List<String> _messages(WidgetTester tester) => [
  for (final announcement in tester.takeAnnouncements()) announcement.message,
];

void main() {
  late StreamController<List<Transaction>> transactions;

  setUp(() {
    // `balance_visibility` false: the balance is shown.
    SharedPreferences.setMockInitialValues({'balance_visibility': false});
    transactions = StreamController<List<Transaction>>();
  });

  tearDown(() => transactions.close());

  testWidgets('the first data shows the rows without insert and without '
      'announcement', (tester) async {
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);

    expect(_inserts, findsNothing);
    expect(_messages(tester), isEmpty);
  });

  testWidgets('a new received row animates in and is announced', (
    tester,
  ) async {
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);
    _messages(tester);

    await _emit(tester, transactions, [_tx('c'), _tx('a'), _tx('b')]);
    await tester.pump(Motion.durationEmphasis ~/ 2);

    final insert = tester.widget<SizeTransition>(_inserts);
    expect(insert.sizeFactor.value, inExclusiveRange(0, 1));
    final messages = _messages(tester);
    expect(messages, hasLength(1));
    expect(messages.single, 'Recebeu ${Asset.lbtc.ticker}, +1.000 sats');

    await tester.pumpAndSettle();
    // The transition widgets go away when the insert ends.
    expect(_inserts, findsNothing);
  });

  testWidgets('a hidden balance hides the amount in the announcement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'balance_visibility': true});
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);
    _messages(tester);

    await _emit(tester, transactions, [_tx('c'), _tx('a'), _tx('b')]);
    expect(_messages(tester), ['Recebeu ${Asset.lbtc.ticker}']);

    await tester.pumpAndSettle();
  });

  testWidgets('a new sent row animates in without announcement', (
    tester,
  ) async {
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);
    _messages(tester);

    await _emit(tester, transactions, [
      _tx('c', type: TransactionType.send),
      _tx('a'),
      _tx('b'),
    ]);
    await tester.pump(Motion.durationEmphasis ~/ 2);

    expect(_inserts, findsOneWidget);
    expect(_messages(tester), isEmpty);

    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion inserts at once and still announces', (
    tester,
  ) async {
    reduceMotion(tester);
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);
    _messages(tester);

    await _emit(tester, transactions, [_tx('c'), _tx('a'), _tx('b')]);

    expect(_inserts, findsNothing);
    expect(_messages(tester), hasLength(1));
  });

  testWidgets('all new rows are a reload: no insert and no announcement', (
    tester,
  ) async {
    await _pumpList(tester, transactions);
    await _emit(tester, transactions, [_tx('a'), _tx('b')]);
    _messages(tester);

    await _emit(tester, transactions, [_tx('c'), _tx('d')]);

    expect(_inserts, findsNothing);
    expect(_messages(tester), isEmpty);
  });
}
