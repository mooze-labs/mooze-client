import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_notice_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Notice about swaps between Bitcoin and L-BTC, shown the first time the
/// user picks that pair, in a floating glass sheet.
///
/// SideSwap runs the peg: it takes from 20 minutes to about 17 hours, it
/// charges 0.1% plus the network fee, and it returns an L-BTC deposit below
/// its minimum to the wallet (the core registers the return address of
/// each peg-out). The user reads it before the swap: a tap outside or a
/// drag does not close the sheet, and the accept button unlocks after
/// [readingSeconds].
class BtcLbtcSwapWarningSheet extends StatelessWidget {
  const BtcLbtcSwapWarningSheet({super.key});

  /// Reading time of the notice. It is longer than the Pix notices: it has
  /// four points about time, fees and returns.
  static const int readingSeconds = 10;

  static Future<void> show(BuildContext context) {
    return showFloatingGlassSheet<void>(
      context,
      dismissible: false,
      builder: (context) => const BtcLbtcSwapWarningSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixNoticeSheet(
      // An attention notice: the warning tone, the swap shape, and the
      // title together carry the meaning.
      icon: PixIcons.exchange,
      tone: PixTone.warning,
      title: t.swap_btc_lbtc_warning_title,
      intro: t.swap_btc_lbtc_warning_intro,
      actionLabel: t.swap_btc_lbtc_warning_accept_button,
      onAction: () => Navigator.of(context).pop(),
      readingSeconds: readingSeconds,
      countingLabel: t.swap_btc_lbtc_warning_accept_button_counting,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PointRow(
            icon: PixIcons.bitcoin,
            text: t.swap_btc_lbtc_warning_provider,
          ),
          const SizedBox(height: 14),
          _PointRow(icon: PixIcons.clock, text: t.swap_btc_lbtc_warning_timing),
          const SizedBox(height: 14),
          _PointRow(icon: PixIcons.percent, text: t.swap_btc_lbtc_warning_fee),
          const SizedBox(height: 14),
          _PointRow(
            icon: PixIcons.restart,
            text: t.swap_btc_lbtc_warning_peg_out_return,
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: AppSurfaces.hairline(context),
          ),
          const SizedBox(height: 16),
          PixNoticeNote(
            icon: PixIcons.shieldCheck,
            text: t.swap_btc_lbtc_warning_funds_safe,
          ),
        ],
      ),
    );
  }
}

/// One point of the notice: an icon well and its text.
class _PointRow extends StatelessWidget {
  const _PointRow({required this.icon, required this.text});

  final PixIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixIconWell(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            // Centers the first line of text on the well.
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
