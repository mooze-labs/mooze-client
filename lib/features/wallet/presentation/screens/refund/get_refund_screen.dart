import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/refundable_swap_list.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
              ? _buildLoadingView(state, colorScheme)
              : state.error != null
              ? _buildErrorView(state.error!, colorScheme)
              : _buildRefreshableRefundablesList(state),
    );
  }

  Widget _buildLoadingView(RefundState state, ColorScheme colorScheme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 0.8,
          colors: [
            Color(0xFF1A0A1A),
            AppColors.backgroundColor,
            AppColors.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 3,
              ),
            ),
            if (state.currentRetry != null && state.maxRetries != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tentativa ${state.currentRetry! + 1} de ${state.maxRetries!}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aguarde, pode demorar um pouco...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshableRefundablesList(RefundState state) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(refundProvider.notifier).loadRefundData();
      },
      color: AppColors.primaryColor,
      backgroundColor: AppColors.backgroundCard,
      child: _buildRefundablesList(state),
    );
  }

  Widget _buildErrorView(String error, ColorScheme colorScheme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 0.8,
          colors: [
            Color(0xFF1A0A1A),
            AppColors.backgroundColor,
            AppColors.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
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
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Erro ao Carregar Dados',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefundablesList(RefundState state) {
    if (state.refundableSwaps == null || state.refundableSwaps!.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.4),
              radius: 0.8,
              colors: [
                Color(0xFF1A0A1A),
                AppColors.backgroundColor,
                AppColors.backgroundColor,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
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
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum Reembolso Disponível',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Você não tem transações pendentes de reembolso.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
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
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Puxe para baixo para atualizar',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
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
