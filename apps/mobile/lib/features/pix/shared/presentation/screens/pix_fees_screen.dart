import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_method_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Tabular figures, so amounts and rates line up in the panels.
const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

/// Returns true when the text is so large that side-by-side amounts break
/// inside a number. The rows then stack their amounts.
bool _isStacked(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.3;

/// The Pix deposit fees.
///
/// The screen reads from top to bottom: the fixed fee, the percentage fees
/// with a switch for the referral discount, the referral bonus, worked
/// examples, and the rules. Each group of figures is one glass panel with
/// hairline rows. The explanations are secondary text outside the panels.
///
/// The content fades and rises in once, over [Motion.durationBase]. A
/// button returns to the top after the user scrolls down.
class PixFeesScreen extends StatefulWidget {
  const PixFeesScreen({super.key});

  @override
  State<PixFeesScreen> createState() => _PixFeesScreenState();
}

class _PixFeesScreenState extends State<PixFeesScreen>
    with SingleTickerProviderStateMixin {
  /// Scroll distance after which the back-to-top button shows.
  static const double _backToTopOffset = 200;

  /// Space between two sections.
  static const double _sectionGap = 32;

  final ScrollController _scrollController = ScrollController();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _entranceAnimation = CurvedAnimation(
    parent: _entrance,
    curve: Motion.curveEnter,
  );

  bool _showBackToTop = false;

  /// True when the percentage fees show the referral discount.
  bool _withDiscount = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.isDismissed) {
      if (Motion.isReduced(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final showBackToTop = _scrollController.offset >= _backToTopOffset;
    if (showBackToTop != _showBackToTop) {
      setState(() => _showBackToTop = showBackToTop);
    }
  }

  void _scrollToTop() {
    // A scroll animation needs a duration above zero. With reduced motion,
    // the list jumps to the top.
    if (Motion.isReduced(context)) {
      _scrollController.jumpTo(0);
      return;
    }
    _scrollController.animateTo(
      0,
      duration: Motion.durationSlow,
      curve: Motion.curveLargeMove,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(title: Text(t.main_settings_pix_fees)),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: FadeSlideIn(
              animation: _entranceAnimation,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  PixScreenScaffold.gutter,
                  8,
                  PixScreenScaffold.gutter,
                  // The back-to-top button never covers the last line.
                  _BackToTopButton.size + 48,
                ),
                children: [
                  PixScreenTitle(
                    title: t.pix_fees_screen_header_title,
                    subtitle: t.pix_fees_screen_header_subtitle,
                  ),
                  const SizedBox(height: 28),
                  const _FixedFeeSection(),
                  const SizedBox(height: _sectionGap),
                  _PercentageFeeSection(
                    withDiscount: _withDiscount,
                    onChanged: (value) => setState(() => _withDiscount = value),
                  ),
                  const SizedBox(height: _sectionGap),
                  const _ReferralSection(),
                  const SizedBox(height: _sectionGap),
                  const _ExamplesSection(),
                  const SizedBox(height: _sectionGap),
                  const _RulesSection(),
                ],
              ),
            ),
          ),
          Positioned(
            right: PixScreenScaffold.gutter,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: _BackToTopButton(
                visible: _showBackToTop,
                onPressed: _scrollToTop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group of the screen: the title, an optional qualifier, the
/// content, and an optional footnote.
class _FeeSection extends StatelessWidget {
  const _FeeSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.footnote,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Explanation below the content, as secondary text.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixSectionHeader(title: title),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: secondaryStyle),
        ],
        const SizedBox(height: 12),
        child,
        if (footnote != null) ...[
          const SizedBox(height: 8),
          Text(footnote!, style: secondaryStyle),
        ],
      ],
    );
  }
}

/// A hairline between two rows of a panel.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppSurfaces.hairline(context),
    );
  }
}

/// The fixed fee for small deposits.
class _FixedFeeSection extends StatelessWidget {
  const _FixedFeeSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // With large text, the fee moves below its description.
    final isStacked = _isStacked(context);
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.pix_fees_screen_fixed_fee_subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          t.pix_fees_screen_fixed_fee_breakdown,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
    final fee = Text(
      'R\$ 2,00',
      style: context.textTheme.titleLarge?.copyWith(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFeatures: _tabular,
      ),
    );

    return _FeeSection(
      title: t.pix_fees_screen_fixed_fee_title,
      child: PixSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: MergeSemantics(
          child: isStacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [description, const SizedBox(height: 8), fee],
                )
              : Row(
                  children: [
                    Expanded(child: description),
                    const SizedBox(width: 16),
                    fee,
                  ],
                ),
        ),
      ),
    );
  }
}

/// One deposit range with a percentage fee.
class _FeeRange {
  const _FeeRange(this.min, this.max, this.basePercentage);

  final String min;
  final String max;
  final double basePercentage;
}

/// The percentage fees, with and without the referral discount.
class _PercentageFeeSection extends StatelessWidget {
  const _PercentageFeeSection({
    required this.withDiscount,
    required this.onChanged,
  });

  /// The referral discount multiplies every percentage fee by this factor.
  static const double discountFactor = 0.85;

