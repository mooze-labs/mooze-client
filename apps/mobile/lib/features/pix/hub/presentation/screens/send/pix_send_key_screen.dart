import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_destination.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_destination_input_formatter.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_underline_field.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Destination step of the send flow.
///
/// One field takes any Pix key or a pasted Pix Copy and Paste code, and the
/// screen detects which one it is. A valid CPF that is also a mobile number
/// makes the user choose. Mooze checks the format only. When the backend
/// creates the withdrawal, the Pix provider checks that the key belongs to
/// the CPF or CNPJ of the amount step.
///
/// The field sits on the page with the scanner at its end. Below it, one
/// line follows the input: a paste shortcut, the detected format, or the
/// CPF or phone choice. The line changes with a short fade.
class PixSendKeyScreen extends ConsumerStatefulWidget {
  const PixSendKeyScreen({super.key});

  @override
  ConsumerState<PixSendKeyScreen> createState() => _PixSendKeyScreenState();
}

class _PixSendKeyScreenState extends ConsumerState<PixSendKeyScreen> {
  final TextEditingController _controller = TextEditingController();

  PixDestination _destination = PixDestinationParser.parse('');

  /// The reading the user picked for a number that is a CPF and a phone.
  PixKeyType _numberType = PixKeyType.cpf;

  /// True after a continue tap, so errors stay hidden while the user types.
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _destination = PixDestinationParser.parse(value);
      _numberType = PixKeyType.cpf;
      _submitted = false;
    });
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
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
    // A text set by code skips the input formatters, so mask it here.
    final value = PixDestinationInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    _controller.value = value;
    _onChanged(value.text);
  }

  /// Applies the reading picked for a number that is a CPF and a phone, and
  /// masks the number to match it.
  void _chooseNumberType(PixKeyType type) {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final text = type == PixKeyType.phone
        ? PixDestinationInputFormatter.formatMobile(digits)
        : formatCpfCnpj(digits);
    setState(() => _numberType = type);
    // Setting the value by code does not call onChanged, so the choice stays.
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _continue() {
    setState(() => _submitted = true);
    final controller = ref.read(pixSendControllerProvider.notifier);

    final PixKeyValidation? key = switch (_destination.kind) {
      PixDestinationKind.key => _destination.key,
      PixDestinationKind.cpfOrPhone =>
        _numberType == PixKeyType.phone ? _destination.phone : _destination.key,
      _ => null,
    };

    if (key != null) {
      FocusScope.of(context).unfocus();
      controller.startFromKey(key.type!, key.normalized);
      context.push('/pix/send/amount');
      return;
    }

    if (_destination.kind == PixDestinationKind.code) {
      FocusScope.of(context).unfocus();
      final failure = controller.startFromCode(
        _controller.text,
        scanned: false,
      );
      if (failure != null) {
        AppSnackBar.error(
          context,
          pixHubFailureMessage(AppLocalizations.of(context), failure),
        );
        return;
      }
      context.push('/pix/send/amount');
    }
  }

  /// The error of the field, shown only after a continue tap.
  String? _error(AppLocalizations t) {
    if (!_submitted || _destination.kind != PixDestinationKind.invalid) {
      return null;
    }
    final codeError = _destination.code?.error;
    if (codeError != null) return pixBrCodeErrorMessage(t, codeError);
    final keyError = _destination.key?.error;
    return keyError == null ? null : pixKeyValidationMessage(t, keyError);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasText = _destination.kind != PixDestinationKind.empty;

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_send_title,
      title: t.pix_hub_send_key_title,
      subtitle: t.pix_hub_send_key_label,
      bottomAction: PrimaryButton(
        text: t.common_continue,
        isEnabled: hasText,
        onPressed: _continue,
      ),
      children: [
        PixUnderlineField(
          controller: _controller,
          autofocus: true,
          hintText: t.pix_hub_send_key_hint,
          errorText: _error(t),
          keyboardType: TextInputType.emailAddress,
          inputFormatters: [PixDestinationInputFormatter()],
          textInputAction: TextInputAction.done,
          onChanged: _onChanged,
          onSubmitted: hasText ? _continue : null,
          // The clear action shows only when the field has text. The scanner
          // stays at the end of the field in every state.
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                _FieldIconButton(
                  icon: PixIcons.close,
                  tooltip: t.pix_hub_send_key_clear,
                  color: context.colors.textTertiary,
                  onPressed: _clear,
                ),
              _FieldIconButton(
                icon: PixIcons.scan,
                tooltip: t.pix_hub_send_key_scan,
                color: context.colors.textPrimary,
                onPressed: () => context.push('/pix/send/scan'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // The line below the field changes with what the field holds. It is
        // the last block of the page, so it fades only: nothing below it
        // moves, and the new chips take taps at once.
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.durationFast),
          switchInCurve: Motion.curveEnter,
          switchOutCurve: Motion.curveExit,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.topStart,
            children: [...previous, if (current != null) current],
          ),
          child: KeyedSubtree(
            // The key follows the kind only, so a CPF or phone choice
            // updates the chips in place.
            key: ValueKey(_destination.kind),
            child: _Feedback(
              destination: _destination,
              numberType: _numberType,
              onPaste: _pasteFromClipboard,
              onNumberType: _chooseNumberType,
            ),
          ),
        ),
      ],
    );
  }
}

