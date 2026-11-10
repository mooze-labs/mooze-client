import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_switch_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Advanced fee settings.
///
/// - The economic Bitcoin fee speed for BTC to L-BTC swaps. Turning it on
///   asks the user to accept the risk first: with a low fee the swap can
///   wait hours or days, and a dropped transaction sends the amount back to
///   the wallet. The warning stays on screen while the setting is on.
/// - A custom fee rate for Bitcoin on-chain sends. The send form warns
///   about a rate far from the network rates, so the switch asks nothing.
class FeeSettingsScreen extends ConsumerWidget {
  const FeeSettingsScreen({super.key});

  Future<void> _setLowFeeEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      final accepted = await _confirmLowFee(context);
      if (!accepted || !context.mounted) return;
    }
    await ref.read(pegLowFeeEnabledProvider.notifier).setEnabled(enabled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lowFee = ref.watch(pegLowFeeEnabledProvider);
    final customFee = ref.watch(sendCustomFeeEnabledProvider);

    return SettingsPageScaffold(
      title: t.settings_fees,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsGlassSection(
              title: t.swap_title.toUpperCase(),
              child: SettingsSwitchRow(
                title: t.low_fee_toggle_title,
                subtitle: t.low_fee_toggle_subtitle,
                toggle: Toggle(
                  value: lowFee,
                  onChange: (v) => _setLowFeeEnabled(context, ref, v),
                ),
              ),
            ),
            if (lowFee) _LowFeeWarning(message: t.low_fee_warning_message),
            SettingsGlassSection(
              title: t.wallet_send_appbar_title.toUpperCase(),
              child: SettingsSwitchRow(
                title: t.custom_fee_toggle_title,
                subtitle: t.custom_fee_toggle_subtitle,
                toggle: Toggle(
                  value: customFee,
                  onChange: (v) => ref
                      .read(sendCustomFeeEnabledProvider.notifier)
                      .setEnabled(v),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks the user to accept the risk of the economic fee in a floating glass
/// sheet. Returns true when the user turns it on. Closing the sheet any
/// other way keeps it off.
Future<bool> _confirmLowFee(BuildContext context) async {
  final accepted = await showFloatingGlassSheet<bool>(
    context,
    builder: (_) => const _LowFeeWarningSheet(),
  );
  return accepted ?? false;
}

/// The risk of the economic fee, with the warning badge before the title,
/// the action to turn it on, and a neutral way back.
class _LowFeeWarningSheet extends StatelessWidget {
  const _LowFeeWarningSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(
            title: t.low_fee_warning_title,
            leading: GlassSheetBadge(
              icon: PixIcons.warning,
              color: context.appColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                t.low_fee_warning_message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PrimaryButton(
              text: t.low_fee_warning_confirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                // The way back stays neutral. The brand color is for the
                // main action.
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(64, 48),
              ),
              child: Text(t.common_cancel),
            ),
          ),
        ],
      ),
    );
  }
}

/// The risk of the economic fee, under the switch while it is on. The icon
/// and the tint carry the warning color; the text keeps the primary text
/// color, so it stays readable.
class _LowFeeWarning extends StatelessWidget {
  final String message;

  const _LowFeeWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixIcon(PixIcons.warning, size: 20, color: warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
