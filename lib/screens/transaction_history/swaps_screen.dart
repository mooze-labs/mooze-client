import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/database.dart';
import 'package:mooze_mobile/providers/multichain/swaps_provider.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';

class SwapsScreen extends ConsumerWidget {
  const SwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapsAsyncValue = ref.watch(swapsHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(swapsHistoryProvider);
      },
      child: swapsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [Center(child: Text("Erro: $error"))],
            ),
        data: (swaps) {
          if (swaps.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Text("Nenhum swap encontrado"),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            itemCount: swaps.length,
            itemBuilder: (context, index) {
              final swap = swaps[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  title: Text(
                    "#${swap.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_outward),
                          Text(
                            "${(swap.sendAmount / pow(10, 8)).toStringAsFixed(8)} ${AssetCatalog.getByLiquidAssetId(swap.sendAsset)?.ticker}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Image.asset(
                            AssetCatalog.getByLiquidAssetId(
                                  swap.sendAsset,
                                )?.logoPath ??
                                "",
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.call_received),
                          Text(
                            "${(swap.receiveAmount / pow(10, 8)).toStringAsFixed(8)} ${AssetCatalog.getByLiquidAssetId(swap.receiveAsset)?.ticker}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Image.asset(
                            AssetCatalog.getByLiquidAssetId(
                                  swap.receiveAsset,
                                )?.logoPath ??
                                "",
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                      Text(
                        "${DateFormat('dd/MM/yyyy HH:mm').format(swap.createdAt)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: "roboto",
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
