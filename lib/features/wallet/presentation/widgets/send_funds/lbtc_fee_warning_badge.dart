import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    InfoOverlay.show(
      context,
      title: t.wallet_send_lbtc_info_title,
      steps: [
        InfoStep(
          icon: Icons.account_balance_wallet_outlined,
          title: t.wallet_send_lbtc_info_step1_title,
          description: t.wallet_send_lbtc_info_step1_desc,
        ),
        InfoStep(
          icon: Icons.swap_horiz,
          title: t.wallet_send_lbtc_obtain_title,
          description: t.wallet_send_lbtc_obtain_desc_info,
        ),
        InfoStep(
          icon: Icons.bolt,
          title: t.wallet_send_lbtc_info_step3_title,
          description: t.wallet_send_lbtc_info_step3_desc,
        ),
      ],
      footerBuilder:
          (closeOverlay) => SecondaryButton(
            text: t.wallet_send_lbtc_go_swap,
            onPressed: () {
              closeOverlay();
              context.go('/swap');
            },
          ),
    );
  }
}