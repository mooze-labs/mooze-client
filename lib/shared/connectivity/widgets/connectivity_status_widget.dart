import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';

class ConnectivityStatusWidget extends ConsumerStatefulWidget {
  const ConnectivityStatusWidget({super.key});

  @override
  ConsumerState<ConnectivityStatusWidget> createState() =>
      _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState
    extends ConsumerState<ConnectivityStatusWidget> {
  ConnectivityResult? _currentConnectivity;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _getCurrentConnectivity();
  }

  Future<void> _getCurrentConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _currentConnectivity =
          result.isNotEmpty ? result.first : ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final connectivityState = ref.watch(connectivityProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status de Conectividade',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildStatusRow(
              'Rede Disponível (connectivity_plus)',
              _getConnectivityIcon(_currentConnectivity),
              _getConnectivityText(_currentConnectivity),
              _getConnectivityColor(_currentConnectivity),
            ),

            const SizedBox(height: 8),

            _buildStatusRow(
              'Internet Real (DNS + APIs)',
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              isOnline ? 'Online' : 'Offline',
              isOnline ? Colors.green : Colors.orange,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sistema Híbrido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. connectivity_plus detecta mudanças de rede (WiFi/Mobile/None)\n'
                    '2. Quando há rede, verificamos internet real via DNS lookup\n'
                    '3. APIs também atualizam status baseado em sucesso/falha\n'
                    '4. Timer backup verifica a cada 30s como fallback',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(connectivityCheckerProvider)();
                  await _getCurrentConnectivity();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Verificar Conectividade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Última verificação: ${_formatDateTime(connectivityState.lastUpdate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    IconData icon,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getConnectivityIcon(ConnectivityResult? result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.cable;
      case ConnectivityResult.none:
      case null:
        return Icons.signal_wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  String _getConnectivityText(ConnectivityResult? result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
      case null:
        return 'Sem Rede';
      default:
        return 'Desconhecido';
    }
  }

  Color _getConnectivityColor(ConnectivityResult? result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return Colors.green;
      case ConnectivityResult.none:
      case null:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
