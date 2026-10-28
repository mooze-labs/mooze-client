import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Entry point of the receiving operations.
///
/// The screen separates two different intents: receiving a payment from another
/// person, and depositing money into the user's own Mooze wallet.
///
/// Each intent is one glass group of rows. The rows of a group share the
/// panel and an inset hairline, as in the hub lists.
class PixReceiveScreen extends ConsumerWidget {
  const PixReceiveScreen({super.key});

  /// Opens the deposit flow, after the CPF and the ownership notice.
  void _openDeposit(BuildContext context, WidgetRef ref) {
    final profile = ref.read(pixDepositProfileServiceProvider);
    context.push(
      profile.isReadyToDeposit() ? '/pix/deposit' : '/pix/deposit/cpf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    return PixScreenScaffold(
      title: t.pix_hub_receive_title,
      onRefresh: () async =>
          ref.read(favoritePayersControllerProvider.notifier).refresh(),
      children: [
        PixSectionHeader(title: t.pix_hub_receive_from_others),
        const SizedBox(height: 8),
        PixSurfaceCard(
          child: Column(
            children: [
              PixActionTile(
                icon: PixIcons.qrCode,
                title: t.pix_hub_receive_create_charge,
                subtitle: t.pix_hub_receive_create_charge_subtitle,
                onTap: () => context.push('/pix/receive/request'),
              ),
              const _RowDivider(),
              PixActionTile(
                icon: PixIcons.link,
                title: t.pix_hub_action_links,
                subtitle: t.pix_hub_action_links_subtitle,
                onTap: () => context.push('/pix/links'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PixSectionHeader(title: t.pix_hub_receive_own_wallet),
        const SizedBox(height: 8),
        PixSurfaceCard(
          child: PixActionTile(
            icon: PixIcons.deposit,
            title: t.pix_hub_shortcut_deposit,
            subtitle: t.pix_hub_receive_deposit_subtitle,
            onTap: () => _openDeposit(context, ref),
          ),
        ),
        const SizedBox(height: 10),
        _Note(text: t.pix_hub_receive_deposit_note),
        const SizedBox(height: 28),
        const _FavoritePayersSection(),
      ],
    );
  }
}

/// Payers saved on the device, reused by the deposit CPF step.
///
/// The list comes from the favourite payers feature, which stores the records
/// locally. Managing them stays on its own screen.
///
/// A change between loading, error, and data grows and fades the panel
/// content over [SizeFadeSwitcher]. With reduced motion it changes at once.
class _FavoritePayersSection extends ConsumerWidget {
  /// How many payers the section shows before sending the user to the full
  /// list.
  static const int _maxVisible = 4;

  const _FavoritePayersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final payers = ref.watch(favoritePayersControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixSectionHeader(
          title: t.cpf_favorites_title,
          actionLabel: t.pix_hub_manage,
          onAction: () => context.push('/favorite-payers'),
        ),
        // The header action is 40 pt high, so the header already ends
        // below its text.
        const SizedBox(height: 2),
        PixSurfaceCard(
          child: SizeFadeSwitcher(
            child: payers.when(
              loading: () => const _PayerSkeleton(key: ValueKey('loading')),
              error: (_, _) => PixEmptyState(
                key: const ValueKey('error'),
                icon: PixIcons.offline,
                title: t.cpf_favorites_error,
                actionLabel: t.common_retry,
                onAction: () => ref
                    .read(favoritePayersControllerProvider.notifier)
                    .refresh(),
                isCompact: true,
              ),
              data: (list) => list.isEmpty
                  ? PixEmptyState(
                      key: const ValueKey('empty'),
                      icon: PixIcons.personAdd,
                      title: t.cpf_favorites_empty_title,
                      message: t.cpf_favorites_empty_subtitle,
                      actionLabel: t.cpf_favorites_add,
                      onAction: () => context.push('/favorite-payers'),
                      isCompact: true,
                    )
                  : Column(
                      key: const ValueKey('list'),
                      children: [
                        for (final (index, payer)
                            in list.take(_maxVisible).indexed) ...[
                          if (index > 0) const _RowDivider(),
                          _FavoritePayerRow(payer: payer),
                        ],
                        if (list.length > _maxVisible) ...[
                          const _RowDivider(),
                          PixActionTile(
                            icon: PixIcons.people,
                            title: t.cpf_favorites_view_all,
                            onTap: () => context.push('/favorite-payers'),
                          ),
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

/// One saved payer: the label chosen by the user and the masked document.
///
/// The row has the shape of a [PixActionTile]: a neutral well, two lines of
/// text, and a chevron.
class _FavoritePayerRow extends StatelessWidget {
  final FavoritePayer payer;

  const _FavoritePayerRow({required this.payer});

  @override
  Widget build(BuildContext context) {
    void open() => context.push('/favorite-payers');

    // `excludeSemantics` drops the semantics of the ink well below, so the
    // node carries the tap action itself.
    return Semantics(
      button: true,
      label: '${payer.label}, ${payer.maskedCpf}',
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const PixIconWell(icon: PixIcons.person),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payer.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payer.maskedCpf,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PixIcon(
                PixIcons.chevronRight,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder rows in the shape of the payer rows, shown while they load.
class _PayerSkeleton extends StatelessWidget {
  const _PayerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          for (var index = 0; index < 2; index++)
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
                        SkeletonBox(width: 128, height: 14),
                        SizedBox(height: 8),
                        SkeletonBox(width: 96, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Hairline between two rows of a panel. It starts at the row text.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: PixActionTile.textInset,
      color: AppSurfaces.hairline(context),
    );
  }
}

/// A short explanation below a group, with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(PixIcons.info, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
