import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
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
    // The payer marked as "my user" first, then the newest saved.
    final payers =
        ref.watch(orderedFavoritePayersProvider).valueOrNull ??
        const <FavoritePayer>[];
    final filtered = _filter(payers);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassSheet(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const _GripHandle(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.cpf_favorites_title,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchField(
                    hintText: t.cpf_favorites_search_hint,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              t.cpf_favorites_search_empty,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const PanelDivider(
                            indent: _PayerRow.dividerIndent,
                          ),
                          itemBuilder: (context, index) {
                            final payer = filtered[index];
                            return _PayerRow(
                              payer: payer,
                              onTap: () => Navigator.of(context).pop(payer),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GripHandle extends StatelessWidget {
  const _GripHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppSurfaces.hairline(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Search field of the sheet: a glass lens fill with a hairline border,
/// the brand color on focus.
class _SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hintText, required this.onChanged});

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );

    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      cursorColor: colors.primaryColor,
      style: context.textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
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
    );
  }
}

/// A payer row of the sheet: a neutral initial well, the label, and the
/// masked document. Tapping the row picks the payer.
class _PayerRow extends StatelessWidget {
  final FavoritePayer payer;
  final VoidCallback onTap;

  const _PayerRow({required this.payer, required this.onTap});

  static const double _hPadding = 20;
  static const double _wellSize = 40;

  /// Hairline indent: lines up with the text, past the well.
  static const double dividerIndent = _hPadding + _wellSize + 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final trimmed = payer.label.trim();
    final initial = trimmed.isEmpty
        ? null
        : trimmed.characters.first.toUpperCase();

    return Semantics(
      label: '${payer.label}, ${payer.maskedCpf}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _hPadding),
            child: ExcludeSemantics(
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
                    child: initial == null
                        ? Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: colors.textPrimary,
                          )
                        : Text(
                            initial,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payer.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
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
                  Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
