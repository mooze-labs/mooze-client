import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

export 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';

/// The period control of the market sheet: a track with one glass lens
/// under the selected period.
///
/// The lens slides to a new period over [Motion.durationFast], and the
/// labels cross-fade their color. A selection plays a selection click.
/// With reduced motion, the lens moves at once.
class MarketPeriodSelector extends StatelessWidget {
  const MarketPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const double height = 44;
  static const double _inset = 4;

  final MarketPeriod selected;
  final ValueChanged<MarketPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const periods = MarketPeriod.values;
    final duration = Motion.of(context, Motion.durationFast);
    final index = periods.indexOf(selected);

    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: duration,
            curve: Motion.curveMove,
            alignment: Alignment(-1 + 2 * index / (periods.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / periods.length,
              heightFactor: 1,
              child: const GlassLens(),
            ),
          ),
          Row(
            children: [
              for (final period in periods)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: period == selected,
                    label: period.spokenName(t),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (period == selected) return;
                        HapticFeedback.selectionClick();
                        onChanged(period);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          curve: Motion.curveMove,
                          style: context.textTheme.labelLarge!.copyWith(
                            color: period == selected
                                ? context.colors.textPrimary
                                : context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text(period.label),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
