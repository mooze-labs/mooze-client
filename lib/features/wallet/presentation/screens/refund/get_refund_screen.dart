import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/refundable_swap_list.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Screen to display list of refundable swaps
class GetRefundScreen extends ConsumerStatefulWidget {
  static const String routeName = '/get_refund';

  const GetRefundScreen({super.key});

  @override
  ConsumerState<GetRefundScreen> createState() => _GetRefundScreenState();
}

class _GetRefundScreenState extends ConsumerState<GetRefundScreen> {
  @override
  void initState() {
    super.initState();
    // Load refund data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refundProvider.notifier).loadRefundData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refundProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reembolsos Disponíveis'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Voltar',
        ),
      ),
      body:
          state.isLoading
              ? _buildLoadingView(state)
              : state.error != null
              ? _buildErrorView(state.error!)
              : _buildRefreshableRefundablesList(state),
    );
  }

  Widget _buildLoadingView(RefundState state) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.backgroundCard.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircularProgressIndicator(
              color: context.colors.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (state.currentRetry != null && state.maxRetries != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: context.colors.backgroundCard.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Tentativa ${state.currentRetry! + 1} de ${state.maxRetries!}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aguarde, pode demorar um pouco...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshableRefundablesList(RefundState state) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(refundProvider.notifier).loadRefundData();
      },
      color: context.colors.primaryColor,
      backgroundColor: context.colors.backgroundCard,
      child: _buildRefundablesList(state),
    );
  }

  Widget _buildErrorView(String error) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.colors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Erro ao Carregar Dados',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(refundProvider.notifier).loadRefundData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryColor,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tentar Novamente',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefundablesList(RefundState state) {
    if (state.refundableSwaps == null || state.refundableSwaps!.isEmpty) {
      final colorScheme = context.colorScheme;
      final textTheme = context.textTheme;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.colors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.tertiary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum Reembolso Disponível',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Você não tem transações pendentes de reembolso.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.colors.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: context.colors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Puxe para baixo para atualizar',
                            style: textTheme.labelMedium?.copyWith(
                              color: context.colors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefundableSwapList(
      refundables: state.refundableSwaps!,
      onSwapTap: (swap) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RefundScreen(swapInfo: swap)));
      },
    );
  }
}
