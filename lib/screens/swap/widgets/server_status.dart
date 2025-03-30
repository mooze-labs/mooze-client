import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';

class ServerStatusDisplay extends ConsumerWidget {
  final Future<ServerStatus?> serverStatusFuture;
  final bool pegIn;

  const ServerStatusDisplay({
    super.key,
    required this.serverStatusFuture,
    required this.pegIn,
  });

  Widget _buildDisplayRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: "roboto",
            fontSize: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideswapClient = ref.read(sideswapRepositoryProvider);

    return StreamBuilder<int>(
      stream: sideswapClient.pegInWalletBalanceStream,
      builder: (context, pegInSnapshot) {
        return StreamBuilder<int>(
          stream: sideswapClient.pegOutWalletBalanceStream,
          builder: (context, pegOutSnapshot) {
            return FutureBuilder<ServerStatus?>(
              future: serverStatusFuture,
              builder: (context, serverSnapshot) {
                // Show loading indicator if any data is still loading
                if (serverSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // If there's an error with server status
                if (serverSnapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Erro ao carregar status do servidor: ${serverSnapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  );
                }

                // Get values from stream snapshots with fallbacks
                final pegInWalletBalance =
                    pegInSnapshot.hasData ? pegInSnapshot.data! : 0;

                final pegOutWalletBalance =
                    pegOutSnapshot.hasData ? pegOutSnapshot.data! : 0;

                // Get server status values with fallbacks
                final minPegInAmount =
                    serverSnapshot.hasData
                        ? serverSnapshot.data!.minPegInAmount
                        : 0;

                final minPegOutAmount =
                    serverSnapshot.hasData
                        ? serverSnapshot.data!.minPegOutAmount
                        : 0;

                // Build the actual widget with all values
                return Container(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDisplayRow(
                              context,
                              "Taxa de conversão",
                              "0.1%",
                            ),
                            (pegIn)
                                ? Column(
                                  children: [
                                    _buildDisplayRow(
                                      context,
                                      "Valor mínimo para peg-in",
                                      "${(minPegInAmount / pow(10, 8)).toStringAsFixed(8)}",
                                    ),
                                    _buildDisplayRow(
                                      context,
                                      "Valor máximo para peg-in",
                                      "${(pegInWalletBalance / pow(10, 8)).toStringAsFixed(8)}",
                                    ),
                                  ],
                                )
                                : Column(
                                  children: [
                                    _buildDisplayRow(
                                      context,
                                      "Valor mínimo para peg-out",
                                      "${(minPegOutAmount / pow(10, 8)).toStringAsFixed(8)}",
                                    ),
                                    _buildDisplayRow(
                                      context,
                                      "Valor máximo para peg-out",
                                      "${(pegOutWalletBalance / pow(10, 8)).toStringAsFixed(8)}",
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