/// An icon button inside the field, with a 48 pt touch target.
class _FieldIconButton extends StatelessWidget {
  final PixIconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _FieldIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: PixIcon(icon, size: 22, color: color),
    );
  }
}

/// The line below the field: a paste shortcut, the detected format, or the
/// choice between CPF and phone.
class _Feedback extends StatelessWidget {
  final PixDestination destination;
  final PixKeyType numberType;
  final VoidCallback onPaste;
  final ValueChanged<PixKeyType> onNumberType;

  const _Feedback({
    required this.destination,
    required this.numberType,
    required this.onPaste,
    required this.onNumberType,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    switch (destination.kind) {
      case PixDestinationKind.empty:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: _PastePill(label: t.pix_hub_code_paste, onPressed: onPaste),
        );
      case PixDestinationKind.key:
        return _DetectedLine(
          text: t.pix_hub_key_detected(
            pixKeyTypeLabel(t, destination.key!.type!),
          ),
        );
      case PixDestinationKind.code:
        return _DetectedLine(text: t.pix_hub_send_key_code_detected);
      case PixDestinationKind.cpfOrPhone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.pix_hub_send_key_ambiguous,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in const [PixKeyType.cpf, PixKeyType.phone])
                  _NumberTypeChip(
                    type: type,
                    selected: numberType == type,
                    onSelected: () => onNumberType(type),
                  ),
              ],
            ),
          ],
        );
      case PixDestinationKind.invalid:
        // The field shows the error after a continue tap.
        return const SizedBox(width: double.infinity);
    }
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

/// One reading of a number that is a CPF and a phone.
///
/// The selected chip has a brand border, a light brand fill, and a check in
/// place of the type icon, so the selection never depends on color alone.
class _NumberTypeChip extends StatelessWidget {
  final PixKeyType type;
  final bool selected;
  final VoidCallback onSelected;

  const _NumberTypeChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = context.colors.primaryColor;
    final foreground = selected
        ? context.colors.textPrimary
        : context.colors.textSecondary;

    return ChoiceChip(
      label: Text(pixKeyTypeLabel(t, type)),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: PixIcon(
        selected ? PixIcons.check : pixKeyTypeIcon(type),
        size: 16,
        color: selected ? primary : foreground,
      ),
      labelStyle: context.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      color: WidgetStatePropertyAll(
        selected
            ? primary.withValues(alpha: 0.12)
            : GlassStyle.of(context).lensFill,
      ),
      side: BorderSide(
        color: selected ? primary : AppSurfaces.hairline(context),
        width: selected ? 1.4 : 1,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

/// A small confirmation of what the field holds.
///
/// The check icon and the text carry the state together with the color.
class _DetectedLine extends StatelessWidget {
  final String text;

  const _DetectedLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.positiveColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(PixIcons.success, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
