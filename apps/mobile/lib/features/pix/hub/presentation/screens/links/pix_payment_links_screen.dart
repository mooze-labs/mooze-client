import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Lists the payment links owned by the user.
///
/// The links share one glass panel, split by inset hairlines, like the Pix
/// history. A change between loading, error, and data grows and fades the
/// content over [SizeFadeSwitcher].
class PixPaymentLinksScreen extends ConsumerWidget {
  const PixPaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final links = ref.watch(pixHubPaymentLinksProvider);

    return PixScreenScaffold(
      title: t.pix_hub_action_links,
      subtitle: t.pix_hub_action_links_subtitle,
      onRefresh: () async => ref.invalidate(pixHubPaymentLinksProvider),
      bottomAction: PrimaryButton(
        text: t.pix_hub_link_create,
        onPressed: () => context.push('/pix/links/new'),
      ),
      children: [
        SizeFadeSwitcher(
          child: links.when(
            loading: () => const _LinkSkeleton(key: ValueKey('loading')),
            error: (_, _) => PixEmptyState(
              key: const ValueKey('error'),
              icon: PixIcons.offline,
              title: t.pix_hub_error_title,
              message: t.pix_hub_error_body,
              actionLabel: t.common_retry,
              onAction: () => ref.invalidate(pixHubPaymentLinksProvider),
            ),
            data: (list) => PixSurfaceCard(
              key: ValueKey(list.isEmpty ? 'empty' : 'list'),
              child: list.isEmpty
                  ? PixEmptyState(
                      icon: PixIcons.linkOff,
                      title: t.pix_hub_empty_links_title,
                      message: t.pix_hub_empty_links_body,
                      isCompact: true,
                    )
                  : Column(
                      children: [
                        for (final (index, link) in list.indexed) ...[
                          if (index > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              // The divider starts at the row text.
                              indent: PixActionTile.textInset,
                              color: AppSurfaces.hairline(context),
                            ),
                          PixPaymentLinkTile(link: link),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One payment link row.
///
/// It has the shape of a Pix history row: a neutral well, the reference and
/// the date, and the amount with tabular figures at the end. A status chip
/// below the amount states the status with an icon, a label, and a color.
class PixPaymentLinkTile extends StatelessWidget {
  final PixPaymentLink link;

  const PixPaymentLinkTile({super.key, required this.link});

  /// Widest share of the row that the amount and the status can take.
  static const double _trailingShare = 0.45;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cents = link.amountInCents;
    final amountStyle = cents == null
        ? context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          )
        : context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

    return MergeSemantics(
      child: InkWell(
        onTap: () => context.push('/pix/links/detail', extra: link),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                const PixIconWell(icon: PixIcons.link),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.reference,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPixDate(link.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // With large text the amount and the chip scale down
                // instead of pushing the reference out of the row.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _trailingShare,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cents == null
                              ? t.pix_hub_link_open_amount
                              : formatBrlCents(cents),
                          maxLines: 1,
                          style: amountStyle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: PixPaymentLinkStatusChip(status: link.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip that states the status of a payment link.
///
/// Like the status chip of the Pix history, it carries an icon and a label
/// with its color, so the status never depends on color alone.
class PixPaymentLinkStatusChip extends StatelessWidget {
  final PixPaymentLinkStatus status;

  const PixPaymentLinkStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (color, icon) = switch (status) {
      PixPaymentLinkStatus.paid => (
        pixToneColor(context, PixTone.positive),
        PixIcons.check,
      ),
      PixPaymentLinkStatus.pending => (
        pixToneColor(context, PixTone.warning),
        PixIcons.clock,
      ),
      // An expired link no longer takes a payment: a broken link, in gray.
      PixPaymentLinkStatus.expired => (
        context.colors.textSecondary,
        PixIcons.linkOff,
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixIcon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            pixPaymentLinkStatusLabel(t, status),
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows in the shape of the link rows, shown while they load.
class _LinkSkeleton extends StatelessWidget {
  const _LinkSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return PixSurfaceCard(
      child: SkeletonShimmer(
        child: Column(
          children: [
            for (var index = 0; index < 3; index++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    SkeletonBox.circle(size: PixIconWell.defaultSize),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 14),
                          SizedBox(height: 8),
                          SkeletonBox(width: 72, height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    SkeletonBox(width: 72, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
