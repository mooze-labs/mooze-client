import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Dialog shown when the user attempts to send DEPIX or USDT without
/// sufficient L-BTC balance to cover network mining fees.
///
/// The dialog is opaque Liquid Glass. "Go to SWAP" is the main action.
class LbtcInsufficientFundsDialog extends StatefulWidget {
  final Asset asset;

  const LbtcInsufficientFundsDialog({super.key, required this.asset});

  /// Returns `true` if the user wants to go to SWAP, `false` otherwise.
  static Future<bool?> show(BuildContext context, {required Asset asset}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => LbtcInsufficientFundsDialog(asset: asset),
    );
  }

  @override
  State<LbtcInsufficientFundsDialog> createState() =>
      _LbtcInsufficientFundsDialogState();
}

class _LbtcInsufficientFundsDialogState
    extends State<LbtcInsufficientFundsDialog> {
  // Properly managed recognizer — disposed in dispose()
  late final TapGestureRecognizer _swapRecognizer;

  @override
  void initState() {
    super.initState();
    _swapRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _swapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final assetName = widget.asset == Asset.depix ? 'DePIX' : 'USDT';

    return GlassAlertDialog(
      title: Column(
        children: [
          const PixIconWell(
            icon: PixIcons.deposit,
            tone: PixTone.warning,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            t.wallet_send_lbtc_insufficient_title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.wallet_send_lbtc_insufficient_body(assetName),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwapOption(context),
            const SizedBox(height: 12),
            _buildLightningOption(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
            minimumSize: const Size(64, 48),
          ),
          child: Text(t.common_understood),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primaryColor,
            foregroundColor: context.colorScheme.onPrimary,
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(t.wallet_send_lbtc_go_swap),
        ),
      ],
    );
  }

  TextStyle? _optionStyle(BuildContext context) => context.textTheme.bodySmall
      ?.copyWith(color: context.colors.textSecondary, height: 1.4);

  Widget _buildSwapOption(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PixIconWell(icon: PixIcons.exchange, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: _optionStyle(context),
                children: [
                  TextSpan(text: t.wallet_send_lbtc_insufficient_swap_prefix),
                  TextSpan(
                    text: 'SWAP',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    // Reuses the state-managed recognizer — no leak
                    recognizer: _swapRecognizer,
                  ),
                  TextSpan(text: t.wallet_send_lbtc_insufficient_swap_suffix),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightningOption(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PixIconWell(icon: PixIcons.fast, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.wallet_send_lbtc_insufficient_lightning,
              style: _optionStyle(context),
            ),
          ),
        ),
      ],
    );
  }
}
