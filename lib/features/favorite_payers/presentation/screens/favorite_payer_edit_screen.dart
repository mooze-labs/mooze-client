import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';

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
  final MaskTextInputFormatter _mask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  String? _labelError;
  String? _cpfError;
  bool _saving = false;

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

    setState(() => _saving = true);
    final result = await ref
        .read(favoritePayersControllerProvider.notifier)
        .save(id: widget.initial?.id, label: label, cpf: _cpfController.text);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result == FavoritePayerSaveError.duplicateCpf) {
      setState(() => _cpfError = t.cpf_favorites_duplicate);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? t.cpf_favorites_edit_title
              : t.cpf_favorites_add_title,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomSheet: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            text: t.cpf_favorites_save,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
      body: PlatformSafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoozeTextField(
                controller: _labelController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                labelText: t.cpf_favorite_label,
                hintText: t.cpf_favorite_label_hint,
                errorText: _labelError,
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
              ),
              const SizedBox(height: 16),
              MoozeTextField(
                controller: _cpfController,
                inputFormatters: [_mask],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                labelText: t.cpf_field_label,
                hintText: t.cpf_field_hint,
                errorText: _cpfError,
                onChanged: (_) {
                  if (_cpfError != null) setState(() => _cpfError = null);
                },
                onSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
