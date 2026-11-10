import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Segmented control that picks the unit of the amount field.
///
/// A [GlassSegmentedControl]: the glass lens of the navigation bar marks
/// the unit, and a drag sideways moves it. Each segment is at least 48 pt
/// wide and the track is 48 pt high.
class ReceiveConversionOptionsRow extends ConsumerWidget {
  final Asset? selectedAsset;

  const ReceiveConversionOptionsRow({super.key, required this.selectedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(receiveConversionTypeProvider);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;
    final controller = ref.read(receiveConversionControllerProvider.notifier);

    final hasSats = selectedAsset == Asset.btc || selectedAsset == Asset.lbtc;

    return GlassSegmentedControl<ReceiveConversionType>(
      segments: [
        GlassSegment(
          value: ReceiveConversionType.asset,
          label: selectedAsset!.ticker,
        ),
        if (hasSats)
          const GlassSegment(value: ReceiveConversionType.sats, label: 'sats'),
        GlassSegment(value: ReceiveConversionType.fiat, label: fiatCurrency),
      ],
      selected: conversionType,
      onChanged: (type) =>
          controller.changeConversionType(type, selectedAsset!),
    );
  }
}

/// Quiet line with the amount in the other units, for example
/// "≈ 150.000 sats · 512.34 R$".
///
/// The numbers use the same formatting as before. Screen readers hear the
/// "equivalent conversions" label first.
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
    final t = AppLocalizations.of(context);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;
    final conversionType = ref.watch(receiveConversionTypeProvider);
    final muted = context.colors.textSecondary;

    return FutureBuilder(
      future: ref.read(fiatPriceProvider(selectedAsset).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: muted,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.receive_conversion_loading,
                  style: context.textTheme.bodySmall?.copyWith(color: muted),
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

          final parts = <String>[
            if (conversionType != ReceiveConversionType.asset)
              '${_formatAssetAmount()} ${selectedAsset.ticker}',
            if ((selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) &&
                conversionType != ReceiveConversionType.sats &&
                satsValue != null)
              '${SatsInputFormatter.formatValue(satsValue)} sats',
            if (conversionType != ReceiveConversionType.fiat)
              '${fiatValue.toStringAsFixed(2)} $fiatCurrency',
          ];
          if (parts.isEmpty) return const SizedBox.shrink();

          return Semantics(
            label: '${t.receive_conversion_equivalent} ${parts.join(', ')}',
            excludeSemantics: true,
            child: Text(
              '≈ ${parts.join('  ·  ')}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        });
      },
    );
  }

  String _formatAssetAmount() {
    final decimals = (selectedAsset == Asset.btc || selectedAsset == Asset.lbtc)
        ? 8
        : 6;
    return assetAmount
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
