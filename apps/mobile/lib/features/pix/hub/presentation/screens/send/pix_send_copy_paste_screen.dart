import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_section_header.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Pix Copy and Paste step of the send flow.
///
/// The screen reads the structure and the CRC16 of the code. Those checks say
/// that the text is a well-formed Pix code, not that the charge exists or that
/// it can be paid. The backend pays a Pix key, so only a code that carries a
/// key can continue.
///
/// The code goes in a glass field with a paste pill below it. When the code
/// is valid, the data read from it grows in below the pill.
class PixSendCopyPasteScreen extends ConsumerStatefulWidget {
  const PixSendCopyPasteScreen({super.key});

  @override
  ConsumerState<PixSendCopyPasteScreen> createState() =>
      _PixSendCopyPasteScreenState();
}

class _PixSendCopyPasteScreenState
    extends ConsumerState<PixSendCopyPasteScreen> {
  final TextEditingController _controller = TextEditingController();
  PixBrCode? _parsed;
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _submitted = false;
      _parsed = value.trim().isEmpty ? null : PixBrCodeParser.parse(value);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).pix_hub_code_clipboard_empty,
      );
      return;
    }
    _controller.text = text;
    _onChanged(text);
  }

  void _continue() {
    setState(() {
      _submitted = true;
      _parsed = PixBrCodeParser.parse(_controller.text);
    });
    final parsed = _parsed;
    if (parsed == null || !parsed.isStructurallyValid) return;

    FocusScope.of(context).unfocus();
    final failure = ref
        .read(pixSendControllerProvider.notifier)
        .startFromCode(_controller.text, scanned: false);

    if (failure != null) {
      AppSnackBar.error(
        context,
        pixHubFailureMessage(AppLocalizations.of(context), failure),
      );
      return;
    }
    // The amount step also asks for the tax ID of the key owner, so a code
    // with a fixed amount passes through it too.
    context.push('/pix/send/amount');
  }

  /// Masked key of the code, or the "no key" text for a dynamic code.
  String _keyEntry(AppLocalizations t, PixBrCode parsed) {
    final key = parsed.pixKey;
    if (key == null) return t.pix_hub_code_no_key;
    final type = PixKeyValidator.validate(key).type ?? PixKeyType.random;
    return maskPixKey(type, key);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final parsed = _parsed;
    final showError =
        _submitted && parsed != null && !parsed.isStructurallyValid;
    final isRead = parsed != null && parsed.isStructurallyValid;

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_send_title,
      title: t.pix_hub_method_copy_paste,
      subtitle: t.pix_hub_code_input_hint,
      bottomAction: PrimaryButton(
        text: t.common_continue,
        isEnabled: _controller.text.trim().isNotEmpty,
        onPressed: _continue,
      ),
      children: [
        _CodeField(
          controller: _controller,
          onChanged: _onChanged,
          errorText: showError ? pixBrCodeErrorMessage(t, parsed.error!) : null,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _PastePill(
            label: t.pix_hub_code_paste,
            onPressed: _pasteFromClipboard,
          ),
        ),
        // The data read from the code grows in when the code is valid.
        SizeFadeSwitcher(
          child: isRead
              ? Column(
                  key: const ValueKey('read'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    PixSectionHeader(title: t.pix_hub_code_read_title),
                    const SizedBox(height: 8),
                    PixSummaryCard(
                      entries: [
                        PixSummaryEntry(
                          t.pix_hub_summary_recipient,
                          parsed.merchantName ?? t.pix_hub_value_unavailable,
                        ),
                        PixSummaryEntry(
                          t.pix_hub_method_key,
                          _keyEntry(t, parsed),
                        ),
                        PixSummaryEntry(
                          t.pix_hub_summary_amount,
                          parsed.amountInCents == null
                              ? t.pix_hub_link_open_amount
                              : formatBrlCents(parsed.amountInCents!),
                          highlight: parsed.amountInCents != null,
                        ),
                        if (parsed.merchantCity != null)
                          PixSummaryEntry(
                            t.pix_hub_summary_city,
                            parsed.merchantCity!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Note(t.pix_hub_code_local_check_warning),
                  ],
                )
              : const SizedBox(key: ValueKey('empty'), width: double.infinity),
        ),
      ],
    );
  }
}

/// The multi-line field that takes the Pix code.
///
/// It is a glass lens on the page, because a code runs over several lines
/// and needs a frame. The code uses a monospaced face, so the user can
/// compare it with the source.
class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _CodeField({
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );
    final codeStyle = context.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      // iOS has no font named "monospace", so it takes the fallback.
      fontFamilyFallback: const ['Menlo', 'Courier'],
      color: context.colors.textPrimary,
      height: 1.45,
    );
    final hairline = AppSurfaces.hairline(context);
    final t = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      maxLines: 6,
      minLines: 4,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: context.colors.primaryColor,
      style: codeStyle,
      decoration: InputDecoration(
        hintText: t.pix_hub_code_input_placeholder,
        hintStyle: codeStyle?.copyWith(color: context.colors.textTertiary),
        filled: true,
        fillColor: GlassStyle.of(context).lensFill,
        contentPadding: const EdgeInsets.all(16),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: context.textTheme.bodySmall?.copyWith(
          color: context.colors.negativeColor,
          height: 1.4,
        ),
        border: frame(hairline, 1),
        enabledBorder: frame(hairline, 1),
        focusedBorder: frame(context.colors.primaryColor, 1.5),
        errorBorder: frame(context.colors.negativeColor, 1),
        focusedErrorBorder: frame(context.colors.negativeColor, 1.5),
      ),
    );
  }
}

/// A tonal pill that pastes the clipboard into the field.
///
/// It is a secondary action, so it stays neutral and leaves the brand pink
/// to the continue button.
class _PastePill extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PastePill({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textPrimary;
    return PressScale(
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor: GlassStyle.of(context).lensFill,
          // The pill is 40 pt high. The padded tap target makes it 48 pt.
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: StadiumBorder(
            side: BorderSide(color: AppSurfaces.hairline(context)),
          ),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: PixIcon(PixIcons.paste, size: 18, color: color),
        label: Text(label),
      ),
    );
  }
}

/// A secondary note with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Row(
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
    );
  }
}
