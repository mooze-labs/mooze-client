import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/multichain/transaction_history_provider.dart';
import 'package:mooze_mobile/screens/transaction_history/widgets/transaction_display.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);

    return Scaffold(
      appBar: MoozeAppBar(title: "Histórico de transações"),
      drawer: MoozeDrawer(),
      body: Column(
        children: [
          _buildFilterControls(context, ref, filters),
          Expanded(
            child: filteredTransactions.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text("Erro: $error")),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(child: Text("Nenhuma transação encontrada"));
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
        ],
      ),
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
