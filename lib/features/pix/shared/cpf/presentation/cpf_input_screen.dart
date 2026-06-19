import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/widgets/favorite_payer_picker_sheet.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const int _kCarouselFavorites = 5;

const EdgeInsets _kPagePadding = EdgeInsets.symmetric(horizontal: 20);

class CpfInputScreen extends ConsumerStatefulWidget {
  const CpfInputScreen({super.key});

  @override
  ConsumerState<CpfInputScreen> createState() => _CpfInputScreenState();
}

class _CpfInputScreenState extends ConsumerState<CpfInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final FocusNode _cpfFocus = FocusNode();
  final CpfCnpjInputFormatter _formatter = CpfCnpjInputFormatter();

  bool _touched = false;
  CpfValidationError? _error;
  bool _saveThisPayer = false;
  bool _isSubmitting = false;

  String get _digits => CpfValidator.strip(_controller.text);
  bool get _isComplete => _digits.length == 11 || _digits.length == 14;
  bool get _isValidCpf => CpfValidator.isValid(_controller.text);
  bool get _hasLabel => _labelController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        if (_touched) _error = CpfValidator.validate(_controller.text);
      });
    });
    _labelController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _labelController.dispose();
    _cpfFocus.dispose();
    super.dispose();
  }

  void _selectFavorite(FavoritePayer payer) {
    setState(() {
      _controller.text = payer.maskedCpf;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _touched = false;
      _error = null;
      _saveThisPayer = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _openPicker() async {
    final selected = await showFavoritePayerPickerSheet(context);
    if (selected != null) _selectFavorite(selected);
  }

  Future<void> _submit(bool canSave) async {
    final error = CpfValidator.validate(_controller.text);
    if (error != null) {
      setState(() {
        _touched = true;
        _error = error;
        _isSubmitting = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isSubmitting = false);
      });
      return;
    }

    setState(() {
      _touched = true;
      _error = null;
      _isSubmitting = true;
    });

    // Saving a favorite is best-effort — never block returning a valid CPF.
    if (canSave && _saveThisPayer && _hasLabel) {
      try {
        await ref
            .read(favoritePayersControllerProvider.notifier)
            .save(label: _labelController.text, cpf: _digits);
      } catch (_) {
        // Ignore: the CPF is valid; the favorite just won't be persisted.
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop<String>(_digits);
  }

  String? _errorText(AppLocalizations t) {
    return switch (_error) {
      null => null,
      CpfValidationError.empty => t.cpf_error_required,
      CpfValidationError.incomplete => t.cpf_error_incomplete,
      CpfValidationError.invalid => t.cpf_error_invalid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final favorites =
        ref.watch(favoritePayersControllerProvider).valueOrNull ??
        const <FavoritePayer>[];
    final hasFavorites = favorites.isNotEmpty;
    final alreadyFavorite =
        _isComplete && favorites.any((p) => p.cpf == _digits);
    // Contextual save: only offered for a valid, not-yet-saved CPF.
    final canSave = _isValidCpf && !alreadyFavorite;
    final canContinue =
        _isComplete && (!(_saveThisPayer && canSave) || _hasLabel);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(t.cpf_screen_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomSheet: _ContinueBar(
        enabled: canContinue,
        isLoading: _isSubmitting,
        onPressed: () => _submit(canSave),
      ),
      body: PlatformSafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            // No horizontal padding here — the gutter is applied per-section so
            // the favorites carousel below can run edge-to-edge.
            padding: const EdgeInsets.only(top: 12, bottom: 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Why the CPF is required — reuses the Pix info-tip card.
                Padding(
                  padding: _kPagePadding,
                  child: InfoTipsSection(
                    maxTips: 1,
                    tips: [
                      InfoTip(
                        icon: Icons.privacy_tip_outlined,
                        text: t.cpf_screen_subtitle,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (hasFavorites) ...[
                  const SizedBox(height: 24),
                  // "View all" sits in the header so it stays visible while the
                  // capped chip row scrolls horizontally.
                  Padding(
                    padding: _kPagePadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: _SectionLabel(text: t.cpf_favorites_section),
                        ),
                        if (favorites.length > _kCarouselFavorites)
                          TextButton(
                            onPressed: _openPicker,
                            child: Text(t.cpf_favorites_view_all),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Full-bleed row: the gutter is the list's own padding so
                  // chips scroll flush with the screen edges.
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: _kPagePadding,
                      children: [
                        for (final payer in favorites.take(_kCarouselFavorites))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color:
                                    _digits == payer.cpf
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer
                                        : Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(payer.label),
                              tooltip: payer.maskedCpf,
                              selected: _digits == payer.cpf,
                              onSelected: (_) => _selectFavorite(payer),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: _kPagePadding,
                    child: _LabeledDivider(text: t.cpf_or_enter_manually),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 20),
                Padding(
                  padding: _kPagePadding,
                  child: MoozeTextField(
                    controller: _controller,
                    focusNode: _cpfFocus,
                    inputFormatters: [_formatter],
                    keyboardType: TextInputType.number,
                    autofocus: !hasFavorites,
                    textInputAction: TextInputAction.done,
                    labelText: t.cpf_field_label,
                    hintText: t.cpf_field_hint,
                    errorText: _errorText(t),
                    onSubmitted: (_) {
                      if (canContinue) _submit(canSave);
                    },
                  ),
                ),
                // Contextual "save this payer" — only after a valid new CPF.
                if (canSave) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: _kPagePadding,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _saveThisPayer,
                      onChanged:
                          (v) => setState(() => _saveThisPayer = v ?? false),
                      title: Text(t.cpf_save_this_payer),
                    ),
                  ),
                  if (_saveThisPayer)
                    Padding(
                      padding: _kPagePadding,
                      child: MoozeTextField(
                        controller: _labelController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        labelText: t.cpf_favorite_label,
                        hintText: t.cpf_favorite_label_hint,
                      ),
                    ),
                ],
                const SizedBox(height: 15),
                Padding(
                  padding: _kPagePadding,
                  child: InfoTipsSection(
                    tips: [
                      InfoTip(
                        icon: Icons.info_outline,
                        text: t.cpf_payment_warning,
                        iconColor: context.appColors.warning,
                      ),
                    ],
                    maxTips: 1,
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

/// Sticky bottom action bar — stays above the keyboard and is always visible.
class _ContinueBar extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContinueBar({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: SlideToConfirmButton(
          text: t.merchant_generate_qr,
          isEnabled: enabled,
          isLoading: isLoading,
          onSlideComplete: onPressed,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _LabeledDivider extends StatelessWidget {
  final String text;
  const _LabeledDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: Theme.of(context).textTheme.labelMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
