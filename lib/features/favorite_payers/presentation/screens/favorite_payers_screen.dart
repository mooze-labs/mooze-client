import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payer_edit_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';

/// Wallet-menu management screen: full CRUD over favorite payers with search,
/// and explicit loading / error / empty / data states.
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
      builder: (dialogContext) => AlertDialog(
        title: Text(t.cpf_favorites_delete_title),
        content: Text(t.cpf_favorites_delete_body(payer.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.colors.negativeColor,
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final payersAsync = ref.watch(favoritePayersControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.cpf_favorites_title)),
      body: PlatformSafeArea(
        child: payersAsync.when(
          loading: () => const _LoadingList(),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.read(favoritePayersControllerProvider.notifier).refresh(),
          ),
          data: (payers) {
            if (payers.isEmpty) {
              return _EmptyState(onAdd: () => _openEditor());
            }
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
                      ? Center(child: Text(t.cpf_favorites_search_empty))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _PayerTile(
                            payer: filtered[index],
                            onEdit: () => _openEditor(filtered[index]),
                            onDelete: () => _confirmDelete(filtered[index]),
                          ),
                        ),
                ),
                // Sticky primary action.
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: PrimaryButton(
                      text: t.cpf_favorites_add,
                      onPressed: () => _openEditor(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: MoozeTextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        hintText: t.cpf_favorites_search_hint,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class _PayerTile extends StatelessWidget {
  final FavoritePayer payer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PayerTile({
    required this.payer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '${payer.label}, ${payer.maskedCpf}',
      button: true,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: context.colors.primaryColor.withValues(alpha: 0.12),
          child: Icon(
            Icons.person_outline_rounded,
            color: context.colors.primaryColor,
          ),
        ),
        title: Text(
          payer.label,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          payer.maskedCpf,
          style: textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        onTap: onEdit,
        trailing: PopupMenuButton<_PayerAction>(
          tooltip: t.cpf_favorites_actions,
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (action) => switch (action) {
            _PayerAction.edit => onEdit(),
            _PayerAction.delete => onDelete(),
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _PayerAction.edit,
              child: Text(t.cpf_favorites_edit),
            ),
            PopupMenuItem(
              value: _PayerAction.delete,
              child: Text(t.cpf_favorites_remove),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PayerAction { edit, delete }

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 64,
            color: context.colors.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            t.cpf_favorites_empty_title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            t.cpf_favorites_empty_subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 32),
          PrimaryButton(text: t.cpf_favorites_add, onPressed: onAdd),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appColors.warning,
          ),
          const SizedBox(height: 24),
          Text(
            t.cpf_favorites_error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          SecondaryButton(text: t.common_retry, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// Shimmer skeleton matching the tile layout, like the Pix history loading
/// list (`LoadingPixDepositList`).
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: List.generate(
        6,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: base, shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Column(
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
    );
  }
}
