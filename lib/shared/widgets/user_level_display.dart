import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

class UserLevelDisplay extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const UserLevelDisplay({super.key, this.onTap});

  @override
  ConsumerState<UserLevelDisplay> createState() => _UserLevelDisplayState();
}

class _UserLevelDisplayState extends ConsumerState<UserLevelDisplay> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final levelsData = ref.watch(levelsProvider);

    return levelsData.when(
      data: (data) {
        return _UserLevelDisplayStateful(
          currentLevel: data.spendingLevel,
          currentProgress: data.levelProgress,
          onTap: widget.onTap,
        );
      },
      loading: () => _buildLoadingCard(Theme.of(context).colorScheme),
      error: (error, stack) {
        return _buildErrorCard(context);
      },
    );
  }

  Widget _buildLoadingCard(ColorScheme colorScheme) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            t.level_load_error,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: t.common_retry,
            isLoading: _isRetrying,
            onPressed: () async {
              setState(() => _isRetrying = true);
              await Future.delayed(const Duration(milliseconds: 500));
              ref.invalidate(walletLevelsRemoteProvider);
              ref.invalidate(userDataProvider);
              if (mounted) {
                setState(() => _isRetrying = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UserLevelDisplayStateful extends StatefulWidget {
  final int currentLevel;
  final double currentProgress;
  final VoidCallback? onTap;

  const _UserLevelDisplayStateful({
    required this.currentLevel,
    this.currentProgress = 0.0,
    this.onTap,
  }) : assert(
         currentLevel >= 0 && currentLevel <= 3,
         'Current level must be between 0 and 3. Received: $currentLevel',
       ),
       assert(
         currentProgress >= 0.0 && currentProgress <= 1.0,
         'Progress must be between 0.0 and 1.0',
       );

  @override
  State<_UserLevelDisplayStateful> createState() =>
      _UserLevelDisplayStatefulState();
}

class _UserLevelDisplayStatefulState extends State<_UserLevelDisplayStateful>
    with TickerProviderStateMixin {
  // Some brand level colors are designed for dark surfaces (Diamond's light
  // cyan, Silver's mid-gray). In light theme they lose contrast against white
  // backgrounds, so we substitute deeper, theme-appropriate variants.
  Color _adaptLevelColor(Color color, Brightness brightness) {
    if (brightness == Brightness.dark) return color;
    if (color == const Color(0xFFB9F2FF))
      return const Color(0xFF00ACC1); // Diamond → cyan-600
    if (color == const Color(0xFFC0C0C0))
      return const Color(0xFF757575); // Silver → grey-600
    return color;
  }

  late ScrollController _scrollController;
  late AnimationController _progressAnimationController;
  late AnimationController _highlightAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    // Pre-scroll 37.5 px so the first circle appears flush at the left edge
    // rather than centred within its 120 px item slot.
    _scrollController = ScrollController(initialScrollOffset: 200);

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _highlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentProgress,
    ).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _highlightAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _highlightAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCurrentLevel();
      _progressAnimationController.forward();
      _highlightAnimationController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressAnimationController.dispose();
    _highlightAnimationController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    if (_scrollController.hasClients) {
      // Each item is 120 px wide; the 45 px circle is centred, leaving 37.5 px
      // on each side. Offset by that amount so the active circle lands flush at
      // the left edge of the viewport.
      const circleOffset = 15; // (120 - 45) / 2
      final targetPosition = (widget.currentLevel * 120.0 + circleOffset).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelProgressBar(),
          Container(
            padding: EdgeInsets.all(16),
            child: _buildCurrentLevelInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressBar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: UserLevels.levels.length,
        itemBuilder: (context, index) {
          final level = UserLevels.levels[index];
          final isCurrentLevel = level.order == widget.currentLevel;
          final isCompleted = level.order < widget.currentLevel;
          final isNext = level.order == widget.currentLevel + 1;

          return _buildLevelMarker(
            level: level,
            isCurrentLevel: isCurrentLevel,
            isCompleted: isCompleted,
            isNext: isNext,
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
    required bool isNext,
    required int index,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = colorScheme.brightness;
    final onSurface = colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;
    final isDark = brightness == Brightness.dark;

    final adaptedColor = _adaptLevelColor(level.color, brightness);

    // Inactive circles and connector tracks use a neutral surface token so
    // they read as "not yet reached" on both dark and light backgrounds.
    final inactiveCircleColor =
        isDark
            ? Colors.white.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest;
    final inactiveIconColor =
        isDark
            ? Colors.white.withValues(alpha: 0.4)
            : onSurface.withValues(alpha: 0.3);
    final trackEmptyColor =
        isDark
            ? onSurface.withValues(alpha: 0.25)
            : colorScheme.outline.withValues(alpha: 0.4);

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            level.name,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.w500,
              color:
                  isCurrentLevel
                      ? adaptedColor
                      : isCompleted
                      ? adaptedColor.withValues(alpha: 0.8)
                      : onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            width: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (index < UserLevels.levels.length - 1)
                  Positioned(
                    left: 60,
                    top: 22.5,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final lineProgress =
                            isCompleted
                                ? 1.0
                                : isCurrentLevel
                                ? _progressAnimation.value
                                : 0.0;

                        return Container(
                          width: 120,
                          height: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: LinearProgressIndicator(
                            value: lineProgress,
                            backgroundColor: trackEmptyColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted || isCurrentLevel
                                  ? adaptedColor
                                  : trackEmptyColor,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                  ),
                Center(
                  child: AnimatedBuilder(
                    animation:
                        isCurrentLevel
                            ? _highlightAnimation
                            : const AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      final scale =
                          isCurrentLevel ? _highlightAnimation.value : 1.0;

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCompleted || isCurrentLevel
                                    ? adaptedColor
                                    : inactiveCircleColor,
                            boxShadow:
                                isCurrentLevel
                                    ? [
                                      BoxShadow(
                                        color: adaptedColor.withValues(
                                          alpha: isDark ? 0.45 : 0.3,
                                        ),
                                        blurRadius: isDark ? 12 : 8,
                                        spreadRadius: isDark ? 4 : 2,
                                      ),
                                    ]
                                    : null,
                            border:
                                isCurrentLevel
                                    ? Border.all(
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.25,
                                              )
                                              : adaptedColor.withValues(
                                                alpha: 0.35,
                                              ),
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Icon(
                            level.icon,
                            color:
                                isCompleted || isCurrentLevel
                                    ? Colors.white
                                    : inactiveIconColor,
                            size: context.responsiveFont(22),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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

    final colorScheme = Theme.of(context).colorScheme;
    final brightness = colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final onSurface = colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;

    final adaptedCurrent = _adaptLevelColor(currentLevelData.color, brightness);
    final adaptedNext =
        nextLevelData != null
            ? _adaptLevelColor(nextLevelData.color, brightness)
            : null;
    final trackBg =
        isDark
            ? onSurface.withValues(alpha: 0.2)
            : colorScheme.outline.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.level_current,
              style: textTheme.labelLarge?.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              currentLevelData.name,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: adaptedCurrent,
              ),
            ),
            if (nextLevelData != null && adaptedNext != null) ...[
              const SizedBox(width: 10),
              SvgPicture.asset(
                "assets/icons/menu/arrow_to_slide.svg",
                colorFilter: ColorFilter.mode(adaptedCurrent, BlendMode.srcIn),
                height: 12,
                width: 12,
              ),
              const SizedBox(width: 10),
              Text(
                nextLevelData.name,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: adaptedNext.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (nextLevelData != null)
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.level_progress(
                          (_progressAnimation.value * 100).toInt(),
                        ),
                        style: textTheme.labelMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        t.level_next(nextLevelData.name),
                        style: textTheme.labelMedium?.copyWith(
                          color: adaptedNext?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: trackBg,
                      valueColor: AlwaysStoppedAnimation<Color>(adaptedCurrent),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
