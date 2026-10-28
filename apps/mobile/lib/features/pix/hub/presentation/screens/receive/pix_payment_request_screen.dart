import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_action_tile.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_amount_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Creates the charge another person pays.
///
/// The amount is the hero of the step. The options of the charge, the open
/// amount and the receiving key, share one glass group below it. The
/// description is a bare underline field, as in the send flow.
class PixPaymentRequestScreen extends ConsumerStatefulWidget {
  const PixPaymentRequestScreen({super.key});

  @override
  ConsumerState<PixPaymentRequestScreen> createState() =>
      _PixPaymentRequestScreenState();
}

class _PixPaymentRequestScreenState
    extends ConsumerState<PixPaymentRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  int _amountInCents = 0;
  bool _payerChoosesAmount = false;
  bool _submitted = false;
  PixKey? _selectedKey;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? _amountError(AppLocalizations t) {
    if (!_submitted || _payerChoosesAmount) return null;
    if (_amountInCents < PixPaymentRequest.minAmountInCents) {
      return t.pix_hub_charge_error_min(
        formatBrlCents(PixPaymentRequest.minAmountInCents),
      );
    }
    if (_amountInCents > PixPaymentRequest.maxAmountInCents) {
      return t.pix_hub_amount_error_max(
        formatBrlCents(PixPaymentRequest.maxAmountInCents),
      );
    }
    return null;
  }

  Future<void> _create(List<PixKey> keys) async {
    final t = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (_amountError(t) != null) return;

    final key = _selectedKey ?? keys.first;
    final description = _descriptionController.text.trim();

    final created = await ref
        .read(pixPaymentRequestControllerProvider.notifier)
        .create(
          key: key,
          amountInCents: _payerChoosesAmount ? null : _amountInCents,
          description: description.isEmpty ? null : description,
        );

    if (!mounted) return;
    if (!created) {
      final failure = ref.read(pixPaymentRequestControllerProvider).failure;
      if (failure != null) {
        AppSnackBar.error(context, pixHubFailureMessage(t, failure));
      }
      return;
    }

    final request = ref.read(pixPaymentRequestControllerProvider).request;
    if (request != null) {
      context.push('/pix/receive/request/detail', extra: request);
    }
  }

  /// Opens the key list in a glass sheet and keeps the key the user picks.
  Future<void> _pickKey(List<PixKey> keys, PixKey selected) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<PixKey>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _KeyPickerSheet(keys: keys, selected: selected),
    );
    if (picked != null && mounted) setState(() => _selectedKey = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final keys = ref.watch(pixHubKeysProvider);
    final isBusy = ref.watch(pixPaymentRequestControllerProvider).isBusy;

    final list = keys.valueOrNull ?? const <PixKey>[];
    final selected = _selectedKey ?? (list.isEmpty ? null : list.first);

    return PixScreenScaffold(
      title: t.pix_hub_receive_create_charge,
      subtitle: t.pix_hub_receive_create_charge_subtitle,
      bottomAction: list.isEmpty
          ? null
          : PrimaryButton(
              text: t.pix_hub_charge_create,
              isLoading: isBusy,
              onPressed: () => _create(list),
            ),
      children: [
        SizeFadeSwitcher(
          child: keys.when(
            loading: () => const Padding(
              key: ValueKey('loading'),
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => PixEmptyState(
              key: const ValueKey('error'),
              icon: PixIcons.offline,
              title: t.pix_hub_error_title,
              message: t.pix_hub_error_body,
              actionLabel: t.common_retry,
              onAction: () => ref.invalidate(pixHubKeysProvider),
            ),
            data: (keyList) {
              if (keyList.isEmpty || selected == null) {
                return PixEmptyState(
                  key: const ValueKey('empty'),
                  icon: PixIcons.key,
                  title: t.pix_hub_empty_keys_title,
                  message: t.pix_hub_empty_keys_body,
                );
              }

              return Column(
                key: const ValueKey('form'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Caption(t.pix_hub_amount_label),
                  const SizedBox(height: 10),
                  // The field fades back while the payer chooses the
                  // amount, because it no longer takes input.
                  AnimatedOpacity(
                    opacity: _payerChoosesAmount ? 0.4 : 1,
                    duration: Motion.of(context, Motion.durationFast),
                    curve: Motion.curveMove,
                    child: PixAmountField(
                      autofocus: false,
                      readOnly: _payerChoosesAmount,
                      errorText: _amountError(t),
                      onChanged: (cents) =>
                          setState(() => _amountInCents = cents),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PixSurfaceCard(
                    child: Column(
                      children: [
                        _SwitchRow(
                          icon: PixIcons.amount,
                          title: t.pix_hub_charge_open_amount,
                          subtitle: t.pix_hub_charge_open_amount_hint,
                          value: _payerChoosesAmount,
                          onChanged: (value) =>
                              setState(() => _payerChoosesAmount = value),
                        ),
                        const _RowDivider(),
                        _KeyRow(
                          pixKey: selected,
                          // A single key leaves nothing to choose.
                          onTap: keyList.length > 1
                              ? () => _pickKey(keyList, selected)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DescriptionField(controller: _descriptionController),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The receiving key of the charge, as a row of the options group.
///
/// With more than one key, a tap opens the key list and a chevron shows it.
class _KeyRow extends StatelessWidget {
  final PixKey pixKey;
  final VoidCallback? onTap;

  const _KeyRow({required this.pixKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final value = '${pixKeyTypeLabel(t, pixKey.type)} · ${pixKey.masked}';

    return Semantics(
      button: onTap != null,
      label: t.pix_hub_charge_key_label,
      value: value,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              PixIconWell(icon: pixKeyTypeIcon(pixKey.type)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.pix_hub_charge_key_label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                PixIcon(
                  PixIcons.chevronDown,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating glass sheet that lists the keys of the user.
///
/// The selected key has a brand well and a check, so the selection never
/// depends on color alone. A tap closes the sheet with that key.
class _KeyPickerSheet extends StatelessWidget {
  final List<PixKey> keys;
  final PixKey selected;

  const _KeyPickerSheet({required this.keys, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _SheetHandle()),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Semantics(
              header: true,
              child: Text(
                t.pix_hub_charge_key_label,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (index, key) in keys.indexed) ...[
                    if (index > 0) const _RowDivider(),
                    _KeyOption(
                      pixKey: key,
                      isSelected: key.id == selected.id,
                      onTap: () => Navigator.of(context).pop(key),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One key of the key list.
class _KeyOption extends StatelessWidget {
  final PixKey pixKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _KeyOption({
    required this.pixKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = pixKey.label ?? pixKeyTypeLabel(t, pixKey.type);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, ${pixKey.masked}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              PixIconWell(
                icon: pixKeyTypeIcon(pixKey.type),
                tone: isSelected ? PixTone.brand : PixTone.neutral,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pixKey.masked,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                PixIcon(
                  PixIcons.check,
                  size: 20,
                  color: context.colors.primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of the options group with a switch at the end.
///
/// A tap anywhere on the row flips the switch. [MergeSemantics] reads the
/// title, the hint, and the switch state as one control.
class _SwitchRow extends StatelessWidget {
  final PixIconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              PixIconWell(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional message of the charge, drawn as a bare underline.
///
/// It follows the underline fields of the send flow. Unlike those, it keeps
/// sentence capitalization and suggestions, because it holds free text.
class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    UnderlineInputBorder line(Color color, double width) =>
        UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(t.pix_hub_description_label),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: t.pix_hub_description_hint,
            hintStyle: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            // The field sits on the page, where the light outline variant
            // has the page color. The outline shows in both themes.
            border: line(context.colorScheme.outline, 1),
            enabledBorder: line(context.colorScheme.outline, 1),
            focusedBorder: line(context.colors.primaryColor, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Caption above an input, as in the send flow.
class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Short bar at the top of a sheet that shows it can be dragged down.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.onSurface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Hairline between two rows of a panel. It starts at the row text.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: PixActionTile.textInset,
      color: AppSurfaces.hairline(context),
    );
  }
}
