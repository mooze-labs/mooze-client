import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/transactions/build_nav_item.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// The floating Liquid Glass capsule that switches between the transaction
/// history and the Pix history.
///
/// It belongs to the family of the main navigation capsule: it floats above
/// the home indicator, the content scrolls behind it, and a glass lens
/// slides under the selected tab and stretches while it moves, like a drop
/// of liquid.
///
/// The capsule can be dragged sideways, as the main capsule: the lens
/// follows the finger, stretches between the tabs, presses against the ends
/// of the capsule, and the tab under it lights up with a selection click.
/// On release, the drag and its speed pick the tab: half a tab of travel,
/// or a flick, moves on. The lens settles there on a [Motion.springSettle]
/// spring, and the bar calls [onTap] with that tab, as a tap would. A
/// vertical drag is left to the page, and a tap still opens its tab.
///
/// With reduced motion, the lens jumps and does not stretch. A drag still
/// moves it with the finger.
class TransactionsBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TransactionsBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Height of the capsule.
  static const double capsuleHeight = 64;

  /// Width of the capsule. Two tabs need less room than the main bar.
  static const double capsuleWidth = 260;

  /// Space between the capsule edge and the tabs.
  static const double inset = 6;

  @override
  State<TransactionsBottomNavBar> createState() =>
      _TransactionsBottomNavBarState();
}

class _TransactionsBottomNavBarState extends State<TransactionsBottomNavBar>
    with TickerProviderStateMixin {
  static const int _tabCount = 2;

  /// Share of the travel past the first or the last tab that the lens
  /// follows. The lens presses against the end instead of leaving it.
  static const double _edgeResistance = 0.3;

  /// Time over which the release speed carries the lens on, in seconds. A
  /// flick moves to the next tab even after a short drag.
  static const double _flingTime = 0.12;

  /// Moves the lens between the two tabs.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
    value: 1,
  );

  /// Settles the lens after a drag, in tab positions.
  late final AnimationController _settle;

  /// Start and end of the current lens move, as tab positions.
  late double _from;
  late double _to;

  /// Lens position while the user drags the capsule. Null otherwise.
  double? _dragPosition;

  /// True from the start of a drag until the lens settles.
  bool _capsuleDrag = false;

  /// Lens position at the start of the drag.
  double _dragStart = 0;

  /// Distance of the drag, in tabs.
  double _dragDistance = 0;

  /// Tab under the lens during a drag.
  int _dragTab = 0;

  /// Width of one tab, from the last layout.
  double _slot = 1;

  int get _index => widget.currentIndex.clamp(0, _tabCount - 1);

  @override
  void initState() {
    super.initState();
    _from = _to = _index.toDouble();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dragPosition = _settle.value));
  }

  @override
  void didUpdateWidget(TransactionsBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // During a drag, the lens settles on the new tab itself.
    if (oldWidget.currentIndex != widget.currentIndex && !_capsuleDrag) {
      _moveTo(_index);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _move.dispose();
    super.dispose();
  }

  /// Visual position of the lens, as a tab position.
  double get _position =>
      _dragPosition ??
      lerpDouble(_from, _to, Motion.curveLargeMove.transform(_move.value))!;

  /// Stretch of the lens from 0 (at rest) to 1 (halfway between the tabs).
  double get _stretch {
    if (Motion.isReduced(context)) return 0;
    final drag = _dragPosition;
    if (drag != null) {
      return math.sin(math.pi * (drag - drag.floorToDouble()));
    }
    return math.sin(math.pi * _move.value) * (_to - _from).abs().clamp(0, 1);
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

  // Drag on the capsule.

  void _onDragStart(DragStartDetails details) {
    _settle.stop();
    _move.stop();
    _dragStart = _position;
    _dragDistance = 0;
    _dragTab = _dragStart.round().clamp(0, _tabCount - 1);
    setState(() {
      _capsuleDrag = true;
      _dragPosition = _dragStart;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta! / _slot;
    final position = _resist(_dragStart + _dragDistance);
    final tab = position.round().clamp(0, _tabCount - 1);
    if (tab != _dragTab) {
      _dragTab = tab;
      HapticFeedback.selectionClick();
    }
    setState(() => _dragPosition = position);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = (details.primaryVelocity ?? 0) / _slot;
    final position = _dragPosition ?? _position;
    final target = (position + velocity * _flingTime).round().clamp(
      0,
      _tabCount - 1,
    );
    if (target != widget.currentIndex) widget.onTap(target);
    _settleTo(target, velocity);
  }

  /// A drag that never started, for example because a tap won, leaves the
  /// lens alone.
  void _onDragCancel() {
    if (_capsuleDrag) _settleTo(_index, 0);
  }

  /// Returns [position] with resistance past the first and the last tab.
  static double _resist(double position) {
    const last = _tabCount - 1.0;
    if (position < 0) return position * _edgeResistance;
    if (position > last) return last + (position - last) * _edgeResistance;
    return position;
  }

  /// Springs the lens from where the finger left it to [target], with the
  /// release speed.
  void _settleTo(int target, double velocity) {
    final start = _dragPosition ?? _position;
    if (Motion.isReduced(context) || (start - target).abs() < 0.001) {
      _endDrag(target);
      return;
    }
    _settle.value = start;
    _settle
        .animateWith(
          SpringSimulation(
            Motion.springSettle,
            start,
            target.toDouble(),
            velocity,
            snapToEnd: true,
          ),
        )
        // A new drag stops the spring, and the future then never completes.
        .then((_) => _endDrag(target));
  }

  void _endDrag(int target) {
    if (!mounted) return;
    setState(() {
      _capsuleDrag = false;
      _dragPosition = null;
      _from = _to = target.toDouble();
      _move.value = 1;
    });
    // The route did not follow, so the lens goes back to the open tab.
    if (_index != target) _moveTo(_index);
  }

  @override
  Widget build(BuildContext context) {
    // The capsule floats above the home indicator. Where the system has no
    // bottom inset, a 12 pt gap keeps it off the edge.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomGap = math.max(bottomInset - 8, 12.0);

    const tabs = [
      ('assets/icons/menu/navigation/asset.svg', 'Transações'),
      ('assets/icons/menu/navigation/pix.svg', 'Pix'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: SizedBox(
          width: TransactionsBottomNavBar.capsuleWidth,
          height: TransactionsBottomNavBar.capsuleHeight,
          child: LiquidGlass(
            tintOpacity: LiquidGlass.barTintOpacity,
            blurSigma: LiquidGlass.barBlurSigma,
            child: Padding(
              padding: const EdgeInsets.all(TransactionsBottomNavBar.inset),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slot = constraints.maxWidth / _tabCount;
                  _slot = slot;
                  // The tab under the lens lights up during a drag.
                  final selected = _capsuleDrag
                      ? _position.round().clamp(0, _tabCount - 1)
                      : widget.currentIndex;
                  // Only horizontal drags: vertical ones stay with the page,
                  // and a tap without travel stays with its tab.
                  return GestureDetector(
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    onHorizontalDragCancel: _onDragCancel,
                    child: Stack(
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
                            for (var i = 0; i < _tabCount; i++)
                              Expanded(
                                child: AppNavItem(
                                  icon: tabs[i].$1,
                                  label: tabs[i].$2,
                                  index: i,
                                  currentIndex: selected,
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
