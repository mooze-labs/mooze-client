import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Always-visible AppBar info button — mirrors the PIX screen's info button.
/// Explains why L-BTC is required and offers a shortcut to SWAP.
class LbtcFeeInfoButton extends StatelessWidget {
  const LbtcFeeInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showLbtcInfo(context),
      icon: const Icon(Icons.info_outline_rounded),
    );
  }

  void _showLbtcInfo(BuildContext context) {
    InfoOverlay.show(
      context,
      title: 'Informações sobre taxas',
      steps: [
        InfoStep(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Bitcoin L2 para taxas de rede',
          description:
              'Para enviar DePIX, USDT ou qualquer ativo da rede Liquid, '
              'você precisa ter Bitcoin L2 (Liquid Bitcoin) na carteira. '
              'Ele é usado para pagar os mineradores da rede.',
        ),
        InfoStep(
          icon: Icons.swap_horiz,
          title: 'Como obter Bitcoin L2',
          description:
              'Use a função SWAP para converter Bitcoin (Lightning ou '
              'on-chain) em Bitcoin L2 diretamente no aplicativo.',
        ),
        InfoStep(
          icon: Icons.bolt,
          title: 'Receba via Lightning ou Liquid',
          description:
              'Receba Bitcoin via Lightning Network ou Liquid para obter '
              'Bitcoin L2 na sua carteira sem usar o SWAP.',
        ),
      ],
      footerBuilder:
          (closeOverlay) => SecondaryButton(
            text: 'Ir para SWAP',
            onPressed: () {
              closeOverlay();
              context.go('/swap');
            },
          ),
    );
  }
}