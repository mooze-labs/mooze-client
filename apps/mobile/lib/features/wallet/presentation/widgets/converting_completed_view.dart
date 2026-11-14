import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'conversion_scene.dart';

/// The end of a conversion between chains, which its details show once
/// its credit reached the wallet, on the stage of the celebrations: black
/// in the dark theme, pearl in the light one.
///
/// The [ConversionScene] of the two coins plays first. The title and the
/// message show once the received coin lands, then the button.
///
/// The scene starts once this view is on top. The confirmation of the
/// received credit often opens over the details first, and a scene that
/// played behind it would be lost. Under reduced motion everything shows at
/// once, with one light haptic.
class ConvertingCompletedView extends StatefulWidget {
  const ConvertingCompletedView({
    super.key,
    required this.fromAsset,
    required this.toAsset,
    this.onDone,
  });

  final Asset fromAsset;
  final Asset toAsset;

  /// What the button does. By default it goes home.
  final VoidCallback? onDone;

  @override
  State<ConvertingCompletedView> createState() =>
      _ConvertingCompletedViewState();
}

class _ConvertingCompletedViewState extends State<ConvertingCompletedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationConversion,
  );

  /// The title and the message, once the received coin lands.
  late final Animation<double> _reveal = _interval(0.7, 0.95);

  /// The button, last.
  late final Animation<double> _details = _interval(0.8, 1);

  bool _started = false;

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Motion.curveEnter),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read on every change of the route, so the view hears when the
    // confirmation over it closes.
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    if (_started || !onTop) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _controller.value = 1;
      HapticFeedback.lightImpact();
      return;
    }
    // Pushed on its own, as the preview does, the entrance starts once the
    // route is in place. A route pushed with a transition spends its first
    // frame offstage, where its animation reads complete: that one does not
    // count.
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == null || (animation.isCompleted && !route!.offstage)) {
      _controller.forward();
      return;
    }
    void start(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(start);
      if (mounted) _controller.forward();
    }

    animation.addStatusListener(start);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = StagePalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: palette.page,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    // The shockwave crosses the whole screen.
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConversionScene(
                          fromAsset: widget.fromAsset,
                          toAsset: widget.toAsset,
                          animation: _controller,
                        ),
                        FadeTransition(
                          opacity: _reveal,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.9,
                              end: 1,
                            ).animate(_reveal),
                            child: _Headline(
                              title: t.converting_details_completed_title,
                              message: t.converting_details_completed_message,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                // A fade never blocks the tap: the button works from the
                // first frame.
                child: FadeTransition(
                  opacity: _details,
                  child: PrimaryButton(
                    text: t.converting_details_back_to_home,
                    onPressed: widget.onDone ?? () => context.go('/home'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The title and the message under the coins.
class _Headline extends StatelessWidget {
  const _Headline({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
