import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/amount_field_send.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'send_flow_parts.dart';

/// Compact segmented choice of the unit the user types the amount in.
///
/// A [GlassSegmentedControl]: the glass lens of the navigation bar marks
/// the unit, and a drag sideways moves it.
class SendConversionOptionsRow extends ConsumerWidget {
  final Asset? selectedAsset;

  const SendConversionOptionsRow({super.key, required this.selectedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(sendConversionTypeProvider);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;

    final hasSats = selectedAsset == Asset.btc || selectedAsset == Asset.lbtc;

    return GlassSegmentedControl<SendConversionType>(
      segments: [
        GlassSegment(
          value: SendConversionType.asset,
          label: selectedAsset!.ticker,
        ),
        if (hasSats)
          const GlassSegment(value: SendConversionType.sats, label: 'sats'),
        GlassSegment(value: SendConversionType.fiat, label: fiatCurrency),
      ],
      selected: conversionType,
      onChanged: (type) =>
          ref.read(sendConversionTypeProvider.notifier).state = type,
    );
  }
}

/// The typed amount in the other units, as one quiet line.
///
/// For example "≈ 0.0012 L-BTC · 120.000 sats". The line leaves out the
/// unit the user types in, because the hero already shows it.
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
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;
    final conversionType = ref.watch(sendConversionTypeProvider);
    final quietStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: sendTabularFigures,
    );

    return FutureBuilder(
      future: ref.read(fiatPriceProvider(selectedAsset).future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: Text(
                  t.wallet_send_loading_conversions,
                  style: quietStyle,
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

          final parts = [
            if (conversionType != SendConversionType.asset)
              '${_formatAssetAmount()} ${selectedAsset.ticker}',
            if ((selectedAsset == Asset.btc || selectedAsset == Asset.lbtc) &&
                conversionType != SendConversionType.sats &&
                satsValue != null)
              '${SatsInputFormatter.formatValue(satsValue)} '
                  '${satsValue == 1 ? 'sat' : 'sats'}',
            if (conversionType != SendConversionType.fiat)
              '${fiatValue.toStringAsFixed(2)} $fiatCurrency',
          ];
          if (parts.isEmpty) return const SizedBox.shrink();
          final line = parts.join(' · ');

          return Semantics(
            label: '${t.wallet_send_equivalent_conversions} $line',
            excludeSemantics: true,
            child: Text('≈ $line', style: quietStyle),
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
