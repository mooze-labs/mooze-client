import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The level of the user, from [levelsProvider], on a surface that already
/// frames it, such as a glass sheet.
///
/// It shows a [UserLevelCard.plain] once the level loads, a skeleton in
/// its shape while it loads, and an error with a retry button if it fails.
/// The skeleton cross-fades to the level.
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

    final child = levelsData.when(
      data: (data) => UserLevelCard.plain(
        currentLevel: data.spendingLevel,
        currentProgress: data.levelProgress,
        onTap: widget.onTap,
      ),
      loading: () => const UserLevelCardSkeleton.plain(),
      error: (error, stack) => _buildError(context),
    );

    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.durationBase),
      switchInCurve: Motion.curveEnter,
      switchOutCurve: Motion.curveExit,
      // The states differ in height: keep them at the top while they
      // cross-fade.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: child,
    );
  }

  /// A red well with the error, a muted line, and a retry button.
  Widget _buildError(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textTheme = context.textTheme;
    final negative = context.colors.negativeColor;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: negative.withValues(alpha: 0.14),
                  border: Border.all(color: negative.withValues(alpha: 0.24)),
                ),
                child: Icon(Icons.error_outline, size: 20, color: negative),
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
