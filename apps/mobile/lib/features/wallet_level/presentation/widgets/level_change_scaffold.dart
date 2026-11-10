import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_celebration.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_emblem.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/level_names.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The screen of a level change, on the page of its stage: black in the
/// dark theme, pearl in the light one.
///
/// [LevelCelebration] plays first. Once the medal rests, the headline
/// shows: the [title], the [message], the [badge] between two [ornament]s,
/// and the name of the new level. A glass pill with the old and the new
/// level, the [tip] if any, and a button with [actionLabel] that closes the
/// screen come last. Under reduced motion everything shows at once, with
/// one light haptic.
class LevelChangeScaffold extends StatefulWidget {
  const LevelChangeScaffold({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    required this.title,
    required this.message,
    required this.badge,
    required this.ornament,
    this.tip,
    required this.actionLabel,
  });

  final int oldLevel;
  final int newLevel;
  final String title;
  final String message;
  final String badge;
  final String ornament;
  final String? tip;
  final String actionLabel;

  @override
  State<LevelChangeScaffold> createState() => _LevelChangeScaffoldState();
}

class _LevelChangeScaffoldState extends State<LevelChangeScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationLevelChange,
  );

  /// The headline, once the medal rests.
  late final Animation<double> _reveal = _interval(0.66, 0.9);

  /// The pill, the tip, and the button, last.
  late final Animation<double> _details = _interval(0.78, 1);

  bool _started = false;

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Motion.curveEnter),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _controller.value = 1;
      HapticFeedback.lightImpact();
      return;
    }
    // The entrance starts once the route is in place.
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      _controller.forward();
      return;
    }
    void start(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.removeStatusListener(start);
      if (mounted) _controller.forward();
    }

    route.addStatusListener(start);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    final palette = StagePalette.of(context);
    final isUpgrade = widget.newLevel > widget.oldLevel;

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
                        LevelCelebration(
                          oldLevel: widget.oldLevel,
                          newLevel: widget.newLevel,
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
                              title: widget.title,
                              message: widget.message,
                              badge: widget.badge,
                              ornament: widget.ornament,
                              // The tints of the light theme are too pale
                              // for small text on its page.
                              badgeColor: isUpgrade && palette.isDark
                                  ? WalletLevelUiHelpers.getLevelTint(
                                      widget.newLevel,
                                      Brightness.dark,
                                    )
                                  : context.colors.textSecondary,
                              level: widget.newLevel,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _details,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: _LevelChangePill(
                                  oldLevel: widget.oldLevel,
                                  newLevel: widget.newLevel,
                                ),
                              ),
                              if (tip != null) ...[
                                const SizedBox(height: 20),
                                _TipPanel(tip),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FadeTransition(
                  opacity: _details,
                  child: PrimaryButton(
                    text: widget.actionLabel,
                    onPressed: () => context.pop(),
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

/// The title, the message, the badge, and the name of the new level under
/// the medal.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.title,
    required this.message,
    required this.badge,
    required this.ornament,
    required this.badgeColor,
    required this.level,
  });

  final String title;
  final String message;
  final String badge;
  final String ornament;
  final Color badgeColor;
  final int level;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
        const SizedBox(height: 20),
        Text(
          '$ornament  $badge  $ornament',
          semanticsLabel: badge,
          textAlign: TextAlign.center,
          style: context.textTheme.labelMedium?.copyWith(
            color: badgeColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.levelName(level),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// A glass pill with the emblem and the name of the old level, an arrow,
/// and the new level. Down, the old name is struck through.
class _LevelChangePill extends StatelessWidget {
  const _LevelChangePill({required this.oldLevel, required this.newLevel});

  final int oldLevel;
  final int newLevel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;
    final muted = context.colors.textSecondary;
    final isUpgrade = newLevel > oldLevel;
    return LiquidGlass(
      blurBackdrop: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LevelEmblem(
              oldLevel,
              size: 16,
              color: WalletLevelUiHelpers.getLevelTint(
                oldLevel,
                Theme.of(context).brightness,
              ).withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              t.levelName(oldLevel),
              style: textTheme.bodyMedium?.copyWith(
                color: muted,
                decoration: isUpgrade ? null : TextDecoration.lineThrough,
                decorationColor: muted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward_rounded, size: 16, color: muted),
            ),
            LevelEmblem(newLevel, size: 16),
            const SizedBox(width: 6),
            Text(
              t.levelName(newLevel),
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glass panel with a light bulb and [text].
class _TipPanel extends StatelessWidget {
  const _TipPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: context.colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
