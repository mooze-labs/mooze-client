import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Dialog shown when the user attempts to send DEPIX or USDT without
/// sufficient L-BTC balance to cover network mining fees.
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
    _swapRecognizer =
        TapGestureRecognizer()
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final assetName = widget.asset == Asset.depix ? 'DePIX' : 'USDT';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: colorScheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.wallet_send_lbtc_insufficient_title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.wallet_send_lbtc_insufficient_body(assetName),
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildSwapOption(context, colorScheme, textTheme),
          const SizedBox(height: 10),
          _buildLightningOption(context, colorScheme, textTheme),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(t.common_understood),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(t.wallet_send_lbtc_go_swap),
        ),
      ],
    );
  }

  Widget _buildSwapOption(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(colorScheme, Icons.swap_horiz),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: RichText(
              text: TextSpan(
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: t.wallet_send_lbtc_insufficient_swap_prefix),
                  TextSpan(
                    text: 'SWAP',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildLightningOption(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(colorScheme, Icons.bolt),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              t.wallet_send_lbtc_insufficient_lightning,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBadge(ColorScheme colorScheme, IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, size: 16, color: colorScheme.primary)),
    );
  }
}
