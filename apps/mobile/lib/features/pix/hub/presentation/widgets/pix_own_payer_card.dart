import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_deposit_ownership_notice.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/own_deposit_payer.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The payer document of the user's own deposits.
///
/// It is the document of the favorite payer marked as "my user", read from
/// the favorites, so the card changes as soon as that payer changes. Without
/// that payer the card stays empty, and a warning below it sends the user to
/// the favorite payers.
class PixOwnPayerCard extends ConsumerWidget {
  const PixOwnPayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final own = ref.watch(ownDepositPayerProvider);
    final isLoading = own.isLoading && !own.hasValue && !own.hasError;
    // Favorites that cannot be read show as no payer, as in the deposit.
    final payer = own.hasError ? null : own.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: MergeSemantics(
            child: Row(
              children: [
                const PixIconWell(icon: PixIcons.idCard),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.pix_hub_deposit_cpf_stored_label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: SkeletonShimmer(
                            child: SkeletonBox(width: 132, height: 14),
                          ),
                        )
                      else
                        Text(
                          payer == null
                              ? t.pix_hub_deposit_cpf_missing
                              : formatCpfCnpj(payer.cpf),
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: payer == null
                                ? context.colors.textSecondary
                                : context.colors.textPrimary,
                            fontWeight: payer == null
                                ? FontWeight.w400
                                : FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      if (payer != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${payer.label} · ${t.cpf_favorites_own_badge}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLoading && payer == null) ...[
          const SizedBox(height: 12),
          PixWarningPanel(
            title: t.pix_deposit_own_payer_required_title,
            body: t.pix_deposit_own_payer_required_body,
            actionLabel: t.pix_deposit_own_payer_required_action,
            onAction: () => context.push('/favorite-payers'),
          ),
        ],
      ],
    );
  }
}
