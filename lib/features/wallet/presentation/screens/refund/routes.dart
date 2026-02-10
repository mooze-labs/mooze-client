import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/get_refund_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/refund_confirmation_screen.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';

/// Rotas para o fluxo de refund
///
/// Para integrar no seu sistema de rotas, adicione estas rotas ao GoRouter:
///
/// ```dart
/// ...refundRoutes,
/// ```
final refundRoutes = [
  GoRoute(
    path: '/refund',
    name: GetRefundScreen.routeName,
    builder: (context, state) => const GetRefundScreen(),
  ),
  GoRoute(
    path: '/refund/:swapAddress',
    name: RefundScreen.routeName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;

      if (extra == null || extra['swapInfo'] == null) {
        // Se não tiver swapInfo, redireciona para lista
        return const GetRefundScreen();
      }

      final swapInfo = extra['swapInfo'] as RefundableSwap;
      return RefundScreen(swapInfo: swapInfo);
    },
  ),
  GoRoute(
    path: '/refund/confirmation',
    name: RefundConfirmationScreen.routeName,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;

      if (extra == null || extra['refundParams'] == null) {
        // Se não tiver refundParams, volta para lista
        return const GetRefundScreen();
      }

      final refundParams = extra['refundParams'] as RefundParams;
      return RefundConfirmationScreen(refundParams: refundParams);
    },
  ),
];

/// Exemplo de navegação usando rotas nomeadas:
/// 
/// ```dart
/// // Navegar para lista de refunds
/// context.go('/refund');
/// 
/// // Ou usando Navigator tradicional
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => const GetRefundScreen(),
///   ),
/// );
/// 
/// // Navegar para detalhes de um swap específico
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => RefundScreen(swapInfo: swapInfo),
///   ),
/// );
/// ```
