import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The floating Liquid Glass navigation capsule of the main screens.
///
/// The capsule floats above the bottom edge and the content scrolls behind
/// it. A glass lens marks the selected tab. The lens slides to a tapped tab
/// and stretches while it moves, like a drop of liquid. During a swipe
/// between pages, it follows [pagePosition], so it moves with the finger.
/// Only the selected tab shows its label.
///
/// With reduced motion, the lens jumps and does not stretch.
class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Position of the tab pager, for example 1.4 halfway through a swipe
  /// from the second to the third tab. Null keeps the lens on
  /// [currentIndex].
  final ValueListenable<double>? pagePosition;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pagePosition,
  });

  /// Height of the capsule.
  static const double capsuleHeight = 64;

  /// Maximum width of the capsule on wide screens.
  static const double maxCapsuleWidth = 440;

  /// Space between the capsule and the sides of the screen.
  static const double sideMargin = 16;

  /// Space between the capsule edge and the tabs.
  static const double inset = 6;

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  /// Moves the lens between two tabs.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
    value: 1,
  );

  /// Start and end of the current lens move, as tab positions.
  late double _from;
  late double _to;

  /// Pager position while the user drags between pages. Null otherwise.
  double? _dragPosition;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.currentIndex.toDouble();
    widget.pagePosition?.addListener(_onPagePosition);
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pagePosition != widget.pagePosition) {
      oldWidget.pagePosition?.removeListener(_onPagePosition);
      widget.pagePosition?.addListener(_onPagePosition);
    }
    if (oldWidget.currentIndex != widget.currentIndex) {
      _moveTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    widget.pagePosition?.removeListener(_onPagePosition);
    _move.dispose();
    super.dispose();
  }

  /// Visual position of the lens, as a tab position.
  double get _position =>
      _dragPosition ??
      lerpDouble(_from, _to, Motion.curveLargeMove.transform(_move.value))!;

  /// Stretch of the lens from 0 (at rest) to 1 (halfway between far tabs).
  double get _stretch {
    if (Motion.isReduced(context)) return 0;
    final drag = _dragPosition;
    if (drag != null) {
      return math.sin(math.pi * (drag - drag.floorToDouble()));
    }
    final distance = (_to - _from).abs().clamp(0.0, 2.0) / 2;
    return math.sin(math.pi * _move.value) * distance;
  }

  void _moveTo(int index) {
    final target = index.toDouble();
    final start = _position;
    _dragPosition = null;
    if ((start - target).abs() < 0.02 || Motion.isReduced(context)) {
      setState(() {
        _from = _to = target;
        _move.value = 1;
      });
      return;
    }
    _from = start;
    _to = target;
    _move.forward(from: 0);
  }

  /// Follows the pager while the user drags. A jump to a whole page, for
  /// example after a tap, is left to [_moveTo], which animates it.
  void _onPagePosition() {
    final page = widget.pagePosition!.value;
    final isBetweenPages = (page - page.roundToDouble()).abs() > 0.001;
    if (isBetweenPages) {
      setState(() => _dragPosition = page);
      return;
    }
    if (_dragPosition != null) {
      // The drag settled on a page.
      setState(() {
        _dragPosition = null;
        _from = _to = page;
        _move.value = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final destinations = [
      _Destination(
        label: t.nav_home,
        icon: 'assets/icons/menu/navigation/home.svg',
      ),
      _Destination(
        label: t.wallet_assets_tab,
        icon: 'assets/icons/menu/navigation/asset.svg',
      ),
      // Pix keeps its brand orb: it is the main product of the app.
      _Destination(label: t.nav_pix, isPix: true),
      _Destination(
        label: t.swap_title,
        icon: 'assets/icons/menu/navigation/swap.svg',
      ),
      _Destination(
        label: t.nav_menu,
        icon: 'assets/icons/menu/navigation/menu.svg',
      ),
    ];

    // The capsule floats above the home indicator. Where the system has no
    // bottom inset, a 12 pt gap keeps it off the edge.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomGap = math.max(bottomInset - 8, 12.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        CustomBottomNavBar.sideMargin,
        8,
        CustomBottomNavBar.sideMargin,
        bottomGap,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: CustomBottomNavBar.maxCapsuleWidth,
          ),
          child: SizedBox(
            height: CustomBottomNavBar.capsuleHeight,
            child: LiquidGlass(
              child: Padding(
                padding: const EdgeInsets.all(CustomBottomNavBar.inset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slot = constraints.maxWidth / destinations.length;
                    return Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _move,
                          builder: (context, _) => _buildLens(
                            slot: slot,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: _NavSlot(
                                  destination: destinations[i],
                                  selected: widget.currentIndex == i,
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The lens under the selected tab. It widens and flattens a little while
  /// it moves.
  Widget _buildLens({
    required double slot,
    required double width,
    required double height,
  }) {
    final stretch = _stretch;
    final lensWidth = math.min((slot - 4) * (1 + 0.45 * stretch), width);
    final lensHeight = height * (1 - 0.12 * stretch);
    final center = (_position + 0.5) * slot;
    final left = (center - lensWidth / 2).clamp(0.0, width - lensWidth);
    return Positioned(
      left: left,
      top: (height - lensHeight) / 2,
      width: lensWidth,
      height: lensHeight,
      child: const GlassLens(),
    );
  }
}

/// One destination of the navigation capsule.
@immutable
class _Destination {
  const _Destination({required this.label, this.icon, this.isPix = false});

  final String label;

  /// SVG icon. Pix uses its orb instead.
  final String? icon;
  final bool isPix;
}

/// One tab: icon and, when selected, its label.
class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  /// Size of the icon area. Every tab uses the same size, so the labels
  /// share one row.
  static const double iconArea = 32;

  /// Height of the label line. The icon area, the gap, and the label fit
  /// inside the capsule at every text scale.
  static const double labelLine = 16;

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? context.colors.primaryColor
        : context.colors.textSecondary;
    final icon = destination.icon;

    // `excludeSemantics` drops the semantics of the gesture below, so the
    // node carries the tap action itself.
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          scale: Motion.pressScaleCircle,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: iconArea,
                  child: Center(
                    child: destination.isPix || icon == null
                        ? const _PixOrb()
                        : TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: iconColor),
                            duration: Motion.of(context, Motion.durationFast),
                            curve: Motion.curveMove,
                            builder: (context, color, _) => SvgPicture.asset(
                              icon,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                color ?? iconColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                  ),
                ),
                // The label grows in under the icon. The icon rises with it.
                SizeFadeSwitcher(
                  duration: Motion.durationBase,
                  child: selected
                      ? Padding(
                          key: const ValueKey('label'),
                          padding: const EdgeInsets.only(top: 1),
                          // One line in a fixed line box: a large text scale
                          // shrinks the label instead of wrapping it or
                          // growing past the capsule.
                          child: SizedBox(
                            height: labelLine,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                destination.label,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('none'), width: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Pix mark in a small brand orb.
class _PixOrb extends StatelessWidget {
  const _PixOrb();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Same color pair as the Pix action card.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryColor, colors.navBarFabBackground],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/menu/navigation/pix.svg',
        width: 16,
        height: 16,
      ),
    );
  }
}
