import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/current_limits_card.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/providers/wallet_levels_provider.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_header.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/wallet_levels_quick_info.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';

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

  /// Side margin of the content.
  static const double _gutter = BackdropPageScaffold.gutter;

  @override
  Widget build(BuildContext context) {
    final walletLevelsAsync = ref.watch(walletLevelsProvider);

    return BackdropPageScaffold(
      title: AppLocalizations.of(context).wallet_levels_title,
      // The menu and the Pix hub both push this screen, so back returns to
      // the screen that opened it. A deep link has nothing below it, so it
      // falls back to the menu.
      leading: BackButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/menu'),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            return ApiDownIndicatorIcon(
              onRetry: () {
                ref.invalidate(walletLevelsProvider);
                ref.invalidate(walletLevelsRemoteProvider);
                ref.invalidate(userDataProvider);
              },
            );
          },
        ),
      ],
      body: walletLevelsAsync.when(
        data: (walletLevels) => _buildBody(walletLevels),
        loading: () => _buildLoadingBody(),
        error: (error, stackTrace) => _buildError(error),
      ),
      floatingActionButton: _showBackToTop ? _buildBackToTopButton() : null,
    );
  }

  Widget _buildBody(List<WalletLevelEntity> walletLevels) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletLevelsProvider);
        ref.invalidate(walletLevelsRemoteProvider);
        ref.invalidate(userDataProvider);

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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final isApiDown = ref.watch(apiDownProvider);
                      if (isApiDown) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildApiDownNotice(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const WalletLevelsHeader(),
                  const SizedBox(height: 28),
                  const WalletLevelsQuickInfo(),
                  const SizedBox(height: 16),
                  _buildUserLevelCard(),
                  const SizedBox(height: 16),
                  const CurrentLimitsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The API is down: a glass panel with a warning well and a muted line.
  Widget _buildApiDownNotice() {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StateWell(
            icon: Icons.cloud_off_rounded,
            color: context.appColors.warning,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.wallet_levels_api_down_title,
                  style: textTheme.titleSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.wallet_levels_api_down_body,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBody() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WalletLevelsHeader(isLoading: true),
                const SizedBox(height: 28),
                const WalletLevelsQuickInfo(isLoading: true),
                const SizedBox(height: 16),
                _buildLoadingUserLevelCard(),
                const SizedBox(height: 16),
                const CurrentLimitsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(_gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StateWell(
              icon: Icons.error_outline,
              color: context.colors.negativeColor,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              t.wallet_levels_load_error_title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.wallet_levels_load_error_body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SecondaryButton(
              text: t.common_retry,
              height: 48,
              isLoading: _isRetrying,
              onPressed: () async {
                setState(() {
                  _isRetrying = true;
                });

                ref.invalidate(walletLevelsProvider);
                ref.invalidate(walletLevelsRemoteProvider);
                ref.invalidate(userDataProvider);

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

  Widget _buildUserLevelCard() {
    final levelsData = ref.watch(levelsProvider);

    return levelsData.when(
      data: (data) {
        return UserLevelCard(
          currentLevel: data.spendingLevel,
          currentProgress: data.levelProgress,
        );
      },
      loading: () => _buildLoadingUserLevelCard(),
      error: (error, stack) => _buildErrorUserLevelCard(),
    );
  }

  Widget _buildLoadingUserLevelCard() {
    final baseColor = context.colors.baseColor;

    Widget box({double? width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(height < 24 ? height / 2 : 12),
        ),
      );
    }

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: context.colors.highlightColor,
        period: Motion.durationShimmer,
        enabled: !Motion.isReduced(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(width: 160, height: 18),
            const SizedBox(height: 16),
            box(height: 70),
            const SizedBox(height: 16),
            box(width: 120, height: 14),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                box(width: 80, height: 10),
                box(width: 80, height: 10),
              ],
            ),
            const SizedBox(height: 12),
            box(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUserLevelCard() {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StateWell(
                icon: Icons.error_outline,
                color: context.colors.negativeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.level_load_error,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.level_load_retry,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: t.common_retry,
            height: 48,
            isLoading: _isRetryingUserLevel,
            onPressed: () async {
              setState(() {
                _isRetryingUserLevel = true;
              });

              ref.invalidate(walletLevelsRemoteProvider);
              ref.invalidate(userDataProvider);

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

  /// A round glass button that scrolls the list back to the top.
  Widget _buildBackToTopButton() {
    const size = 48.0;
    return SizedBox(
      width: size,
      height: size,
      child: LiquidGlass(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (Motion.isReduced(context)) {
                _scrollController.jumpTo(0);
                return;
              }
              _scrollController.animateTo(
                0,
                duration: Motion.durationSlow,
                curve: Motion.curveLargeMove,
              );
            },
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_up,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round well that marks a state, such as an error, with a light tint of
/// [color].
class _StateWell extends StatelessWidget {
  const _StateWell({required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, size: size / 2, color: color),
    );
  }
}
