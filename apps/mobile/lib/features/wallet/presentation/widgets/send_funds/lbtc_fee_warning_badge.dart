import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Info button of the send screen app bar. It is always visible.
///
/// It opens a floating glass sheet, as the info button of the receive
/// screen does. The sheet tells why a send needs L-BTC for the network
/// fee and has a shortcut to the swap screen.
class LbtcFeeInfoButton extends StatelessWidget {
  const LbtcFeeInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return IconButton(
      onPressed: () => _showLbtcInfo(context),
      tooltip: t.wallet_send_lbtc_info_title,
      icon: PixIcon(PixIcons.info, size: 22, color: context.colors.textPrimary),
    );
  }

  void _showLbtcInfo(BuildContext context) {
    final t = AppLocalizations.of(context);
    showGlassInfoSheet(
      context,
      title: t.wallet_send_lbtc_info_title,
      steps: [
        (
          t.wallet_send_lbtc_info_step1_title,
          t.wallet_send_lbtc_info_step1_desc,
        ),
        (t.wallet_send_lbtc_obtain_title, t.wallet_send_lbtc_obtain_desc_info),
        (
          t.wallet_send_lbtc_info_step3_title,
          t.wallet_send_lbtc_info_step3_desc,
        ),
      ],
      actionLabel: t.wallet_send_lbtc_go_swap,
      onAction: () => context.go('/swap'),
    );
  }
}
