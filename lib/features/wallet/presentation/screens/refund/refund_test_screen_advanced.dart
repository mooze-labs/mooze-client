import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider_mock.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_mock_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/get_refund_screen.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Tela de teste avançada para o fluxo de refund
///
/// Esta tela permite testar todo o fluxo de refund usando dados mockados,
/// baseados em transações reais de Peg In que falharam.
///
/// Funcionalidades:
/// - Injeta transação Peg In refundable (baseada em TX real: 5e2159e9...)
/// - Injeta transação Peg Out refundable para comparação
/// - Testa fluxo completo de refund com SDK mockado
/// - Visualiza detalhes das transações mockadas
/// - Permite limpar/recarregar transações
///
/// Para acessar:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const RefundTestScreenAdvanced()),
/// );
/// ```
class RefundTestScreenAdvanced extends ConsumerStatefulWidget {
  static const String routeName = '/refund_test_advanced';

  const RefundTestScreenAdvanced({super.key});

  @override
  ConsumerState<RefundTestScreenAdvanced> createState() =>
      _RefundTestScreenAdvancedState();
}

class _RefundTestScreenAdvancedState
    extends ConsumerState<RefundTestScreenAdvanced> {
  bool _mockTransactionsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final mockTransactions = ref.watch(transactionMockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Teste de Refund Avançado'),
        backgroundColor: context.colors.backgroundColor,
        actions: [
          if (_mockTransactionsLoaded)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Limpar transações mock',
              onPressed: () {
                ref
                    .read(transactionMockProvider.notifier)
                    .clearMockTransactions();
                setState(() => _mockTransactionsLoaded = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transações mockadas removidas'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
      backgroundColor: context.colors.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.science, size: 80, color: context.colors.primaryColor),
            const SizedBox(height: 32),
            Text(
              'Teste de Refund com\nTransações Reais',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Simule transações Peg In refundable baseadas em\n'
              'dados reais para testar o fluxo completo de reembolso.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Botão para carregar transações mock
            if (!_mockTransactionsLoaded)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: Text(
                    'Carregar Transações Mock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ref
                        .read(transactionMockProvider.notifier)
                        .loadDefaultMockTransactions();
                    setState(() => _mockTransactionsLoaded = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${ref.read(transactionMockProvider).length} transações mockadas carregadas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),

            // Mostra lista de transações mockadas
            if (_mockTransactionsLoaded && mockTransactions.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: context.colors.primaryColor,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Transações Mockadas (${mockTransactions.length})',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    ...mockTransactions.asMap().entries.map(
                      (entry) => _buildTransactionCard(entry.value, entry.key),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Botões de ação
            if (_mockTransactionsLoaded) ...[
              // Botão para testar refund com dados mock do SDK
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet, size: 24),
                  label: const Text(
                    'Testar Fluxo de Refund (Mock SDK)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navega para tela de refund com provider mockado
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => ProviderScope(
                              overrides: [
                                refundProvider.overrideWith(
                                  (ref) => MockRefundNotifier(ref),
                                ),
                              ],
                              child: const GetRefundScreen(),
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botão para testar com SDK real
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud, size: 24),
                label: const Text(
                  'Testar com SDK Real',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GetRefundScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 48),

            // Informações detalhadas sobre a transação real
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.colors.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sobre a Transação Real',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('🔹 Tipo: Peg In (BTC → LBTC)'),
                  _buildInfoRow('🔹 TX ID: 5e2159e9b5fbf7023b2800...'),
                  _buildInfoRow(
                    '🔹 Valor enviado: 52574 sats (402 sats de taxa)',
                  ),
                  _buildInfoRow('🔹 Valor esperado: 52172 sats (LBTC)'),
                  _buildInfoRow('🔹 Data: 04/02/2026 às 00:17:10'),
                  _buildInfoRow('🔹 Lockup TX: 2622dd4f5a1c69f7cea5...'),
                  _buildInfoRow('🔹 Endereço: bc1p62e2r4jnr3v985uqk...'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: REFUNDABLE\nEsta transação falhou e os fundos podem ser reembolsados para o endereço Bitcoin original.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx, int index) {
    final isRefundable = tx.status == TransactionStatus.refundable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isRefundable
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isRefundable
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRefundable ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRefundable ? 'REFUNDABLE' : 'CONFIRMED',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isRefundable ? Icons.warning_amber : Icons.check_circle,
                color: isRefundable ? Colors.orange : Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tx.fromAsset?.name.toUpperCase()} → ${tx.toAsset?.name.toUpperCase()}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Valor: ${tx.amount} sats',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            'ID: ${tx.id.length > 20 ? '${tx.id.substring(0, 20)}...' : tx.id}',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          if (tx.destination != null)
            Text(
              'Para: ${tx.destination!.length > 25 ? '${tx.destination!.substring(0, 25)}...' : tx.destination!}',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
