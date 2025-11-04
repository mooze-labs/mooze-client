import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';

class ReceiveConversionOptionsRow extends ConsumerWidget {
  final Asset? selectedAsset;

  const ReceiveConversionOptionsRow({super.key, required this.selectedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(receiveConversionTypeProvider);
    final currencyNotifier = ref.read(currencyControllerProvider.notifier);
    final fiatCurrency = currencyNotifier.icon;
    final controller = ref.read(receiveConversionControllerProvider.notifier);

    return Row(
      children: [
        _ConversionOption(
          icon: Icons.account_balance_wallet,
          label: selectedAsset!.ticker,
          isSelected: conversionType == ReceiveConversionType.asset,
          onTap:
              () => controller.changeConversionType(
                ReceiveConversionType.asset,
                selectedAsset!,
              ),
        ),
        const SizedBox(width: 8),
        if (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) ...[
          _ConversionOption(
            icon: Icons.bolt,
            label: 'sats',
            isSelected: conversionType == ReceiveConversionType.sats,
            onTap:
                () => controller.changeConversionType(
                  ReceiveConversionType.sats,
                  selectedAsset!,
                ),
          ),
          const SizedBox(width: 8),
        ],
        _ConversionOption(
          icon: Icons.monetization_on,
          label: fiatCurrency,
          isSelected: conversionType == ReceiveConversionType.fiat,
          onTap:
              () => controller.changeConversionType(
                ReceiveConversionType.fiat,
                selectedAsset!,
              ),
        ),
      ],
    );
  }
}

class _ConversionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversionOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiveConversionPreview extends ConsumerWidget {
  final Asset selectedAsset;
  final double assetAmount;

  const ReceiveConversionPreview({
    super.key,
    required this.selectedAsset,
    required this.assetAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyControllerProvider.notifier);
    final fiatCurrency = currencyNotifier.icon;
    final conversionType = ref.watch(receiveConversionTypeProvider);

    return FutureBuilder(
      future: ref.read(fiatPriceProvider(selectedAsset).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
              const SizedBox(width: 8),
              Text(
                'Carregando conversões...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        }

        return snapshot.data!.fold((error) => const SizedBox.shrink(), (price) {
          final fiatValue = assetAmount * price;
          final satsValue =
              (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
                  ? (assetAmount * 100000000).round()
                  : null;

          return Column(
            children: [
              Container(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Conversões equivalentes:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (conversionType != ReceiveConversionType.asset)
                _ConversionRow(
                  icon: Icons.account_balance_wallet,
                  label: '${selectedAsset.ticker}:',
                  value: assetAmount
                      .toStringAsFixed(
                        selectedAsset == Asset.btc ||
                                selectedAsset == Asset.lbtc
                            ? 8
                            : 6,
                      )
                      .replaceAll(RegExp(r'0+$'), '')
                      .replaceAll(RegExp(r'\.$'), ''),
                  suffix: selectedAsset.ticker,
                ),

              if ((selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) &&
                  conversionType != ReceiveConversionType.sats &&
                  satsValue != null)
                _ConversionRow(
                  icon: Icons.bolt,
                  label: 'Satoshis:',
                  value: satsValue.toString(),
                  suffix: 'sats',
                ),

              if (conversionType != ReceiveConversionType.fiat)
                _ConversionRow(
                  icon: Icons.monetization_on,
                  label: '$fiatCurrency:',
                  value: fiatValue.toStringAsFixed(2),
                  suffix: fiatCurrency,
                ),
            ],
          );
        });
      },
    );
  }
}

class _ConversionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;

  const _ConversionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            '$value $suffix',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
