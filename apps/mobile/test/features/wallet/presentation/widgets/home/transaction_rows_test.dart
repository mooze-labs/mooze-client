import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/transaction_list.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';

import '../../../../../shared/test_app.dart';

Transaction _tx(
  String id,
  DateTime createdAt, {
  TransactionType type = TransactionType.receive,
}) {
  return Transaction(
    id: id,
    amount: BigInt.from(1000),
    blockchain: Blockchain.liquid,
    asset: Asset.lbtc,
    type: type,
    status: TransactionStatus.confirmed,
    createdAt: createdAt,
  );
}

Transaction _swap(String id, DateTime createdAt) {
  return Transaction(
    id: id,
    amount: BigInt.from(113500),
    blockchain: Blockchain.liquid,
    asset: Asset.lbtc,
    type: TransactionType.swap,
    status: TransactionStatus.confirmed,
    createdAt: createdAt,
    fromAsset: Asset.depix,
    toAsset: Asset.lbtc,
    sentAmount: BigInt.from(500000000),
    receivedAmount: BigInt.from(113500),
  );
}

Widget _list(
  List<Transaction> transactions, {
  bool groupByDate = true,
  bool hidden = false,
  List<Widget> leadingRows = const [],
}) {
  return ProviderScope(
    child: wrapForTest(
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SuccessfulTransactionList(
            transactions: transactions,
            // `isVisible` is true when the balance is hidden.
            isVisible: hidden,
            groupByDate: groupByDate,
            leadingRows: leadingRows,
          ),
        ),
      ),
    ),
  );
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final todayNoon = DateTime(today.year, today.month, today.day, 12);
  final yesterdayNoon = DateTime(today.year, today.month, today.day - 1, 12);
  final lastYear = DateTime(today.year - 1, 3, 5, 9, 30);

  group('Grouped by date', () {
    testWidgets('shows one header and one panel per day', (tester) async {
      await tester.pumpWidget(
        _list([
          _tx('a', todayNoon),
          _tx('b', todayNoon),
          _tx('c', yesterdayNoon),
          _tx('d', lastYear),
        ]),
      );

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Ontem'), findsOneWidget);
      expect(
        find.text(DateFormat('d MMM y', 'pt').format(lastYear)),
        findsOneWidget,
      );
      expect(find.byType(AppPanel), findsNWidgets(3));
    });

    testWidgets('rows show the status and the time, without the day', (
      tester,
    ) async {
      await tester.pumpWidget(_list([_tx('a', todayNoon)]));
      expect(find.text('Confirmado · 12:00'), findsOneWidget);
    });
  });

  group('One panel (home preview)', () {
    testWidgets('shows no headers and puts the day next to the time', (
      tester,
    ) async {
      await tester.pumpWidget(
        _list([
          _tx('a', todayNoon),
          _tx('b', yesterdayNoon),
        ], groupByDate: false),
      );

      expect(find.byType(AppPanel), findsOneWidget);
      expect(find.text('Hoje'), findsNothing);
      expect(find.text('Confirmado · Hoje, 12:00'), findsOneWidget);
      expect(find.text('Confirmado · Ontem, 12:00'), findsOneWidget);
    });

    testWidgets('puts the leading rows in the same panel', (tester) async {
      await tester.pumpWidget(
        _list(
          [_tx('a', todayNoon)],
          groupByDate: false,
          leadingRows: const [Text('Swap em andamento')],
        ),
      );

      expect(find.byType(AppPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppPanel),
          matching: find.text('Swap em andamento'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the leading rows without other rows', (tester) async {
      await tester.pumpWidget(
        _list(
          const [],
          groupByDate: false,
          leadingRows: const [Text('Swap em andamento')],
        ),
      );

      expect(find.text('Swap em andamento'), findsOneWidget);
      expect(find.byType(EmptyTransactionList), findsNothing);
    });
  });

  group('Swap rows', () {
    testWidgets('show the received and the sent amounts on the right', (
      tester,
    ) async {
      await tester.pumpWidget(_list([_swap('s', todayNoon)]));

      expect(
        find.text('+${Asset.lbtc.formatBalance(BigInt.from(113500))}'),
        findsOneWidget,
      );
      expect(find.text(r'-R$5.00'), findsOneWidget);
    });

    testWidgets('hide both amounts with the balance', (tester) async {
      await tester.pumpWidget(_list([_swap('s', todayNoon)], hidden: true));

      expect(find.text(r'-R$5.00'), findsNothing);
      expect(find.text('•••••••'), findsOneWidget);
    });
  });
}
