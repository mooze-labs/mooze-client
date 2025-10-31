import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/current_limits_card.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_header.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_quick_info.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';

class WalletLevelsScreen extends ConsumerStatefulWidget {
  const WalletLevelsScreen({super.key});

  @override
  ConsumerState<WalletLevelsScreen> createState() => _WalletLevelsScreenState();
}

class _WalletLevelsScreenState extends ConsumerState<WalletLevelsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  bool _isRetrying = false;
  bool _isRetryingUserLevel = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showBackToTop) {
        setState(() {
          _showBackToTop = true;
        });
      }
    } else {
      if (_showBackToTop) {
        setState(() {
          _showBackToTop = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final walletLevelsAsync = ref.watch(walletLevelsProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: walletLevelsAsync.when(
        data: (walletLevels) => _buildBody(theme, colorScheme, walletLevels),
        loading: () => _buildLoadingBody(theme, colorScheme),
        error: (error, stackTrace) => _buildError(error, colorScheme),
      ),
      floatingActionButton:
          _showBackToTop ? _buildBackToTopButton(colorScheme) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Níveis da Carteira'),
      leading: IconButton(
        onPressed: () {
          context.go('/menu');
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    List<WalletLevelEntity> walletLevels,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletLevelsProvider);
        ref.invalidate(levelsProvider);

        try {
          await Future.wait([
            ref.read(walletLevelsProvider.future),
            ref.read(levelsProvider.future),
          ]);
        } catch (_) {
          // Ignore errors here as they will be handled by the when() widgets
        }
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletLevelsHeader(colorScheme: colorScheme),
                  const SizedBox(height: 16),
                  WalletLevelsQuickInfo(colorScheme: colorScheme),
                  const SizedBox(height: 16),
                  _buildUserLevelCard(colorScheme),
                  const SizedBox(height: 16),
                  CurrentLimitsCard(colorScheme: colorScheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBody(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletLevelsHeader(colorScheme: colorScheme, isLoading: true),
                const SizedBox(height: 16),
                WalletLevelsQuickInfo(
                  colorScheme: colorScheme,
                  isLoading: true,
                ),
                const SizedBox(height: 16),
                _buildLoadingUserLevelCard(colorScheme),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CurrentLimitsCard(colorScheme: colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar níveis da carteira',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verifique sua conexão com a internet e tente novamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            SecondaryButton(
              text: 'Tentar Novamente',
              isLoading: _isRetrying,
              onPressed: () async {
                setState(() {
                  _isRetrying = true;
                });

                ref.invalidate(walletLevelsProvider);
                ref.invalidate(levelsProvider);

                await Future.delayed(const Duration(milliseconds: 500));

                if (mounted) {
                  setState(() {
                    _isRetrying = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLevelCard(ColorScheme colorScheme) {
    final levelsData = ref.watch(levelsProvider);

    return levelsData.when(
      data: (data) {
        return UserLevelCard(
          currentLevel: data.spendingLevel,
          currentProgress: data.levelProgress,
        );
      },
      loading: () => _buildLoadingUserLevelCard(colorScheme),
      error:
          (error, stack) => _buildErrorUserLevelCard(colorScheme: colorScheme),
    );
  }

  Widget _buildLoadingUserLevelCard(ColorScheme colorScheme) {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              height: 25,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 16),
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

  Widget _buildErrorUserLevelCard({required ColorScheme colorScheme}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erro ao carregar nível',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tente novamente mais tarde.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: 'Tentar novamente',
            height: 45,
            isLoading: _isRetryingUserLevel,
            onPressed: () async {
              setState(() {
                _isRetryingUserLevel = true;
              });

              ref.invalidate(levelsProvider);

              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted) {
                setState(() {
                  _isRetryingUserLevel = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackToTopButton(ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      child: const Icon(Icons.keyboard_arrow_up),
    );
  }
}
