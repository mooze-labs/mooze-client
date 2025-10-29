import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';

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
      loading: () => _buildLoadingCard(),
      error: (error, stack) {
        return _buildErrorCard(context);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
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
            'Erro ao carregar nível',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: 'Tentar novamente',
            isLoading: _isRetrying,
            onPressed: () async {
              setState(() => _isRetrying = true);
              await Future.delayed(const Duration(milliseconds: 500));
              ref.invalidate(levelsProvider);
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
  late ScrollController _scrollController;
  late AnimationController _progressAnimationController;
  late AnimationController _highlightAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

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
      final targetPosition = widget.currentLevel * 120.0;
      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
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
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            level.name,
            style: TextStyle(
              fontSize: context.responsiveFont(12),
              fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.w500,
              color:
                  isCurrentLevel
                      ? level.color
                      : isCompleted
                      ? level.color.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.6),
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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted || isCurrentLevel
                                  ? level.color
                                  : Colors.white.withValues(alpha: 0.3),
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
                                    ? level.color
                                    : Colors.white.withValues(alpha: 0.3),
                            boxShadow:
                                isCurrentLevel
                                    ? [
                                      BoxShadow(
                                        color: level.color.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                    : null,
                            border:
                                isCurrentLevel
                                    ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
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
                                    : Colors.white.withValues(alpha: 0.5),
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
    final currentLevelData = UserLevels.getLevelByOrder(widget.currentLevel);
    final nextLevelData = UserLevels.getNextLevel(widget.currentLevel);

    if (currentLevelData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nível atual: ',
              style: TextStyle(
                fontSize: context.responsiveFont(14),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              currentLevelData.name,
              style: TextStyle(
                fontSize: context.responsiveFont(14),
                fontWeight: FontWeight.bold,
                color: currentLevelData.color,
              ),
            ),
            if (nextLevelData != null) ...[
              SizedBox(width: 10),
              SvgPicture.asset(
                "assets/icons/menu/arrow_to_slide.svg",
                color: currentLevelData.color,
                height: 12,
                width: 12,
              ),
              SizedBox(width: 10),
              Text(
                nextLevelData.name,
                style: TextStyle(
                  fontSize: context.responsiveFont(14),
                  fontWeight: FontWeight.w500,
                  color: nextLevelData.color.withValues(alpha: 0.7),
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
                        'Progresso: ${(_progressAnimation.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: context.responsiveFont(12),
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        'Próximo: ${nextLevelData.name}',
                        style: TextStyle(
                          fontSize: context.responsiveFont(12),
                          color: nextLevelData.color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentLevelData.color,
                      ),
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
