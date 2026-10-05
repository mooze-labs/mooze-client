import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/amount_field_send.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class SendConversionOptionsRow extends ConsumerWidget {
  final Asset? selectedAsset;

  const SendConversionOptionsRow({super.key, required this.selectedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(sendConversionTypeProvider);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;

    final hasSats =
        selectedAsset == Asset.btc || selectedAsset == Asset.lbtc;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // onSurface @ 6% works as a slight darken in light + slight lighten
        // in dark, so the track never disappears against the outer card.
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentPill(
            label: selectedAsset!.ticker,
            isSelected: conversionType == SendConversionType.asset,
            onTap: () => ref.read(sendConversionTypeProvider.notifier).state =
                SendConversionType.asset,
          ),
          if (hasSats)
            _SegmentPill(
              label: 'sats',
              isSelected: conversionType == SendConversionType.sats,
              onTap: () => ref.read(sendConversionTypeProvider.notifier).state =
                  SendConversionType.sats,
            ),
          _SegmentPill(
            label: fiatCurrency,
            isSelected: conversionType == SendConversionType.fiat,
            onTap: () => ref.read(sendConversionTypeProvider.notifier).state =
                SendConversionType.fiat,
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class SendConversionPreview extends ConsumerWidget {
  final Asset selectedAsset;
  final double assetAmount;

  const SendConversionPreview({
    super.key,
    required this.selectedAsset,
    required this.assetAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;
    final conversionType = ref.watch(sendConversionTypeProvider);

    return FutureBuilder(
      future: ref.read(fiatPriceProvider(selectedAsset).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.wallet_send_loading_conversions,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          );
        }

        return snapshot.data!.fold((_) => const SizedBox.shrink(), (price) {
          final fiatValue = assetAmount * price;
          final satsValue =
              (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
                  ? (assetAmount * 100000000).round()
                  : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.wallet_send_equivalent_conversions,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (conversionType != SendConversionType.asset)
                _ConversionRow(
                  label: '${selectedAsset.ticker}:',
                  value: _formatAssetAmount(),
                  suffix: selectedAsset.ticker,
                ),
              if ((selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) &&
                  conversionType != SendConversionType.sats &&
                  satsValue != null)
                _ConversionRow(
                  label: t.wallet_send_satoshis_label,
                  value: SatsInputFormatter.formatValue(satsValue),
                  suffix: satsValue == 1 ? 'sat' : 'sats',
                ),
              if (conversionType != SendConversionType.fiat)
                _ConversionRow(
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

  String _formatAssetAmount() {
    final decimals =
        (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) ? 8 : 6;
    return assetAmount
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class _ConversionRow extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;

  const _ConversionRow({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '$value $suffix',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
