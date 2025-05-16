import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/multichain/transaction_history_provider.dart';
import 'package:mooze_mobile/screens/transaction_history/widgets/transaction_display.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/screens/transaction_history/swaps_screen.dart';
import 'package:mooze_mobile/screens/transaction_history/pegs_screen.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _TransactionsTab(),
    SwapsScreen(),
    PegsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: _getScreenTitle()),
      drawer: MoozeDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transações',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swaps'),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Pegs',
          ),
        ],
      ),
    );
  }

  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0:
        return "Histórico de transações";
      case 1:
        return "Histórico de swaps";
      case 2:
        return "Histórico de pegs";
      default:
        return "Histórico de transações";
    }
  }
}

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);

    return Column(
      children: [
        _buildFilterControls(context, ref, filters),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(transactionHistoryProvider.notifier).refresh();
            },
            child: filteredTransactions.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [Center(child: Text("Erro: $error"))],
                  ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Text("Nenhuma transação encontrada"),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder:
                      (context, index) =>
                          TransactionDisplay(transaction: transactions[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    WidgetRef ref,
    TransactionFilters filters,
  ) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            DropdownButtonFormField<Asset?>(
              value: filters.selectedAsset,
              decoration: InputDecoration(
                labelText: 'Filtrar por ativo',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Todos os ativos')),
                ...AssetCatalog.all
                    .map(
                      (asset) => DropdownMenuItem(
                        value: asset,
                        child: Text(asset.ticker),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (asset) {
                ref
                    .read(transactionFiltersProvider.notifier)
                    .state = TransactionFilters(
                  selectedAsset: asset,
                  startDate: filters.startDate,
                  endDate: filters.endDate,
                );
              },
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(
                      filters.startDate != null && filters.endDate != null
                          ? '${filters.startDate!.toString().split(' ')[0]} - ${filters.endDate!.toString().split(' ')[0]}'
                          : 'Selecione o período',
                    ),
                    onPressed: () async {
                      final dateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange:
                            filters.startDate != null && filters.endDate != null
                                ? DateTimeRange(
                                  start: filters.startDate!,
                                  end: filters.endDate!,
                                )
                                : null,
                      );
                      if (dateRange != null) {
                        ref
                            .read(transactionFiltersProvider.notifier)
                            .state = TransactionFilters(
                          selectedAsset: filters.selectedAsset,
                          startDate: dateRange.start,
                          endDate: dateRange.end,
                        );
                      }
                    },
                  ),
                ),
                if (filters.startDate != null || filters.endDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      ref
                          .read(transactionFiltersProvider.notifier)
                          .state = TransactionFilters(
                        selectedAsset: filters.selectedAsset,
                        startDate: null,
                        endDate: null,
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
