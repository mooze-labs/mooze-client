import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_segmented_control.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_slider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'send_flow_parts.dart';

/// Formats a fee rate in sat/vB with the decimal mark of the app language,
/// for example "0,5" in Portuguese. A whole rate has no decimals.
String formatFeeRate(BuildContext context, double rate) => NumberFormat(
  '0.#',
  Localizations.localeOf(context).toString(),
).format(rate);

/// The custom fee rate of a Bitcoin on-chain send, under the speed choice.
///
/// Without a [rate], it is one row that offers a custom rate. A tap
/// selects it, starts from the Normal rate of [estimate], and opens the
/// row. Open, the row holds the rate in sat/vB in three ways: the field
/// takes a typed rate, with a comma or a point; the minus and plus buttons
/// step it; and the slider sweeps it. Dots on the slider mark the Economic,
/// Normal, and Fast rates, and a drag clicks as it passes one.
///
/// The chevron at the end of the title closes the row to one line that
/// shows the rate, and opens it again. Closing keeps the rate; a speed
/// above clears it. A new selection opens the row.
///
/// The rate goes from [minRate] to [maxRate], in tenths of a sat/vB. The
/// buttons step a tenth below 1 sat/vB and a whole sat/vB from there. The
/// slider runs on a log scale from [minRate] to [highRateFactor] times the
/// Fast rate, so the rates below 1 sat/vB get room under the finger; a
/// typed rate can go past it. A line under the row tells the expected
/// wait, or warns about a rate that the network may refuse, that may wait
/// long, or that pays more than needed; the fill of the slider takes the
/// warning color then.
///
/// The row is the glass track of the speed choice above it, so the two
/// read as one choice. Selected, its title line takes the glass lens that
/// leaves the speeds, as a selected speed does. The open row sits on the
/// glass itself, under the lens, and opens like a drawer.
class CustomFeeRateOption extends StatefulWidget {
  const CustomFeeRateOption({
    super.key,
    required this.rate,
    required this.estimate,
    required this.onChanged,
  });

  /// The custom rate, or null while a preset speed applies.
  final double? rate;

  final BitcoinFeeEstimate estimate;

  final ValueChanged<double> onChanged;

  /// The smallest rate. Bitcoin Core relays down to 0.1 sat/vB from
  /// version 29.1, and the wallet takes any rate.
  static const double minRate = 0.1;

  /// The largest rate. Four digits stop a slip of the finger from paying a
  /// fee far above any network need.
  static const double maxRate = 9999;

  /// Older nodes refuse a rate below this, in sat/vB.
  static const double legacyRelayRate = 1;

  /// A rate above this many times the Fast rate shows a warning. The slider
  /// ends there.
  static const int highRateFactor = 2;

  /// Returns [rate] in tenths, within [minRate] and [maxRate].
  static double clampRate(double rate) =>
      ((rate * 10).round() / 10).clamp(minRate, maxRate);

  @override
  State<CustomFeeRateOption> createState() => _CustomFeeRateOptionState();
}

class _CustomFeeRateOptionState extends State<CustomFeeRateOption> {
  late final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// The rate under the slider thumb during a drag. The rate applies on
  /// release, so a drag does not build a transaction on every frame.
  double? _sliding;

  /// Whether a selected rate shows its field, buttons, and slider.
  bool _open = true;

