import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/extensions.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/shared/models/user_levels.dart';

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
      duration: const Duration(milliseconds: 800),
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

    _highlightAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _highlightAnimationController,
        curve: Curves.elasticInOut,
      ),
    );

    _progressAnimationController.forward();
    _highlightAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void didUpdateWidget(UserLevelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentProgress != widget.currentProgress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.currentProgress,
        end: widget.currentProgress,
      ).animate(
        CurvedAnimation(
          parent: _progressAnimationController,
          curve: Curves.easeOutCubic,
        ),
      );

      _progressAnimationController.reset();
      _progressAnimationController.forward();
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
    _highlightAnimationController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    if (_scrollController.hasClients) {
      final targetPosition = (widget.currentLevel - 1) * 120.0 - 120.0;
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHeader(),
            ),
            const SizedBox(height: 20),
            _buildLevelProgressBar(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCurrentLevelInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.military_tech,
          color: AppColors.primaryColor,
          size: context.responsiveFont(20),
        ),
        const SizedBox(width: 8),
        Text(
          'Meus Níveis',
          style: TextStyle(
            fontSize: context.responsiveFont(18),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'Nível ${widget.currentLevel + 1}',
            style: TextStyle(
              fontSize: context.responsiveFont(12),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
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
    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (index < UserLevels.levels.length - 1)
                    Positioned(
                      left: 50,
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
                            width: 65,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: LinearProgressIndicator(
                              value: lineProgress,
                              backgroundColor: AppColors.textSecondary
                                  .withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted || isCurrentLevel
                                    ? level.color
                                    : AppColors.textSecondary.withValues(
                                      alpha: 0.3,
                                    ),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),

                  AnimatedBuilder(
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
                                    : AppColors.textSecondary.withValues(
                                      alpha: 0.3,
                                    ),
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
                                    : AppColors.textSecondary,
                            size: context.responsiveFont(22),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
                color: AppColors.textSecondary,
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
              Text(
                ' → ',
                style: TextStyle(
                  fontSize: context.responsiveFont(14),
                  color: AppColors.textSecondary,
                ),
              ),
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
                          color: AppColors.textSecondary,
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
                      backgroundColor: AppColors.textSecondary.withValues(
                        alpha: 0.2,
                      ),
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
