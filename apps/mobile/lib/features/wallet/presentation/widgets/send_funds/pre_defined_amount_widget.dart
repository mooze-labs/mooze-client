import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import 'send_flow_parts.dart';

/// The amount fixed by a payment request, drawn as the hero of the form.
///
/// The user cannot edit it. A lock icon next to the label and a note below
/// the amount say so.
class PreDefinedAmountWidget extends ConsumerWidget {
  const PreDefinedAmountWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final detectedAmount = ref.watch(detectedAmountProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    if (!detectedAmount.hasAmount) {
      return const SizedBox.shrink();
    }

    final asset = detectedAmount.asset ?? selectedAsset;
    final primary = _formatPrimaryAmount(detectedAmount.amountInSats!, asset);
    // The unit is the last word of the formatted amount.
    final split = primary.lastIndexOf(' ');
    final digits = split < 0 ? primary : primary.substring(0, split);
    final unit = split < 0 ? '' : primary.substring(split + 1);
    final quiet = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PixIcon(
              PixIcons.lock,
              size: 15,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(child: SendSectionLabel(t.wallet_send_predefined_label)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            SendAssetLogo(asset: asset, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: digits),
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: ' $unit',
                              style: context.textTheme.titleLarge?.copyWith(
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        fontFeatures: sendTabularFigures,
                      ),
                    ),
                  ),
                  if (detectedAmount.asset == Asset.btc ||
                      detectedAmount.asset == Asset.lbtc)
                    SendQuietText(
                      _formatSecondaryAmount(
                        detectedAmount.amountInSats!,
                        asset,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: context.colorScheme.outline),
        const SizedBox(height: 10),
        Text(t.wallet_send_predefined_body, style: quiet),
        if (detectedAmount.label != null) ...[
          const SizedBox(height: 6),
          Text(
            t.wallet_send_predefined_label_value(detectedAmount.label!),
            style: quiet?.copyWith(color: context.colors.textPrimary),
          ),
        ],
        if (detectedAmount.message != null) ...[
          const SizedBox(height: 4),
          Text(
            t.wallet_send_predefined_message_value(detectedAmount.message!),
            style: quiet?.copyWith(color: context.colors.textPrimary),
          ),
        ],
      ],
    );
  }

  String _formatPrimaryAmount(int satoshis, Asset asset) {
    if (asset == Asset.btc || asset == Asset.lbtc) {
      return '$satoshis SATS';
    }

    final amount = satoshis / 100000000;
    return '${amount.toStringAsFixed(2)} ${asset.ticker}';
  }

  String _formatSecondaryAmount(int satoshis, dynamic asset) {
    if (asset == Asset.btc || asset == Asset.lbtc) {
      if (satoshis >= 100000000) {
        final btc = satoshis / 100000000;
        return '${btc.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC';
      } else if (satoshis >= 100000) {
        final mbtc = satoshis / 100000;
        return '${mbtc.toStringAsFixed(3)} mBTC';
      } else if (satoshis >= 100) {
        final ubtc = satoshis / 100;
        return '${ubtc.toStringAsFixed(0)} µBTC';
      } else {
        return '$satoshis sats';
      }
    }

    return '$satoshis sats';
  }
}
