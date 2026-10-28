import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/amount_field_send.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'send_flow_parts.dart';

/// Compact segmented choice of the unit the user types the amount in.
///
/// The selected segment has a brand tint and a brand border, so the
/// selection shows by shape and not by color alone.
class SendConversionOptionsRow extends ConsumerWidget {
  final Asset? selectedAsset;

  const SendConversionOptionsRow({super.key, required this.selectedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(sendConversionTypeProvider);
    final fiatCurrency = ref.read(currencyControllerProvider.notifier).icon;

    final hasSats = selectedAsset == Asset.btc || selectedAsset == Asset.lbtc;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
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
    final primary = context.colors.primaryColor;
    const radius = BorderRadius.all(Radius.circular(999));
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.durationFast),
          curve: Motion.curveMove,
          // 42 pt high with the 3 pt track padding: a 48 pt touch row.
          constraints: const BoxConstraints(minHeight: 42, minWidth: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? context.colors.textPrimary
                  : context.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The typed amount in the other units, as one quiet line.
///
/// For example "≈ 0.0012 BTC L2 · 120.000 sats". The line leaves out the
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
