import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_deposit_ownership_notice.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_underline_field.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_cnpj_input_formatter.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Step the user walks through before their first Pix deposit.
///
/// It collects the CPF and takes the acknowledgement of the bank account
/// ownership notice. Both are kept on the device: Mooze has no service that
/// registers a CPF or that proves who owns the paying bank account, so the
/// screen never states that the CPF was verified with an institution.
///
/// The CPF is a bare underline field, as in the send flow. The notice keeps
/// its warning tint, and the acknowledgement sits right below it.
class PixDepositGateScreen extends ConsumerStatefulWidget {
  /// Route opened once the user completes this screen.
  ///
  /// Defaults to the deposit flow. The notice screen reopens this screen to
  /// change the CPF, and then there is nothing else to open.
  final String? nextRoute;

  const PixDepositGateScreen({super.key, this.nextRoute = '/pix/deposit'});

  @override
  ConsumerState<PixDepositGateScreen> createState() =>
      _PixDepositGateScreenState();
}

class _PixDepositGateScreenState extends ConsumerState<PixDepositGateScreen> {
  final TextEditingController _controller = TextEditingController();
  final CpfCnpjInputFormatter _formatter = CpfCnpjInputFormatter();

  bool _touched = false;
  bool _acknowledged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final service = ref.read(pixDepositProfileServiceProvider);
    final stored = service.taxIdNumber();
    if (stored != null) {
      _controller.text = formatCpfCnpj(stored);
    }
    _acknowledged = service.hasAcknowledgedOwnershipNotice();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _digits => CpfValidator.strip(_controller.text);

  bool get _isValid => CpfValidator.isValid(_controller.text);

  String? _errorText(AppLocalizations t) {
    if (!_touched) return null;
    return switch (CpfValidator.validate(_controller.text)) {
      null => null,
      CpfValidationError.empty => t.cpf_error_required,
      CpfValidationError.incomplete => t.cpf_error_incomplete,
      CpfValidationError.invalid => t.cpf_error_invalid,
    };
  }

  Future<void> _continue() async {
    setState(() => _touched = true);
    if (!_isValid || !_acknowledged) return;

    setState(() => _isSaving = true);
    final service = ref.read(pixDepositProfileServiceProvider);
    await service.saveTaxIdNumber(_digits);
    await service.acknowledgeOwnershipNotice();

    if (!mounted) return;
    setState(() => _isSaving = false);

    final next = widget.nextRoute;
    if (next == null) {
      context.pop();
      return;
    }
    context.pushReplacement(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canContinue = _isValid && _acknowledged;
    final errorText = _errorText(t);

    return PixScreenScaffold(
      appBarTitle: t.pix_hub_shortcut_deposit,
      title: t.pix_hub_deposit_gate_title,
      subtitle: t.pix_hub_deposit_gate_subtitle,
      bottomAction: PrimaryButton(
        text: t.common_continue,
        isEnabled: canContinue,
        isLoading: _isSaving,
        onPressed: _continue,
      ),
      children: [
        // The label and the field read as one control.
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(t.cpf_field_label),
              PixUnderlineField(
                controller: _controller,
                autofocus: true,
                inputFormatters: [_formatter],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                hintText: t.cpf_field_hint,
                errorText: errorText,
                onSubmitted: _continue,
                suffixIcon: _TaxIdStatusIcon(
                  isValid: _isValid,
                  hasError: errorText != null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Hint(t.pix_hub_deposit_cpf_hint),
        const SizedBox(height: 28),
        const PixDepositOwnershipNotice(),
        const SizedBox(height: 8),
        _AcknowledgeTile(
          label: t.pix_hub_deposit_notice_ack,
          value: _acknowledged,
          onChanged: (value) => setState(() => _acknowledged = value),
        ),
      ],
    );
  }
}

/// Reopens the ownership notice after the user acknowledged it.
class PixDepositNoticeScreen extends ConsumerWidget {
  const PixDepositNoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final service = ref.watch(pixDepositProfileServiceProvider);
    final taxId = service.taxIdNumber();

    return PixScreenScaffold(
      title: t.pix_hub_deposit_notice_screen_title,
      bottomAction: SecondaryButton(
        text: t.pix_hub_deposit_change_cpf,
        onPressed: () => context.push('/pix/deposit/cpf'),
      ),
      children: [
        const PixDepositOwnershipNotice(),
        const SizedBox(height: 24),
        PixSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: MergeSemantics(
            child: Row(
              children: [
                const PixIconWell(icon: PixIcons.idCard),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.pix_hub_deposit_cpf_stored_label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        taxId == null
                            ? t.pix_hub_deposit_cpf_missing
                            : formatCpfCnpj(taxId),
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: taxId == null
                              ? context.colors.textSecondary
                              : context.colors.textPrimary,
                          fontWeight: taxId == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Hint(t.pix_hub_deposit_cpf_hint),
      ],
    );
  }
}

/// Small label above a field.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// Secondary note below an input.
class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textTertiary,
        height: 1.4,
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

/// Checkbox row that confirms the ownership notice.
///
/// The whole row is the touch target. The checked box uses the brand
/// color, because it marks a selection.
class _AcknowledgeTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AcknowledgeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
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
