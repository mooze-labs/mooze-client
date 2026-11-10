import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Info button of the send screen app bar. It is always visible.
///
/// It opens a floating glass sheet, as the info button of the receive
/// screen does. The sheet tells why a send needs L-BTC for the network
/// fee and has a shortcut to the swap screen.
///
/// Its last step tells about the custom fee of a Bitcoin on-chain send. A
/// second action opens the fee settings to turn it on, or to configure it
/// once it is on. The settings open on top of the send screen, so their
/// back button returns to the send.
class LbtcFeeInfoButton extends ConsumerWidget {
  const LbtcFeeInfoButton({super.key});

  /// Route of the fee settings.
  static const String feeSettingsRoute = '/settings/advanced/fees';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return IconButton(
      onPressed: () => _showLbtcInfo(context, ref),
      tooltip: t.wallet_send_lbtc_info_title,
      icon: PixIcon(PixIcons.info, size: 22, color: context.colors.textPrimary),
    );
  }

  void _showLbtcInfo(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final customFee = ref.read(sendCustomFeeEnabledProvider);
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
        (
          t.wallet_send_custom_fee_info_title,
          customFee
              ? t.wallet_send_custom_fee_info_on_desc
              : t.wallet_send_custom_fee_info_off_desc,
        ),
      ],
      actionLabel: t.wallet_send_lbtc_go_swap,
      onAction: () => context.go('/swap'),
      secondaryActionLabel: customFee
          ? t.wallet_send_custom_fee_configure
          : t.wallet_send_custom_fee_turn_on,
      onSecondaryAction: () => context.push(feeSettingsRoute),
    );
  }
}
