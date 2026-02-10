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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reembolsos Disponíveis'),
        backgroundColor: AppColors.backgroundColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
              ? _buildErrorView(state.error!)
              : _buildRefundablesList(state),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(refundProvider.notifier).loadRefundData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.backgroundColor,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundablesList(RefundState state) {
    if (state.refundableSwaps == null || state.refundableSwaps!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum Reembolso Disponível',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você não tem transações pendentes de reembolso.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
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
