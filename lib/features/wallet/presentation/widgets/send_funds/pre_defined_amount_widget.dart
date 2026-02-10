import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import '../../providers/send_funds/detected_amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class PreDefinedAmountWidget extends ConsumerWidget {
  const PreDefinedAmountWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectedAmount = ref.watch(detectedAmountProvider);
    final selectedAsset = ref.watch(selectedAssetProvider);

    if (!detectedAmount.hasAmount) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.pinBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Valor pré-definido',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              SvgPicture.asset(
                (detectedAmount.asset ?? selectedAsset).iconPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatPrimaryAmount(
                        detectedAmount.amountInSats!,
                        detectedAmount.asset ?? selectedAsset,
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detectedAmount.asset == Asset.btc ||
                        detectedAmount.asset == Asset.lbtc)
                      Text(
                        _formatSecondaryAmount(
                          detectedAmount.amountInSats!,
                          detectedAmount.asset ?? selectedAsset,
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Este invoice/endereço possui um valor pré-definido. O campo de quantia foi automaticamente preenchido.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
          ),

          if (detectedAmount.label != null ||
              detectedAmount.message != null) ...[
            const SizedBox(height: 12),
            if (detectedAmount.label != null) ...[
              Text(
                'Label: ${detectedAmount.label}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
              ),
            ],
            if (detectedAmount.message != null) ...[
              const SizedBox(height: 4),
              Text(
                'Mensagem: ${detectedAmount.message}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[300]),
              ),
            ],
          ],
        ],
      ),
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