  static const List<_FeeRange> _ranges = [
    _FeeRange('55', '499', 3.5),
    _FeeRange('500', '3.000', 3.0),
  ];

  final bool withDiscount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return _FeeSection(
      title: t.pix_fees_screen_percentage_title,
      subtitle: t.pix_fees_screen_percentage_subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiscountSwitch(withDiscount: withDiscount, onChanged: onChanged),
          const SizedBox(height: 12),
          // A horizontal swipe on the rates also switches the discount.
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < 0 && !withDiscount) onChanged(true);
              if (velocity > 0 && withDiscount) onChanged(false);
            },
            child: PixSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SizeFadeSwitcher(
                child: Column(
                  key: ValueKey(withDiscount),
                  children: [
                    for (var index = 0; index < _ranges.length; index++) ...[
                      if (index > 0) const _Hairline(),
                      _FeeRangeRow(
                        range: _ranges[index],
                        withDiscount: withDiscount,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A deposit range on the left and its fee on the right.
///
/// With the discount, the fee before the discount shows below the range.
class _FeeRangeRow extends StatelessWidget {
  const _FeeRangeRow({required this.range, required this.withDiscount});

  final _FeeRange range;
  final bool withDiscount;

  static String _formatPercentage(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fee = withDiscount
        ? range.basePercentage * _PercentageFeeSection.discountFactor
        : range.basePercentage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.pix_fees_screen_fee_range_label(range.min, range.max),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontFeatures: _tabular,
                    ),
                  ),
                  if (withDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.pix_fees_screen_fee_range_before(
                        _formatPercentage(range.basePercentage),
                      ),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${_formatPercentage(fee)}%',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two segments that choose the rates without or with the discount.
///
/// The selected segment is a glass lens. Its label is bold, so the
/// selection never depends on the fill alone.
class _DiscountSwitch extends StatelessWidget {
  const _DiscountSwitch({required this.withDiscount, required this.onChanged});

  final bool withDiscount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassPanel(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: Row(
        children: [
          Expanded(
            child: _DiscountSegment(
              label: t.pix_fees_screen_tab_no_discount,
              isSelected: !withDiscount,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _DiscountSegment(
              label: t.pix_fees_screen_tab_with_discount,
              icon: PixIcons.gift,
              isSelected: withDiscount,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountSegment extends StatelessWidget {
  const _DiscountSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final PixIconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final glass = GlassStyle.of(context);
    final color = isSelected
        ? context.colors.textPrimary
        : context.colors.textSecondary;

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        // The touch target is 48 pt high. The lens sits 4 pt inside it.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.durationFast),
              curve: Motion.curveMove,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: _radius,
                color: isSelected
                    ? glass.lensFill
                    : glass.lensFill.withValues(alpha: 0),
                border: Border.all(
                  color: isSelected
                      ? AppSurfaces.hairline(context)
                      : Colors.transparent,
                ),
                boxShadow: isSelected ? glass.lensShadows : const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    PixIcon(icon!, size: 14, color: color),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The referral discount on the percentage fees.
class _ReferralSection extends StatelessWidget {
  const _ReferralSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return _FeeSection(
      title: t.pix_fees_screen_referral_title,
      footnote: t.pix_fees_screen_referral_disclaimer,
      child: PixSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: MergeSemantics(
          child: Row(
            children: [
              // The positive tone marks a saving. The text states it too.
              const PixIconWell(icon: PixIcons.gift, tone: PixTone.positive),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.pix_fees_screen_referral_discount,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _tabular,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.pix_fees_screen_referral_subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One worked example: a deposit, its fee, and the amount received.
class _FeeExample {
  const _FeeExample({
    required this.deposit,
    required this.fee,
    required this.receive,
    this.calculation,
    this.withReferral = false,
    this.receiveWithoutReferral,
  });

  final String deposit;
  final String fee;
  final String receive;

  /// How the fee is calculated. Null for the fixed fee.
  final String? calculation;

  final bool withReferral;

  /// Amount received for the same deposit without the referral discount.
  final String? receiveWithoutReferral;
}

/// Worked examples in one panel, under the column titles.
class _ExamplesSection extends StatelessWidget {
  const _ExamplesSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final examples = [
      // R$ 30,00: the fixed fee.
      const _FeeExample(
        deposit: 'R\$ 30,00',
        fee: 'R\$ 2,00',
        receive: 'R\$ 28,00',
      ),
      // R$ 300,00: 3,5%.
      _FeeExample(
        deposit: 'R\$ 300,00',
        fee: 'R\$ 10,50',
        receive: 'R\$ 289,50',
        calculation: t.pix_fees_screen_fee_calculation_of('3,5', '300,00'),
      ),
      // R$ 300,00 with the referral discount: 2,975%.
      const _FeeExample(
        deposit: 'R\$ 300,00',
        fee: 'R\$ 8,93',
        receive: 'R\$ 291,07',
        calculation: '3,5% × 0,85 = 2,975%',
        withReferral: true,
        receiveWithoutReferral: 'R\$ 289,50',
      ),
      // R$ 1.000,00: 3%.
      _FeeExample(
        deposit: 'R\$ 1.000,00',
        fee: 'R\$ 30,00',
        receive: 'R\$ 970,00',
        calculation: t.pix_fees_screen_fee_calculation_of('3', '1.000,00'),
      ),
      // R$ 3.000,00: 3%.
      _FeeExample(
        deposit: 'R\$ 3.000,00',
        fee: 'R\$ 90,00',
        receive: 'R\$ 2.910,00',
        calculation: t.pix_fees_screen_fee_calculation_of('3', '3.000,00'),
      ),
    ];
    final isStacked = _isStacked(context);
    final columnTitleStyle = context.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return _FeeSection(
      title: t.pix_fees_screen_examples_title,
      child: PixSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The column titles. Each row repeats them for screen readers.
            // With large text, each row shows its own titles instead.
            if (!isStacked)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.pix_fees_screen_example_deposit,
                          style: columnTitleStyle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.pix_fees_screen_example_receive,
                          textAlign: TextAlign.end,
                          style: columnTitleStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (var index = 0; index < examples.length; index++) ...[
              if (index > 0 || !isStacked) const _Hairline(),
              _ExampleRow(example: examples[index], isStacked: isStacked),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({required this.example, required this.isStacked});

  final _FeeExample example;

  /// Puts each amount on its own line, under its column title.
  final bool isStacked;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final feeLabel = example.calculation ?? t.pix_fees_screen_example_fee_label;
    final amountStyle = context.textTheme.bodyLarge?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular,
    );
    final detailStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: _tabular,
    );
    final titleStyle = context.textTheme.labelMedium?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    final alignment = isStacked
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
    final textAlign = isStacked ? TextAlign.start : TextAlign.end;
    final receive = Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          example.receive,
          textAlign: textAlign,
          style: amountStyle?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (example.receiveWithoutReferral != null)
          Text(
            example.receiveWithoutReferral!,
            textAlign: textAlign,
            style: detailStyle?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );

    // The visual row relies on the column titles. A screen reader reads
    // each value with its title instead.
    final semanticsLabel = [
      if (example.withReferral) t.pix_fees_screen_example_with_referral,
      '${t.pix_fees_screen_example_deposit} ${example.deposit}',
      '${t.pix_fees_screen_example_receive} ${example.receive}',
      '$feeLabel ${example.fee}',
    ].join(', ');

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (example.withReferral) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PixTag(t.pix_fees_screen_example_with_referral),
              ),
              const SizedBox(height: 8),
            ],
            if (isStacked) ...[
              Text(t.pix_fees_screen_example_deposit, style: titleStyle),
              Text(example.deposit, style: amountStyle),
              const SizedBox(height: 6),
              Text(t.pix_fees_screen_example_receive, style: titleStyle),
              receive,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(example.deposit, style: amountStyle)),
                  Padding(
                    // Centers the arrow on the first line of the amounts.
                    padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
                    child: PixIcon(
                      PixIcons.arrowRight,
                      size: 16,
                      color: context.colors.textTertiary,
                    ),
                  ),
                  Expanded(child: receive),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(feeLabel, style: detailStyle)),
                const SizedBox(width: 12),
                Text(
                  example.fee,
                  style: detailStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The rules of the fees, as a plain list of secondary text.
class _RulesSection extends StatelessWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = [
      t.pix_fees_screen_footer_info_1,
      t.pix_fees_screen_footer_info_2,
      t.pix_fees_screen_footer_info_3,
      t.pix_fees_screen_footer_info_4,
    ];

    return _FeeSection(
      title: t.pix_fees_screen_footer_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rules.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _RuleItem(text: rules[index]),
          ],
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.text});

  static const double _dotSize = 4;
  static const double _lineHeight = 1.4;

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    final style = context.textTheme.bodySmall?.copyWith(
      color: color,
      height: _lineHeight,
    );
    // The dot follows the first line of text at every text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 12) *
        _lineHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: (firstLine - _dotSize) / 2),
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// A round glass button that scrolls the list back to the top.
///
/// It scales and fades in and out over [Motion.durationFast]. With reduced
/// motion, it shows and hides at once. A hidden button takes no taps.
class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.visible, required this.onPressed});

  /// Diameter of the button. It is also the touch target.
  static const double size = 48;

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationFast);

    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: visible ? Motion.curveEnter : Motion.curveExit,
          child: AnimatedScale(
            scale: visible ? 1 : 0.8,
            duration: duration,
            curve: visible ? Motion.curveEnter : Motion.curveExit,
            child: SizedBox.square(
              dimension: size,
              // An overlay over moving content: the glass is opaque, so
              // it needs no backdrop blur.
              child: LiquidGlass(
                blurBackdrop: false,
                opaque: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onPressed,
                    customBorder: const CircleBorder(),
                    // The tooltip also names the button for screen readers.
                    child: Tooltip(
                      message: AppLocalizations.of(
                        context,
                      ).pix_fees_back_to_top,
                      child: Center(
                        // The icon set has no up arrow. The down arrow turns
                        // half a circle.
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: PixIcon(
                            PixIcons.arrowDown,
                            size: 20,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