  /// The last selected rate. The open row shows it while it closes after a
  /// speed clears the rate.
  late double? _lastRate = widget.rate;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showRate();
  }

  @override
  void didUpdateWidget(CustomFeeRateOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A step, a slide, or a new selection shows its rate. A typed rate is
    // already in the field.
    if (widget.rate != null && _parse(_text.text) != widget.rate) _showRate();
    if (oldWidget.rate == null && widget.rate != null) _open = true;
    if (widget.rate != null) _lastRate = widget.rate;
  }

  void _showRate([double? rate]) {
    final value = rate ?? widget.rate;
    _text.text = value == null ? '' : formatFeeRate(context, value);
  }

  /// An unfinished field, such as "0," or an empty one, shows the rate
  /// again when it loses the focus.
  void _onFocus() {
    if (!_focus.hasFocus) _showRate();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Reads a typed rate, with a comma or a point.
  static double? _parse(String text) =>
      double.tryParse(text.replaceAll(',', '.'));

  void _onTyped(String text) {
    final rate = _parse(text);
    if (rate == null || rate < CustomFeeRateOption.minRate) return;
    widget.onChanged(CustomFeeRateOption.clampRate(rate));
  }

  /// Steps the rate on its grid: tenths below 1 sat/vB, whole rates from
  /// there. For example, 1.5 steps down to 1 and up to 2, and 1 steps down
  /// to 0.9.
  void _step(int direction) {
    final rate = widget.rate!;
    final next = direction > 0
        ? (rate < 1 ? rate + 0.1 : rate.floorToDouble() + 1)
        : (rate <= 1 ? rate - 0.1 : rate.ceilToDouble() - 1);
    HapticFeedback.selectionClick();
    widget.onChanged(CustomFeeRateOption.clampRate(next));
  }

  /// The top of the slider.
  double get _sliderMax => math.max(
    widget.estimate.fastFeeSatPerVByte *
        CustomFeeRateOption.highRateFactor.toDouble(),
    2,
  );

  /// The slider position of [rate], from 0 to 1, on a log scale.
  double _toSlider(double rate) {
    const min = CustomFeeRateOption.minRate;
    final clamped = rate.clamp(min, _sliderMax);
    return math.log(clamped / min) / math.log(_sliderMax / min);
  }

  /// The rate at slider [position]: tenths below 10 sat/vB, whole rates
  /// from there.
  double _fromSlider(double position) {
    const min = CustomFeeRateOption.minRate;
    final rate = min * math.pow(_sliderMax / min, position);
    return rate < 10
        ? CustomFeeRateOption.clampRate(rate)
        : rate.roundToDouble();
  }

  /// The warning for [rate], or null for a rate within the network rates.
  String? _warning(AppLocalizations t, double rate) {
    final estimate = widget.estimate;
    if (rate < CustomFeeRateOption.legacyRelayRate) {
      return t.wallet_fee_custom_below_relay;
    }
    if (rate < estimate.lowFeeSatPerVByte) {
      return t.wallet_fee_custom_below_low(estimate.lowFeeSatPerVByte);
    }
    if (rate >
        estimate.fastFeeSatPerVByte * CustomFeeRateOption.highRateFactor) {
      return t.wallet_fee_custom_above_fast(estimate.fastFeeSatPerVByte);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rate = widget.rate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidGlass(
          borderRadius: FeeSpeedSelector.radius,
          blurBackdrop: false,
          shadows: GlassStyle.of(context).controlShadows,
          child: Padding(
            padding: const EdgeInsets.all(GlassSegmentedControl.inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SelectionLens(
                  shown: rate != null,
                  borderRadius: _innerRadius,
                  child: _title(context, t, rate),
                ),
                // Always in the tree, so the first selection opens it too.
                _Drawer(
                  open: rate != null && _open,
                  child: switch (_lastRate) {
                    final last? => _editor(context, t, last),
                    null => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
          ),
        ),
        SizeFadeSwitcher(
          alignment: AlignmentDirectional.topStart,
          child: rate == null
              ? const SizedBox(key: ValueKey('none'), width: double.infinity)
              : Padding(
                  key: const ValueKey('hint'),
                  padding: const EdgeInsets.only(top: 10),
                  child: _hint(context, t, _sliding ?? rate),
                ),
        ),
      ],
    );
  }

  /// Corners of the lens and of the rows inside the track.
  static final BorderRadius _innerRadius =
      FeeSpeedSelector.radius -
      const BorderRadius.all(Radius.circular(GlassSegmentedControl.inset));

  /// The title line. Without a rate, it offers one. With a rate, it shows
  /// the rate while the row is closed, and its chevron opens and closes the
  /// row.
  Widget _title(BuildContext context, AppLocalizations t, double? rate) {
    final selected = rate != null;
    final open = selected && _open;
    final color = selected
        ? context.colors.textPrimary
        : context.colors.textSecondary;
    final summary = !selected
        ? t.wallet_fee_custom_choose
        : open
        ? null
        : '${formatFeeRate(context, rate)} sat/vB';
    return Semantics(
      button: true,
      selected: selected,
      expanded: open,
      child: PressScale(
        // Inside the lens, the ink is the press feedback.
        scale: selected ? 1 : Motion.pressScale,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              if (!selected) {
                widget.onChanged(
                  widget.estimate.mediumFeeSatPerVByte.toDouble(),
                );
                return;
              }
              // A closed row takes the keyboard away with the field.
              _focus.unfocus();
              setState(() => _open = !_open);
            },
            borderRadius: _innerRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.of(context, Motion.durationFast),
                        curve: Motion.curveMove,
                        style: context.textTheme.labelLarge!.copyWith(
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        child: Text(t.wallet_fee_custom),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.durationFast),
                      child: summary == null
                          ? const SizedBox.shrink()
                          : Text(
                              summary,
                              key: ValueKey(summary),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: selected ? FontWeight.w600 : null,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                    // Down opens the row, up closes it, in step with the
                    // drawer.
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: Motion.of(context, _Drawer.duration),
                      curve: Motion.curveMove,
                      child: PixIcon(
                        PixIcons.chevronDown,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The open row under the title: the rate between the step buttons, and
  /// the slider.
  Widget _editor(BuildContext context, AppLocalizations t, double rate) {
    final shown = _sliding ?? rate;
    final warning = _warning(t, shown) != null;
    final estimate = widget.estimate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: t.wallet_fee_custom_decrease,
                onPressed: rate > CustomFeeRateOption.minRate
                    ? () => _step(-1)
                    : null,
              ),
              Expanded(child: _rateField(context, t)),
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: t.wallet_fee_custom_increase,
                onPressed: rate < CustomFeeRateOption.maxRate
                    ? () => _step(1)
                    : null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // The fill eases into the warning color and back.
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: warning
                    ? pixToneColor(context, PixTone.warning)
                    : context.colors.textPrimary,
              ),
              duration: Motion.of(context, Motion.durationFast),
              curve: Motion.curveMove,
              builder: (context, fill, _) => GlassSlider(
                value: _toSlider(shown),
                activeColor: fill,
                marks: [
                  for (final preset in [
                    estimate.lowFeeSatPerVByte,
                    estimate.mediumFeeSatPerVByte,
                    estimate.fastFeeSatPerVByte,
                  ])
                    _toSlider(preset.toDouble()),
                ],
                semanticFormatterCallback: (position) =>
                    '${formatFeeRate(context, _fromSlider(position))} sat/vB',
                onChanged: (position) {
                  final next = _fromSlider(position);
                  setState(() => _sliding = next);
                  _showRate(next);
                },
                onChangeEnd: (position) {
                  setState(() => _sliding = null);
                  widget.onChanged(_fromSlider(position));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The rate in a well cut into the lens, then its unit.
  Widget _rateField(BuildContext context, AppLocalizations t) {
    final glass = GlassStyle.of(context);
    const well = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Screen readers hear what the number is.
        MergeSemantics(
          child: Semantics(
            label: t.wallet_fee_custom_rate_label,
            child: IntrinsicWidth(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                onChanged: _onTyped,
                // The keyboard shows the decimal mark of the phone. A comma
                // or a point both work.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                inputFormatters: [_FeeRateInputFormatter()],
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: glass.groove,
                  border: well,
                  enabledBorder: well,
                  // The rim of the lens lights the well while it edits.
                  focusedBorder: well.copyWith(
                    borderSide: BorderSide(color: glass.lensRim.first),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(minWidth: 56),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'sat/vB',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// The expected wait, or a warning for a rate far from the presets.
  Widget _hint(BuildContext context, AppLocalizations t, double rate) {
    final warning = _warning(t, rate);
    if (warning != null) {
      return SendNotice(
        key: ValueKey(warning),
        icon: PixIcons.warning,
        tone: PixTone.warning,
        message: warning,
      );
    }
    final estimate = widget.estimate;
    final eta = rate >= estimate.fastFeeSatPerVByte
        ? t.wallet_fee_fast_eta
        : rate >= estimate.mediumFeeSatPerVByte
        ? t.wallet_fee_normal_eta
        : t.wallet_fee_economic_eta;
    return SendQuietText(
      t.wallet_fee_custom_eta(eta),
      key: const ValueKey('eta'),
    );
  }
}

/// A glass lens under [child] while [shown]. It fades in and out with the
/// selection.
class _SelectionLens extends StatelessWidget {
  const _SelectionLens({
    required this.shown,
    required this.borderRadius,
    required this.child,
  });

  final bool shown;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: Motion.of(context, Motion.durationBase),
            curve: Motion.curveMove,
            child: GlassLens(borderRadius: borderRadius),
          ),
        ),
        child,
      ],
    );
  }
}

/// Opens [child] like a drawer under the title.
///
/// The box grows to the height of [child] and reveals it from the top.
/// [child] keeps its size the whole way, so nothing in it moves or wraps.
/// It fades in once the box has opened a third, and on the way back it
/// fades out before the box closes. Closed, [child] leaves the tree, with
/// its field and its semantics. While it closes, it takes no touch.
///
/// With reduced motion, it opens and closes at once.
class _Drawer extends StatefulWidget {
  const _Drawer({required this.open, required this.child});

  final bool open;
  final Widget child;

  /// Time to open or close.
  static const Duration duration = Motion.durationEmphasis;

  @override
  State<_Drawer> createState() => _DrawerState();
}

class _DrawerState extends State<_Drawer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _Drawer.duration,
    value: widget.open ? 1 : 0,
  )..addStatusListener((_) => setState(() {}));

  late final Animation<double> _size = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveMove,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Motion.curveMove),
  );

  @override
  void didUpdateWidget(_Drawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (Motion.isReduced(context)) {
      _controller.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) {
      return const SizedBox(width: double.infinity);
    }
    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fade,
        child: IgnorePointer(ignoring: !widget.open, child: widget.child),
      ),
    );
  }
}

/// Keeps a typed fee rate to digits with one decimal mark, a comma or a
/// point, at most four digits before it and one after.
class _FeeRateInputFormatter extends TextInputFormatter {
  static final _shape = RegExp(r'^\d{0,4}([.,]\d?)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _shape.hasMatch(newValue.text) ? newValue : oldValue;
}

/// A minus or plus button of the rate: a small glass lens on the lens of
/// the row, with a 48 pt touch target.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Size of the lens inside the touch target.
  static const double _lens = 40;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      // The lens shrinks under the finger instead of an ink circle.
      style: const ButtonStyle(
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      icon: SizedBox.square(
        dimension: _lens,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedOpacity(
              opacity: enabled ? 1 : 0.4,
              duration: Motion.of(context, Motion.durationFast),
              child: const GlassLens(),
            ),
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? context.colors.textPrimary
                  : context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
    return enabled
        ? PressScale(scale: Motion.pressScaleCircle, child: button)
        : button;
  }
}
