import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/database.dart';
import 'package:mooze_mobile/providers/multichain/pegs_provider.dart';
import 'package:mooze_mobile/screens/swap/check_peg_status.dart';

class PegsScreen extends ConsumerWidget {
  const PegsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pegsAsyncValue = ref.watch(pegsHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(pegsHistoryProvider);
      },
      child: pegsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [Center(child: Text("Erro: $error"))],
            ),
        data: (pegs) {
          if (pegs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Text("Nenhum peg encontrado"),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            itemCount: pegs.length,
            itemBuilder: (context, index) {
              final peg = pegs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        "#${peg.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ID: ${peg.orderId}"),
                          Text("Tipo: ${peg.pegIn ? 'Peg-in' : 'Peg-out'}"),
                          Text(
                            "Endereço de depósito:\n${peg.pegIn ? peg.sideswapAddress : peg.payoutAddress}",
                          ),
                          Text(
                            "Endereço de retirada:\n${peg.pegIn ? peg.payoutAddress : peg.sideswapAddress}",
                          ),
                          Text(
                            "${DateFormat('dd/MM/yyyy HH:mm').format(peg.createdAt)}",
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
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Verificar status"),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => CheckPegStatusScreen(
                                        orderId: peg.orderId,
                                        pegIn: peg.pegIn,
                                      ),
                                ),
                              );
                            },
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
      ),
    );
  }
}
