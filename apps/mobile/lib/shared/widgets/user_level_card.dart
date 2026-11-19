import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_celebration.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_emblem.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';
import 'package:mooze_mobile/shared/user/level_names.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Size of a level marker on the track.
const double _markerSize = 40;

/// Size of the emblem in a marker.
const double _emblemSize = 20;

/// Thickness of the line between two markers.
const double _connectorThickness = 3;

/// Space between a marker and the line that leaves it.
const double _connectorGap = 4;

/// Thickness of the progress bar to the next level.
const double _barThickness = 6;

/// The levels of the wallet: a track of every level, and the progress to
/// the next one.
///
/// The track draws each level as a small medal, in the hexagon and with the
/// emblem of the medals of the level change screens. A level takes its tint
/// once it is reached, and the current level has a full rim and a soft glow
/// in its tint. The line to the next level, and the bar under the track,
/// fill with the progress when the card shows, unless reduced motion is on.
///
/// [UserLevelCard.new] is a glass panel with a header, for a screen.
/// [UserLevelCard.plain] has no panel and no header, for a surface that
/// already frames it and names it, such as a glass sheet.
class UserLevelCard extends StatelessWidget {
  const UserLevelCard({
    super.key,
    required this.currentLevel,
    this.currentProgress = 0.0,
    this.onTap,
  }) : _framed = true,
       assert(
         currentLevel >= 0 && currentLevel <= 3,
         'Current level must be between 0 and 3',
       ),
       assert(
         currentProgress >= 0.0 && currentProgress <= 1.0,
         'Progress must be between 0.0 and 1.0',
       );

  const UserLevelCard.plain({
    super.key,
    required this.currentLevel,
    this.currentProgress = 0.0,
    this.onTap,
  }) : _framed = false,
       assert(
         currentLevel >= 0 && currentLevel <= 3,
         'Current level must be between 0 and 3',
       ),
       assert(
         currentProgress >= 0.0 && currentProgress <= 1.0,
         'Progress must be between 0.0 and 1.0',
       );

  final int currentLevel;

  /// Progress from the current level to the next one, from 0 to 1.
  final double currentProgress;

  final VoidCallback? onTap;

  /// Whether the card is a glass panel with a header.
  final bool _framed;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_framed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _Header(level: currentLevel),
          ),
        Padding(
          padding: _framed
              ? const EdgeInsets.fromLTRB(8, 20, 8, 16)
              : const EdgeInsets.fromLTRB(0, 8, 0, 16),
          child: _LevelTrack(
            currentLevel: currentLevel,
            progress: currentProgress,
          ),
        ),
        const PanelDivider(),
        Padding(
          padding: _framed
              ? const EdgeInsets.all(16)
              : const EdgeInsets.only(top: 16, bottom: 4),
          child: _LevelProgress(
            currentLevel: currentLevel,
            progress: currentProgress,
          ),
        ),
      ],
    );

    if (_framed) {
      return GlassPanel(
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      );
    }
    if (onTap == null) return body;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}

/// A skeleton in the shape of a [UserLevelCard], while the level loads.
///
/// [UserLevelCardSkeleton.new] matches [UserLevelCard.new], and
/// [UserLevelCardSkeleton.plain] matches [UserLevelCard.plain].
class UserLevelCardSkeleton extends StatelessWidget {
  const UserLevelCardSkeleton({super.key}) : _framed = true;

  const UserLevelCardSkeleton.plain({super.key}) : _framed = false;

  final bool _framed;

  @override
  Widget build(BuildContext context) {
    final skeleton = SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_framed) ...[
            const Row(
              children: [
                SkeletonBox(width: 120, height: 18, radius: 9),
                Spacer(),
                SkeletonBox(width: 72, height: 26, radius: 13),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              for (final _ in UserLevels.levels)
                const Expanded(
                  child: Column(
                    children: [
                      _SkeletonMedal(),
                      SizedBox(height: 10),
                      SkeletonBox(width: 44, height: 10, radius: 5),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(width: 140, height: 14, radius: 7),
          ),
          const SizedBox(height: 14),
          const SkeletonBox(
            width: double.infinity,
            height: _barThickness,
            radius: _barThickness / 2,
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 88, height: 10, radius: 5),
              SkeletonBox(width: 88, height: 10, radius: 5),
            ],
          ),
        ],
      ),
    );

    if (!_framed) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: skeleton,
      );
    }
    return GlassPanel(padding: const EdgeInsets.all(16), child: skeleton);
  }
}

