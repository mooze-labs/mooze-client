import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/widgets/favorite_payer_picker_sheet.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/widgets/info_tips_section.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const int _kCarouselFavorites = 5;

const EdgeInsets _kPagePadding = EdgeInsets.symmetric(
  horizontal: PixScreenScaffold.gutter,
);

/// Asks for the CPF or CNPJ of the payer before a Pix charge.
///
/// The layout follows the Pix screens: the backdrop behind a clear app bar,
/// a large title, and the main action pinned at the bottom, above the
/// keyboard. Saved payers run edge to edge in a chip row, so the screen does
/// not use [PixScreenScaffold], which pads all content.
class CpfInputScreen extends ConsumerStatefulWidget {
  /// Taxpayer id digits used to prefill the field.
  ///
  /// The Pix deposit flow passes the CPF the user already informed, so the
  /// screen opens filled and the user only confirms it.
  final String? initialTaxId;

  const CpfInputScreen({super.key, this.initialTaxId});

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
    final initial = widget.initialTaxId;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = formatCpfCnpj(CpfValidator.strip(initial));
    }
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
    final errorText = _errorText(t);

    final content = ListView(
      // No horizontal padding here — the gutter is applied per-section so
      // the favorites carousel below can run edge-to-edge.
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        Padding(
          padding: _kPagePadding,
          child: PixScreenTitle(
            title: t.cpf_screen_title,
            subtitle: t.cpf_screen_subtitle,
          ),
        ),
        const SizedBox(height: 28),
        if (hasFavorites) ...[
          // "View all" sits in the header so it stays visible while the
          // capped chip row scrolls horizontally.
          Padding(
            padding: _kPagePadding,
            child: PixSectionHeader(
              title: t.cpf_favorites_section,
              actionLabel: favorites.length > _kCarouselFavorites
                  ? t.cpf_favorites_view_all
                  : null,
              onAction: _openPicker,
            ),
          ),
          const SizedBox(height: 8),
          // Full-bleed row: the gutter is the list's own padding so chips
          // scroll flush with the screen edges.
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: _kPagePadding,
              itemCount: favorites.length < _kCarouselFavorites
                  ? favorites.length
                  : _kCarouselFavorites,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final payer = favorites[index];
                return _PayerChip(
                  payer: payer,
                  selected: _digits == payer.cpf,
                  onSelected: () => _selectFavorite(payer),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: _kPagePadding,
            child: _LabeledDivider(text: t.cpf_or_enter_manually),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: _kPagePadding,
          child: _LabeledField(
            label: t.cpf_field_label,
            controller: _controller,
            focusNode: _cpfFocus,
            inputFormatters: [_formatter],
            keyboardType: TextInputType.number,
            autofocus: !hasFavorites,
            textInputAction: TextInputAction.done,
            hintText: t.cpf_field_hint,
            errorText: errorText,
            onSubmitted: (_) {
              if (canContinue) _submit(canSave);
            },
            suffixIcon: _TaxIdStatusIcon(
              isValid: _isValidCpf,
              hasError: errorText != null,
            ),
          ),
        ),
        // Contextual "save this payer" — only after a valid new CPF.
        SizeFadeSwitcher(
          child: !canSave
              ? const SizedBox(
                  key: ValueKey('cpf-no-save'),
                  width: double.infinity,
                )
              : Column(
                  key: const ValueKey('cpf-save'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      // The checkbox lines up with the field text.
                      padding: const EdgeInsets.symmetric(
                        horizontal: PixScreenScaffold.gutter - 4,
                      ),
                      child: _CheckTile(
                        label: t.cpf_save_this_payer,
                        value: _saveThisPayer,
                        onChanged: (v) => setState(() => _saveThisPayer = v),
                      ),
                    ),
                    SizeFadeSwitcher(
                      child: !_saveThisPayer
                          ? const SizedBox(
                              key: ValueKey('cpf-no-label'),
                              width: double.infinity,
                            )
                          : Padding(
                              key: const ValueKey('cpf-label'),
                              padding: _kPagePadding.copyWith(top: 8),
                              child: _LabeledField(
                                label: t.cpf_favorite_label,
                                controller: _labelController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                hintText: t.cpf_favorite_label_hint,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: _kPagePadding,
          child: InfoTipsSection(
            tips: [
              InfoTip(
                pixIcon: PixIcons.warning,
                iconColor: context.appColors.warning,
                text: t.cpf_payment_warning,
              ),
            ],
            maxTips: 1,
          ),
        ),
      ],
    );

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: const BackdropAppBar(),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: _Entrance(
                child: Column(
                  children: [
                    Expanded(child: content),
                    // Pinned above the keyboard, so it stays reachable while
                    // the user types.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        PixScreenScaffold.gutter,
                        8,
                        PixScreenScaffold.gutter,
                        12,
                      ),
                      child: PrimaryButton(
                        text: t.merchant_generate_qr,
                        isEnabled: canContinue,
                        isLoading: _isSubmitting,
                        onPressed: () => _submit(canSave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A saved payer in the chip row.
///
/// The selected chip has a brand border and a check in place of the person
/// icon, so the selection never depends on color alone.
class _PayerChip extends StatelessWidget {
  final FavoritePayer payer;
  final bool selected;
  final VoidCallback onSelected;

  const _PayerChip({
    required this.payer,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    return ChoiceChip(
      avatar: PixIcon(
        selected ? PixIcons.check : PixIcons.person,
        size: 16,
        color: selected ? primary : context.colors.textSecondary,
      ),
      label: Text(payer.label),
      tooltip: payer.maskedCpf,
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      shape: const StadiumBorder(),
      backgroundColor: GlassStyle.of(context).lensFill,
      selectedColor: primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? primary : AppSurfaces.hairline(context),
        width: selected ? 1.4 : 1,
      ),
      labelStyle: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

/// A label above a bare underline field, as in the Pix send flow.
///
/// The label and the field merge into one node for screen readers.
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Widget? suffixIcon;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.autofocus = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    UnderlineInputBorder line(Color color, double width) =>
        UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            autocorrect: false,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onSubmitted: onSubmitted,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textTertiary,
              ),
              errorText: errorText,
              errorMaxLines: 2,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              // The field sits on the page, where the light outline variant
              // has the page color. The outline shows in both themes.
              border: line(context.colorScheme.outline, 1),
              enabledBorder: line(context.colorScheme.outline, 1),
              focusedBorder: line(context.colors.primaryColor, 1.5),
              errorBorder: line(context.colors.negativeColor, 1),
              focusedErrorBorder: line(context.colors.negativeColor, 1.5),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status of the tax ID field, at its trailing edge.
///
/// A valid number shows a check. An error shows an alert next to the error
/// text, so the state never depends on color alone.
class _TaxIdStatusIcon extends StatelessWidget {
  final bool isValid;
  final bool hasError;

  const _TaxIdStatusIcon({required this.isValid, required this.hasError});

  @override
  Widget build(BuildContext context) {
    if (isValid) {
      return Center(
        widthFactor: 1,
        child: PixIcon(
          PixIcons.success,
          size: 20,
          color: context.colors.positiveColor,
          semanticLabel: AppLocalizations.of(context).pix_hub_tax_id_valid,
        ),
      );
    }
    if (hasError) {
      return Center(
        widthFactor: 1,
        child: PixIcon(
          PixIcons.error,
          size: 20,
          color: context.colors.negativeColor,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A checkbox row. The whole row is the touch target.
class _CheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      // The theme draws the box. The outline keeps the empty box visible
      // on the light page.
      side: BorderSide(color: context.colorScheme.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
      onChanged: (checked) => onChanged(checked ?? false),
    );
  }
}

class _LabeledDivider extends StatelessWidget {
  final String text;
  const _LabeledDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    final line = Divider(
      height: 1,
      thickness: 1,
      color: AppSurfaces.hairline(context),
    );
    return Row(
      children: [
        Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
        Expanded(child: line),
      ],
    );
  }
}

/// Fades and raises the content once, when the screen opens.
///
/// It matches the entrance of [PixScreenScaffold]. With reduced motion the
/// content appears at once.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}
