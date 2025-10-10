import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/current_limits_card.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/current_user_wallet_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_header.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_quick_info.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_sections_list.dart';

class WalletLevelsScreen extends ConsumerStatefulWidget {
  const WalletLevelsScreen({super.key});

  @override
  ConsumerState<WalletLevelsScreen> createState() => _WalletLevelsScreenState();
}

class _WalletLevelsScreenState extends ConsumerState<WalletLevelsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

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
    final currentUserWalletAsync = ref.watch(currentUserWalletProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: walletLevelsAsync.when(
        data:
            (walletLevels) => currentUserWalletAsync.when(
              data:
                  (currentUserWallet) => _buildBody(
                    theme,
                    colorScheme,
                    walletLevels,
                    currentUserWallet,
                  ),
              loading: () => _buildLoadingBody(theme, colorScheme),
              error: (error, stackTrace) => _buildError(error, colorScheme),
            ),
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
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    List<WalletLevelEntity> walletLevels,
    CurrentUserWalletEntity currentUserWallet,
  ) {
    return CustomScrollView(
      controller: _scrollController,
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
                _buildUserLevelCard(),
                const SizedBox(height: 16),
                CurrentLimitsCard(
                  colorScheme: colorScheme,
                  currentUserWallet: currentUserWallet,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              LevelSectionsList(colorScheme: colorScheme, levels: walletLevels),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
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
                _buildLoadingUserLevelCard(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: CurrentLimitsCard(colorScheme: colorScheme, isLoading: true),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                LevelSectionsList(colorScheme: colorScheme, isLoading: true),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar níveis da carteira',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verifique sua conexão e tente novamente',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(walletLevelsProvider);
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLevelCard() {
    return UserLevelCard(currentLevel: 2, currentProgress: 0.75);
  }

  Widget _buildLoadingUserLevelCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
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