/// The title of the card and a pill with the emblem and the number of the
/// current level.
class _Header extends StatelessWidget {
  const _Header({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              t.level_my_levels,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // A neutral lens: the emblem carries the color of the level.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: GlassStyle.of(context).lensFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppSurfaces.hairline(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LevelEmblem(level, size: 14),
              const SizedBox(width: 6),
              Text(
                t.level_label(level + 1),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Where a level is on the way of the user.
enum _Reach { completed, current, upcoming }

/// Every level in a row of equal slots, with a line between two markers.
///
/// The line that leaves a level fills with the tint of that level: full
/// once the level is behind, up to the progress for the current level, and
/// empty ahead of it.
class _LevelTrack extends StatelessWidget {
  const _LevelTrack({required this.currentLevel, required this.progress});

  final int currentLevel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final levels = UserLevels.levels;
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / levels.length;
        final lineWidth = math.max(0.0, slot - _markerSize - 2 * _connectorGap);

        return Stack(
          children: [
            // The lines sit behind the markers, between their centers.
            for (var i = 0; i < levels.length - 1; i++)
              PositionedDirectional(
                start: slot * (i + 0.5) + _markerSize / 2 + _connectorGap,
                top: (_markerSize - _connectorThickness) / 2,
                width: lineWidth,
                height: _connectorThickness,
                child: ExcludeSemantics(
                  child: _Groove(
                    value: i < currentLevel
                        ? 1
                        : i == currentLevel
                        ? progress
                        : 0,
                    color: WalletLevelUiHelpers.getLevelTint(
                      levels[i].order,
                      brightness,
                    ),
                    thickness: _connectorThickness,
                    animate: i == currentLevel,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final level in levels)
                  Expanded(
                    child: _LevelMarker(
                      level: level.order,
                      reach: level.order < currentLevel
                          ? _Reach.completed
                          : level.order == currentLevel
                          ? _Reach.current
                          : _Reach.upcoming,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// One level on the track: a small medal with the emblem of the level, and
/// its name under it.
class _LevelMarker extends StatelessWidget {
  const _LevelMarker({required this.level, required this.reach});

  final int level;
  final _Reach reach;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = WalletLevelUiHelpers.getLevelTint(
      level,
      Theme.of(context).brightness,
    );
    final isCurrent = reach == _Reach.current;
    final reached = reach != _Reach.upcoming;

    final rim = switch (reach) {
      _Reach.current => tint,
      _Reach.completed => tint.withValues(alpha: 0.35),
      _Reach.upcoming => AppSurfaces.hairline(context),
    };

    return MergeSemantics(
      child: Column(
        children: [
          Container(
            width: _markerSize,
            height: _markerSize,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: LevelCelebration.medalShape.copyWith(
                side: BorderSide(color: rim, width: isCurrent ? 1.5 : 1),
              ),
              color: reached
                  ? tint.withValues(alpha: 0.16)
                  : GlassStyle.of(context).lensFill,
              // The glow marks where the user is.
              shadows: isCurrent
                  ? [
                      BoxShadow(
                        color: tint.withValues(alpha: isDark ? 0.4 : 0.28),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: LevelEmblem(
              level,
              size: _emblemSize,
              color: reached ? tint : context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          // A level name is one word: it shrinks to fit a narrow slot
          // rather than break or cut.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t.levelName(level),
              maxLines: 1,
              style: context.textTheme.labelMedium?.copyWith(
                color: isCurrent
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The current level, and the progress to the next one: a bar in the tint
/// of the current level, the percentage, and the name of the next level.
/// At the last level, only the current level shows.
class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.currentLevel, required this.progress});

  final int currentLevel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasNext = currentLevel < UserLevels.levels.length - 1;

    final muted = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );
    final strong = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final small = context.textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: t.level_current, style: muted),
              TextSpan(text: t.levelName(currentLevel), style: strong),
            ],
          ),
        ),
        if (hasNext) ...[
          const SizedBox(height: 12),
          // The text under the bar says the same to a screen reader.
          ExcludeSemantics(
            child: _Groove(
              value: progress,
              color: WalletLevelUiHelpers.getLevelTint(
                currentLevel,
                Theme.of(context).brightness,
              ),
              thickness: _barThickness,
              animate: true,
            ),
          ),
          const SizedBox(height: 8),
          // Each text keeps to its half and wraps there with large text.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The final percentage shows at once; only the bar moves.
              Flexible(
                child: Text(
                  t.level_progress((progress * 100).toInt()),
                  style: small,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  t.level_next(t.levelName(currentLevel + 1)),
                  textAlign: TextAlign.end,
                  style: small,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A groove cut into the glass, filled from the start up to [value] with
/// [color].
///
/// With [animate], the fill grows from empty when the groove first shows,
/// and moves to a new [value] when it changes. Under reduced motion, the
/// fill shows at its value at once.
class _Groove extends StatelessWidget {
  const _Groove({
    required this.value,
    required this.color,
    required this.thickness,
    this.animate = false,
  });

  final double value;
  final Color color;
  final double thickness;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(thickness / 2);
    final groove = GlassStyle.of(context).groove;

    Widget fill(double value) => DecoratedBox(
      decoration: BoxDecoration(color: groove, borderRadius: radius),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );

    return SizedBox(
      height: thickness,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: Motion.of(context, Motion.durationChartDraw),
              curve: Motion.curveEnter,
              builder: (context, value, _) => fill(value),
            )
          : fill(value),
    );
  }
}

/// A medal-shaped skeleton for a marker of the track.
class _SkeletonMedal extends StatelessWidget {
  const _SkeletonMedal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _markerSize,
      height: _markerSize,
      decoration: ShapeDecoration(
        shape: LevelCelebration.medalShape,
        color: context.colors.baseColor,
      ),
    );
  }
}
