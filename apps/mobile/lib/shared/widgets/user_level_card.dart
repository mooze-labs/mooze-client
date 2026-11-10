import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/level_names.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The levels of the wallet in a glass panel: a header with the current
/// level, a track of every level, and the progress to the next level.
///
/// Each level keeps its own color as a signal: the tint of its marker, the
/// line to the next marker, and the progress bar. The panel stays glass.
/// The progress fills in when the card appears, unless reduced motion is
/// on.
class UserLevelCard extends StatefulWidget {
  final int currentLevel;

  final double currentProgress;

  final VoidCallback? onTap;

  const UserLevelCard({
    super.key,
    required this.currentLevel,
    this.currentProgress = 0.0,
    this.onTap,
  }) : assert(
         currentLevel >= 0 && currentLevel <= 3,
         'Current level must be between 0 and 3',
       ),
       assert(
         currentProgress >= 0.0 && currentProgress <= 1.0,
         'Progress must be between 0.0 and 1.0',
       );

  @override
  State<UserLevelCard> createState() => _UserLevelCardState();
}

class _UserLevelCardState extends State<UserLevelCard>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _progressAnimationController =
      AnimationController(duration: Motion.durationChartDraw, vsync: this);
  late Animation<double> _progressAnimation = _progressTween(
    0,
    widget.currentProgress,
  );

  /// Width of one level on the track.
  static const double _markerWidth = 104;

  /// Diameter of a level marker.
  static const double _markerSize = 44;

  bool _started = false;

  Animation<double> _progressTween(double begin, double end) =>
      Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(
          parent: _progressAnimationController,
          curve: Motion.curveEnter,
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.isReduced(context)) {
      _progressAnimationController.value = 1;
    } else {
      _progressAnimationController.forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void didUpdateWidget(UserLevelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentProgress != widget.currentProgress) {
      _progressAnimation = _progressTween(
        oldWidget.currentProgress,
        widget.currentProgress,
      );
      if (Motion.isReduced(context)) {
        _progressAnimationController.value = 1;
      } else {
        _progressAnimationController
          ..reset()
          ..forward();
      }
    }

    if (oldWidget.currentLevel != widget.currentLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLevel();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  /// Scrolls the track so the current level sits near its middle.
  void _scrollToCurrentLevel() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target =
        (widget.currentLevel + 0.5) * _markerWidth -
        position.viewportDimension / 2;
    final offset = target.clamp(0.0, position.maxScrollExtent);
    final duration = Motion.of(context, Motion.durationSlow);
    if (duration == Duration.zero) {
      _scrollController.jumpTo(offset);
    } else {
      _scrollController.animateTo(
        offset,
        duration: duration,
        curve: Motion.curveLargeMove,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _buildHeader(),
          ),
          _buildLevelProgressBar(),
          const PanelDivider(indent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentLevelInfo(),
          ),
        ],
      ),
    );
    if (widget.onTap == null) return panel;
    return GestureDetector(onTap: widget.onTap, child: panel);
  }

  Widget _buildHeader() {
    final t = AppLocalizations.of(context);
    final level = UserLevels.getLevelByOrder(widget.currentLevel);
    return Row(
      children: [
        Icon(
          Icons.military_tech_outlined,
          color: context.colors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t.level_my_levels,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // A neutral pill: the dot carries the level color.
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
              if (level != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: level.color,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                t.level_label(widget.currentLevel + 1),
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

  Widget _buildLevelProgressBar() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: UserLevels.levels.length,
        itemBuilder: (context, index) {
          final level = UserLevels.levels[index];
          return _buildLevelMarker(
            level: level,
            isCurrentLevel: level.order == widget.currentLevel,
            isCompleted: level.order < widget.currentLevel,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildLevelMarker({
    required UserLevel level,
    required bool isCurrentLevel,
    required bool isCompleted,
    required int index,
  }) {
    final reached = isCompleted || isCurrentLevel;
    final hairline = AppSurfaces.hairline(context);
    final isLast = index == UserLevels.levels.length - 1;

    return SizedBox(
      width: _markerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: _markerSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // The line to the next level fills with this level's color
                // as the user progresses.
                if (!isLast)
                  Positioned(
                    // The stack is as wide as the marker, so the line
                    // starts just past its right edge and stops short of
                    // the next marker.
                    left: _markerSize + 6,
                    width: _markerWidth - _markerSize - 12,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        final value = isCompleted
                            ? 1.0
                            : isCurrentLevel
                            ? _progressAnimation.value
                            : 0.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 2,
                            backgroundColor: hairline,
                            valueColor: AlwaysStoppedAnimation(level.color),
                          ),
                        );
                      },
                    ),
                  ),
                Container(
                  width: _markerSize,
                  height: _markerSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached
                        ? level.color.withValues(alpha: 0.16)
                        : GlassStyle.of(context).lensFill,
                    border: Border.all(
                      color: isCurrentLevel
                          ? level.color
                          : reached
                          ? level.color.withValues(alpha: 0.3)
                          : hairline,
                      width: isCurrentLevel ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    level.icon,
                    size: 20,
                    color: reached ? level.color : context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).levelName(level.order),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: isCurrentLevel
                  ? context.colors.textPrimary
                  : context.colors.textSecondary,
              fontWeight: isCurrentLevel ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelInfo() {
    final t = AppLocalizations.of(context);
    final currentLevelData = UserLevels.getLevelByOrder(widget.currentLevel);
    final nextLevelData = UserLevels.getNextLevel(widget.currentLevel);

    if (currentLevelData == null) return const SizedBox.shrink();

    final muted = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );
    final strong = context.textTheme.bodyMedium?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: t.level_current, style: muted),
              TextSpan(text: currentLevelData.name, style: strong),
              if (nextLevelData != null) ...[
                TextSpan(text: '  →  ', style: muted),
                TextSpan(text: nextLevelData.name, style: muted),
              ],
            ],
          ),
        ),
        if (nextLevelData != null) ...[
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final small = context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      minHeight: 6,
                      backgroundColor: AppSurfaces.hairline(context),
                      valueColor: AlwaysStoppedAnimation(
                        currentLevelData.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.level_progress(
                            (_progressAnimation.value * 100).toInt(),
                          ),
                          style: small,
                        ),
                      ),
                      Text(t.level_next(nextLevelData.name), style: small),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
