import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

enum FeeSpeed { low, medium, fast }

/// Compact segmented choice of the Bitcoin fee speed.
///
/// Each segment shows the speed, the fee rate, and the expected time. A
/// glass lens marks the selected segment, as in the unit selector: it
/// slides to a tapped speed, and it can be dragged from speed to speed. A
/// rate that is still loading shows a skeleton bar, and its segment ignores
/// taps.
///
/// The send form and the BTC to L-BTC swap sheet use it. A null
/// [selectedSpeed] selects no speed, for example while a custom fee rate
/// applies: the lens fades out.
class FeeSpeedSelector extends StatelessWidget {
  final FeeSpeed? selectedSpeed;
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

  /// Corners of the glass track. The custom fee rate below it uses them
  /// too, so the two read as one choice.
  static const BorderRadius radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    GlassSegment<FeeSpeed> segment(
      FeeSpeed speed,
      String title,
      String eta,
      int? rate,
    ) => GlassSegment(
      value: speed,
      label: [title, if (rate != null) '$rate sat/vB', eta].join(', '),
      enabled: rate != null,
      builder: (context, selected) => _FeeSpeedLabel(
        title: title,
        eta: eta,
        rate: rate,
        selected: selected,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.wallet_fee_speed_title,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GlassSegmentedControl<FeeSpeed>(
          expand: true,
          borderRadius: radius,
          selected: selectedSpeed,
          onChanged: onSpeedChanged,
          segments: [
            if (lowFeeLoading)
              segment(
                FeeSpeed.low,
                t.wallet_fee_economic,
                t.wallet_fee_economic_eta,
                lowFeeSatPerVByte,
              ),
            segment(
              FeeSpeed.medium,
              t.wallet_fee_normal,
              t.wallet_fee_normal_eta,
              mediumFeeSatPerVByte,
            ),
            segment(
              FeeSpeed.fast,
              t.wallet_fee_fast,
              t.wallet_fee_fast_eta,
              fastFeeSatPerVByte,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// The speed, its rate, and its expected time, in one segment.
class _FeeSpeedLabel extends StatelessWidget {
  final String title;
  final String eta;
  final int? rate;
  final bool selected;

  const _FeeSpeedLabel({
    required this.title,
    required this.eta,
    required this.rate,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final rate = this.rate;
    final quiet = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: Motion.of(context, Motion.durationFast),
            curve: Motion.curveMove,
            style: context.textTheme.labelLarge!.copyWith(
              color: selected
                  ? context.colors.textPrimary
                  : context.colors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(title, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          rate == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: SkeletonShimmer(
                    child: SkeletonBox(width: 48, height: 12),
                  ),
                )
              : Text(
                  '$rate sat/vB',
                  textAlign: TextAlign.center,
                  style: quiet?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          Text(eta, textAlign: TextAlign.center, style: quiet),
        ],
      ),
    );
  }
}
