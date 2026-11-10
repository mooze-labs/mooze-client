import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Adds a favorite payer, or edits [initial].
///
/// While no payer is "my user", a new payer can be marked as the user here,
/// so the user does not have to find the row menu after saving.
class FavoritePayerEditScreen extends ConsumerStatefulWidget {
  final FavoritePayer? initial;

  const FavoritePayerEditScreen({super.key, this.initial});

  bool get isEditing => initial != null;

  @override
  ConsumerState<FavoritePayerEditScreen> createState() =>
      _FavoritePayerEditScreenState();
}

class _FavoritePayerEditScreenState
    extends ConsumerState<FavoritePayerEditScreen> {
  late final TextEditingController _labelController;
  late final TextEditingController _cpfController;
  final CpfCnpjInputFormatter _formatter = CpfCnpjInputFormatter();

  String? _labelError;
  String? _cpfError;
  bool _saving = false;
  bool _isOwn = false;

  /// True when the screen offers the "my user" mark: a new payer, and no
  /// payer marked yet.
  bool get _offersOwnMark =>
      !widget.isEditing && ref.watch(ownPayerIdProvider) == null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initial?.label ?? '');
    _cpfController = TextEditingController(
      text: widget.initial?.maskedCpf ?? '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // The keyboard can submit again while the first save runs.
    if (_saving) return;
    final t = AppLocalizations.of(context);
    final label = _labelController.text.trim();
    final cpfError = CpfValidator.validate(_cpfController.text);

    setState(() {
      _labelError = label.isEmpty ? t.cpf_favorites_label_required : null;
      _cpfError = switch (cpfError) {
        null => null,
        CpfValidationError.empty => t.cpf_error_required,
        CpfValidationError.incomplete => t.cpf_error_incomplete,
        CpfValidationError.invalid => t.cpf_error_invalid,
      };
    });
    if (_labelError != null || _cpfError != null) return;

    final markAsOwn =
        _isOwn && !widget.isEditing && ref.read(ownPayerIdProvider) == null;
    setState(() => _saving = true);
    final FavoritePayerSaveError? result;
    try {
      result = await ref
          .read(favoritePayersControllerProvider.notifier)
          .save(
            id: widget.initial?.id,
            label: label,
            cpf: _cpfController.text,
            markAsOwn: markAsOwn,
          );
    } catch (_) {
      // The core store failed. The fields stay, so the user can try again.
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, t.cpf_favorites_save_error);
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (result == FavoritePayerSaveError.duplicateCpf) {
      setState(() => _cpfError = t.cpf_favorites_duplicate);
      return;
    }
    if (markAsOwn) {
      AppSnackBar.success(context, t.cpf_favorites_own_marked(label));
    }
    if (!widget.isEditing) _clearForm();
    await Navigator.of(context).maybePop();
  }

  /// Empties the form after a payer was added. A screen that cannot close
  /// is then ready for the next payer.
  void _clearForm() {
    _labelController.clear();
    _cpfController.clear();
    setState(() {
      _isOwn = false;
      _labelError = null;
      _cpfError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // No PopScope guards this screen, so the theme's glass back button
    // (which calls maybePop) stands in for the old explicit BackButton.
    return BackdropPageScaffold(
      title: widget.isEditing
          ? t.cpf_favorites_edit_title
          : t.cpf_favorites_add_title,
      bottomAction: PrimaryButton(
        text: t.cpf_favorites_save,
        isLoading: _saving,
        onPressed: _saving ? null : _save,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: SettingsGlassSection(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassField(
                autofocus: true,
                controller: _labelController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                label: t.cpf_favorite_label,
                hintText: t.cpf_favorite_label_hint,
                errorText: _labelError,
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
              ),
              const SizedBox(height: 20),
              _GlassField(
                controller: _cpfController,
                inputFormatters: [_formatter],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                label: t.cpf_field_label,
                hintText: t.cpf_field_hint,
                errorText: _cpfError,
                tabularFigures: true,
                onChanged: (_) {
                  if (_cpfError != null) setState(() => _cpfError = null);
                },
                onSubmitted: (_) => _save(),
              ),
              if (_offersOwnMark) ...[
                const SizedBox(height: 12),
                _OwnPayerCheck(
                  value: _isOwn,
                  onChanged: (value) => setState(() => _isOwn = value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Checkbox that marks the new payer as "my user": the holder of the bank
/// account that pays the user's own deposits.
///
/// The whole row is the touch target, as in the other checkbox rows of the
/// Pix screens.
class _OwnPayerCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OwnPayerCheck({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CheckboxListTile(
      value: value,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      // The theme draws the box. The outline keeps the empty box visible
      // on the light page.
      side: BorderSide(color: context.colorScheme.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        t.cpf_favorites_own_check_title,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        t.cpf_favorites_own_check_subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
          height: 1.4,
        ),
      ),
      onChanged: (checked) => onChanged(checked ?? false),
    );
  }
}

/// A label above a glass input: lens fill, hairline border, the brand
/// color on focus and the negative color on error.
class _GlassField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool tabularFigures;

  const _GlassField({
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.tabularFigures = false,
  });

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );
    final inputStyle = context.textTheme.bodyLarge?.copyWith(
      color: colors.textPrimary,
      fontFeatures: tabularFigures
          ? const [FontFeature.tabularFigures()]
          : null,
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            cursorColor: colors.primaryColor,
            style: inputStyle,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: inputStyle?.copyWith(color: colors.textTertiary),
              errorText: errorText,
              errorMaxLines: 2,
              errorStyle: context.textTheme.bodySmall?.copyWith(
                color: colors.negativeColor,
              ),
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
              errorBorder: frame(colors.negativeColor, 1),
              focusedErrorBorder: frame(colors.negativeColor, 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
