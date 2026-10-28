import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

enum FeeSpeed { low, medium, fast }

/// Compact segmented choice of the Bitcoin fee speed.
///
/// Each segment shows the speed, the fee rate, and the expected time. The
/// selected segment has a brand tint, a brand border, and a bold title, so
/// the selection shows by shape and not by color alone. A rate that is
/// still loading shows a skeleton bar, and its segment ignores taps.
///
/// The send form and the BTC to L-BTC swap sheet use it.
class FeeSpeedSelector extends StatefulWidget {
  final FeeSpeed selectedSpeed;
  final bool lowFeeLoading;
  final ValueChanged<FeeSpeed> onSpeedChanged;
  final int? lowFeeSatPerVByte;
  final int? mediumFeeSatPerVByte;
  final int? fastFeeSatPerVByte;

  const FeeSpeedSelector({
    super.key,
    required this.selectedSpeed,
    required this.lowFeeLoading,
    required this.onSpeedChanged,
    this.lowFeeSatPerVByte,
    this.mediumFeeSatPerVByte,
    this.fastFeeSatPerVByte,
  });

  @override
  State<FeeSpeedSelector> createState() => _FeeSpeedSelectorState();
}

class _FeeSpeedSelectorState extends State<FeeSpeedSelector> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.wallet_fee_speed_title,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: GlassStyle.of(context).lensFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppSurfaces.hairline(context)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.lowFeeLoading) ...[
                  Expanded(
                    child: _FeeSpeedOption(
                      title: t.wallet_fee_economic,
                      subtitle: t.wallet_fee_economic_eta,
                      feeRate: widget.lowFeeSatPerVByte ?? 1,
                      isSelected: widget.selectedSpeed == FeeSpeed.low,
                      onTap: () => widget.onSpeedChanged(FeeSpeed.low),
                      isLoading: widget.lowFeeSatPerVByte == null,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: _FeeSpeedOption(
                    title: t.wallet_fee_normal,
                    subtitle: t.wallet_fee_normal_eta,
                    feeRate: widget.mediumFeeSatPerVByte ?? 3,
                    isSelected: widget.selectedSpeed == FeeSpeed.medium,
                    onTap: () => widget.onSpeedChanged(FeeSpeed.medium),
                    isLoading: widget.mediumFeeSatPerVByte == null,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _FeeSpeedOption(
                    title: t.wallet_fee_fast,
                    subtitle: t.wallet_fee_fast_eta,
                    feeRate: widget.fastFeeSatPerVByte ?? 5,
                    isSelected: widget.selectedSpeed == FeeSpeed.fast,
                    onTap: () => widget.onSpeedChanged(FeeSpeed.fast),
                    isLoading: widget.fastFeeSatPerVByte == null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FeeSpeedOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final int feeRate;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const _FeeSpeedOption({
    required this.title,
    required this.subtitle,
    required this.feeRate,
    required this.isSelected,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    const radius = BorderRadius.all(Radius.circular(15));
    final quiet = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isLoading,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.durationFast),
          curve: Motion.curveMove,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: SkeletonShimmer(
                        child: SkeletonBox(width: 48, height: 12),
                      ),
                    )
                  : Text(
                      '$feeRate sat/vB',
                      textAlign: TextAlign.center,
                      style: quiet?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              Text(subtitle, textAlign: TextAlign.center, style: quiet),
            ],
          ),
        ),
      ),
    );
  }
}
