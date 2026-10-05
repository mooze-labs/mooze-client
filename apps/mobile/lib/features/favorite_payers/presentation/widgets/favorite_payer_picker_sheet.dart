import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

Future<FavoritePayer?> showFavoritePayerPickerSheet(BuildContext context) {
  return showModalBottomSheet<FavoritePayer>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FavoritePayerPickerSheet(),
  );
}

class _FavoritePayerPickerSheet extends ConsumerStatefulWidget {
  const _FavoritePayerPickerSheet();

  @override
  ConsumerState<_FavoritePayerPickerSheet> createState() =>
      _FavoritePayerPickerSheetState();
}

class _FavoritePayerPickerSheetState
    extends ConsumerState<_FavoritePayerPickerSheet> {
  String _query = '';

  List<FavoritePayer> _filter(List<FavoritePayer> payers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return payers;
    final digits = CpfValidator.strip(_query);
    return payers
        .where(
          (p) =>
              p.label.toLowerCase().contains(q) ||
              (digits.isNotEmpty && p.cpf.contains(digits)),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Recent-first ordering comes from the controller (newest saved first).
    final payers =
        ref.watch(favoritePayersControllerProvider).valueOrNull ??
        const <FavoritePayer>[];
    final filtered = _filter(payers);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.cpf_favorites_title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                MoozeTextField(
                  hintText: t.cpf_favorites_search_hint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(t.cpf_favorites_search_empty))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final payer = filtered[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: context.colors.primaryColor
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: context.colors.primaryColor,
                                ),
                              ),
                              title: Text(
                                payer.label,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                              ),
                              subtitle: Text(
                                payer.maskedCpf,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: context.colors.textSecondary),
                              ),
                              onTap: () => Navigator.of(context).pop(payer),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
