import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Shows [sections] in a column with a staggered entrance.
///
/// Each section fades in and rises by [Motion.riseDistance]. Section `i`
/// starts `i` × [Motion.staggerStep] after the first one. With 5 sections,
/// the entrance takes 460 ms, inside [Motion.entranceBudget].
///
/// The entrance plays once per app session for each [sessionKey]. The tab
/// shell builds a screen again on a tab return, so the record is static. A
/// later mount, or reduced motion, shows the sections at once. Taps work
/// during the entrance.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.sessionKey,
    required this.sections,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Identifies the screen. Each screen plays its entrance once.
  final Object sessionKey;

  final List<Widget> sections;

  final CrossAxisAlignment crossAxisAlignment;

  static final Set<Object> _played = {};

  /// Returns true after the entrance of [sessionKey] started once in this
  /// app session.
  static bool hasPlayed(Object sessionKey) => _played.contains(sessionKey);

  /// Lets the next mount play every entrance again.
  @visibleForTesting
  static void resetSession() => _played.clear();

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.staggeredEntrance(widget.sections.length),
  );
  late List<Animation<double>> _animations = _buildAnimations();
  bool _started = false;

  List<Animation<double>> _buildAnimations() => [
    for (var i = 0; i < widget.sections.length; i++)
      staggeredAnimation(_controller, i),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final firstShow = StaggeredEntrance._played.add(widget.sessionKey);
    if (!firstShow || Motion.isReduced(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void didUpdateWidget(StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _disposeAnimations();
      _controller.duration = Motion.staggeredEntrance(widget.sections.length);
      _animations = _buildAnimations();
    }
  }

  void _disposeAnimations() {
    for (final animation in _animations) {
      if (animation is CurvedAnimation) animation.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (var i = 0; i < widget.sections.length; i++)
          FadeSlideIn(animation: _animations[i], child: widget.sections[i]),
      ],
    );
  }
}
