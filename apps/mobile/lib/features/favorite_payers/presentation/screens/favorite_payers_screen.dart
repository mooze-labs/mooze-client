import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payer_edit_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_menu.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

/// Wallet-menu management screen: full CRUD over favorite payers with search,
/// and explicit loading / error / empty / data states.
///
/// The payers sit as rows split by hairlines inside one glass panel on the
/// app backdrop. The add button stays pinned above the bottom edge.
///
/// One payer can carry the "my user" mark: the holder of the bank account
/// that pays the user's own deposits. The row menu sets and removes it, and
/// a badge shows it.
class FavoritePayersScreen extends ConsumerStatefulWidget {
  const FavoritePayersScreen({super.key});

  @override
  ConsumerState<FavoritePayersScreen> createState() =>
      _FavoritePayersScreenState();
}

class _FavoritePayersScreenState extends ConsumerState<FavoritePayersScreen> {
  String _query = '';

  Future<void> _openEditor([FavoritePayer? payer]) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoritePayerEditScreen(initial: payer),
      ),
    );
  }

  Future<void> _confirmDelete(FavoritePayer payer) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GlassAlertDialog(
        title: Text(t.cpf_favorites_delete_title),
        content: Text(t.cpf_favorites_delete_body(payer.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.negativeColor,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.cpf_favorites_remove),
          ),
        ],
      ),
    );
    if (confirmed != true || payer.id == null) return;
    await ref.read(favoritePayersControllerProvider.notifier).delete(payer.id!);
    if (!mounted) return;
    // Success feedback (the list also visibly updates).
    AppSnackBar.success(context, t.cpf_favorites_removed);
  }

  /// Marks [payer] as "my user", or removes the mark when it has it.
  Future<void> _toggleOwn(FavoritePayer payer, {required bool isOwn}) async {
    final id = payer.id;
    if (id == null) return;
    final t = AppLocalizations.of(context);
    final own = ref.read(ownPayerIdProvider.notifier);
    if (isOwn) {
      await own.unmark();
    } else {
      await own.mark(id);
    }
    if (!mounted) return;
    AppSnackBar.success(
      context,
      isOwn
          ? t.cpf_favorites_own_unmarked
          : t.cpf_favorites_own_marked(payer.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final payersAsync = ref.watch(orderedFavoritePayersProvider);
    final ownId = ref.watch(ownPayerIdProvider);

    // Once the payers load, the add button stays pinned at the bottom, with
    // a list or without one. Loading and errors have no add button.
    final loaded = payersAsync.whenOrNull(data: (_) => true) ?? false;

    return BackdropPageScaffold(
      title: t.cpf_favorites_title,
      bottomAction: loaded
          ? PrimaryButton(
              text: t.cpf_favorites_add,
              onPressed: () => _openEditor(),
            )
          : null,
      body: payersAsync.when(
        loading: () => const _LoadingList(),
        error: (_, _) => _ErrorState(
          onRetry: () =>
              ref.read(favoritePayersControllerProvider.notifier).refresh(),
        ),
        data: (payers) {
          if (payers.isEmpty) return const _EmptyState();
          final filtered = _query.isEmpty
              ? payers
              : payers
                    .where(
                      (p) =>
                          p.label.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList(growable: false);
          return Column(
            children: [
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _SearchEmpty(text: t.cpf_favorites_search_empty)
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          SettingsGlassSection(
                            child: Column(
                              children: [
                                for (var i = 0; i < filtered.length; i++) ...[
                                  if (i > 0)
                                    const PanelDivider(
                                      indent: _PayerTile.dividerIndent,
                                    ),
                                  _PayerTile(
                                    payer: filtered[i],
                                    isOwn: filtered[i].id == ownId,
                                    onEdit: () => _openEditor(filtered[i]),
                                    onDelete: () => _confirmDelete(filtered[i]),
                                    onToggleOwn: () => _toggleOwn(
                                      filtered[i],
                                      isOwn: filtered[i].id == ownId,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _OwnPayerNote(text: t.cpf_favorites_own_hint),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Search field on the gutter: a glass lens fill with a hairline border,
/// the brand color on focus.
class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BackdropPageScaffold.gutter,
        12,
        BackdropPageScaffold.gutter,
        0,
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: colors.primaryColor,
        style: context.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: t.cpf_favorites_search_hint,
          hintStyle: context.textTheme.bodyLarge?.copyWith(
            color: colors.textTertiary,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
          filled: true,
          fillColor: GlassStyle.of(context).lensFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: frame(hairline, 1),
          enabledBorder: frame(hairline, 1),
          focusedBorder: frame(colors.primaryColor, 1.5),
        ),
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  final String text;
  const _SearchEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BackdropPageScaffold.gutter,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A neutral round well with the first letter of the payer's label.
class _InitialWell extends StatelessWidget {
  final String label;
  const _InitialWell({required this.label});

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty
        ? null
        : trimmed.characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GlassStyle.of(context).lensFill,
          border: Border.all(color: AppSurfaces.hairline(context)),
        ),
        child: initial == null
            ? Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: context.colors.textPrimary,
              )
            : Text(
                initial,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// A payer row of the glass panel. The row opens the editor; the trailing
/// menu offers edit, the "my user" mark and remove.
class _PayerTile extends StatelessWidget {
  final FavoritePayer payer;

  /// True when the payer carries the "my user" mark.
  final bool isOwn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleOwn;

  const _PayerTile({
    required this.payer,
    required this.isOwn,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleOwn,
  });

  static const double _hPadding = 16;

  /// Hairline indent: lines up with the text, past the well.
  static const double dividerIndent = _hPadding + _InitialWell.size + 14;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final textTheme = context.textTheme;
    return Semantics(
      label: [
        payer.label,
        payer.maskedCpf,
        if (isOwn) t.cpf_favorites_own_badge,
      ].join(', '),
      button: true,
      child: InkWell(
        onTap: onEdit,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.only(left: _hPadding, right: 4),
            child: Row(
              children: [
                _InitialWell(label: payer.label),
                const SizedBox(width: 14),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                payer.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (isOwn) ...[
                              const SizedBox(width: 8),
                              const _OwnPayerBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payer.maskedCpf,
                          maxLines: 1,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // The same glass menu as the payment links: it hangs from
                // the button and runs the action once it has closed.
                GlassMenuButton(
                  tooltip: t.cpf_favorites_actions,
                  iconColor: colors.textSecondary,
                  items: [
                    GlassMenuItem(
                      icon: Icons.edit_outlined,
                      label: t.cpf_favorites_edit,
                      onSelected: onEdit,
                    ),
                    GlassMenuItem(
                      icon: isOwn
                          ? Icons.person_off_outlined
                          : Icons.person_outline_rounded,
                      label: isOwn
                          ? t.cpf_favorites_own_unmark
                          : t.cpf_favorites_own_mark,
                      onSelected: onToggleOwn,
                    ),
                    GlassMenuItem(
                      icon: Icons.delete_outline_rounded,
                      label: t.cpf_favorites_remove,
                      destructive: true,
                      onSelected: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "my user" badge of a payer row: an icon and a label on a tinted pill,
/// so the mark never depends on color alone.
class _OwnPayerBadge extends StatelessWidget {
  const _OwnPayerBadge();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).cpf_favorites_own_badge,
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

/// What the "my user" mark means, below the list.
class _OwnPayerNote extends StatelessWidget {
  final String text;

  const _OwnPayerNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 15, color: color),
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

/// A muted round well for the empty and error states.
class _StateWell extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StateWell({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GlassStyle.of(context).lensFill,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }
}

/// No payer yet: a preview of the list to come, the title, and what payers
/// are for. Your own payer comes first, because deposits need it. The add
/// button is pinned at the bottom of the screen, as with a list.
///
/// The parts enter one after the other, once per app session, unless
/// reduced motion is on.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: BackdropPageScaffold.gutter,
          vertical: 24,
        ),
        child: StaggeredEntrance(
          sessionKey: _EmptyState,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          sections: [
            const Center(child: _PreviewList()),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Semantics(
                header: true,
                child: Text(
                  t.cpf_favorites_empty_title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  _Purpose(
                    icon: PixIcons.person,
                    title: t.cpf_favorites_empty_own_title,
                    body: t.cpf_favorites_empty_own_body,
                  ),
                  const SizedBox(height: 16),
                  _Purpose(
                    icon: PixIcons.people,
                    title: t.cpf_favorites_empty_others_title,
                    body: t.cpf_favorites_empty_subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A preview of the list to come, as decoration: three payer rows in a
/// small glass panel. The first one carries the "my user" badge; the next
/// ones fade out.
class _PreviewList extends StatelessWidget {
  const _PreviewList();

  static const double _width = 260;

  @override
  Widget build(BuildContext context) {
    // A drawing, not text to read: it keeps its proportions at any text
    // size, and screen readers skip it.
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: _width,
          child: GlassPanel(
            child: Column(
              children: [
                const _PreviewRow(fade: 1, own: true),
                const PanelDivider(indent: _PreviewRow.textInset),
                const _PreviewRow(fade: 0.6),
                const PanelDivider(indent: _PreviewRow.textInset),
                const _PreviewRow(fade: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the [_PreviewList]: a person in a lens well and two bars for
/// the name and the document. [fade] scales the strength of the row, from
/// 0 to 1.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.fade, this.own = false});

  final double fade;
  final bool own;

  static const double _wellSize = 32;
  static const double _padding = 12;

  /// Distance from the panel edge to the bars. Hairlines start here.
  static const double textInset = _padding + _wellSize + _padding;

  @override
  Widget build(BuildContext context) {
    // A neutral ink at low strength reads as a placeholder on both themes,
    // without looking like a loading skeleton.
    final ink = context.colors.textPrimary;
    Widget bar(double width, double height, double strength) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: strength * fade),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Row(
        children: [
          Container(
            width: _wellSize,
            height: _wellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassStyle.of(context).lensFill,
              border: Border.all(color: AppSurfaces.hairline(context)),
            ),
            child: PixIcon(
              PixIcons.person,
              size: 16,
              color: context.colors.textSecondary.withValues(alpha: fade),
            ),
          ),
          const SizedBox(width: _padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(own ? 64 : 88, 9, 0.22),
                const SizedBox(height: 7),
                bar(own ? 80 : 64, 7, 0.12),
              ],
            ),
          ),
          if (own) ...[const SizedBox(width: 8), const _OwnPayerBadge()],
        ],
      ),
    );
  }
}

/// One use of the payers: an icon in a neutral well, a title, and a line.
class _Purpose extends StatelessWidget {
  const _Purpose({required this.icon, required this.title, required this.body});

  final PixIconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixIconWell(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
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

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: BackdropPageScaffold.gutter,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _StateWell(
                icon: Icons.error_outline_rounded,
                color: context.appColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.cpf_favorites_error,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SecondaryButton(text: t.common_retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton matching the row layout inside the glass panel, like
/// the Pix history loading list (`LoadingPixDepositList`).
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final base = context.colors.baseColor;
    final highlight = context.colors.highlightColor;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsGlassSection(
          child: Column(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const PanelDivider(indent: _PayerTile.dividerIndent),
                SizedBox(
                  height: 68,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Row(
                        children: [
                          Container(
                            width: _InitialWell.size,
                            height: _InitialWell.size,
                            decoration: BoxDecoration(
                              color: base,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(140, 14),
                              const SizedBox(height: 8),
                              bar(100, 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
