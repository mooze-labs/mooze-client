import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/node_settings_controller.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/node_settings/node_mode_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';

enum _ExitChoice { save, discard, cancel }

class NodeSettingsScreen extends ConsumerStatefulWidget {
  const NodeSettingsScreen({super.key});

  @override
  ConsumerState<NodeSettingsScreen> createState() => _NodeSettingsScreenState();
}

class _NodeSettingsScreenState extends ConsumerState<NodeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bitcoinController = TextEditingController();
  final _liquidController = TextEditingController();

  bool _saving = false;
  bool _initialized = false;

  // Snapshot of the saved (persisted) state — used to compute whether
  // the form has unsaved changes so the save button can disable itself
  // when there's nothing to do.
  NodeSettingsState? _baseline;

  @override
  void dispose() {
    _bitcoinController.dispose();
    _liquidController.dispose();
    super.dispose();
  }

  /// Permits host:port and scheme://host:port. An empty value is valid:
  /// a blank endpoint falls back to the default node for that chain, so
  /// users can customise just one of the two. The "at least one endpoint"
  /// rule is enforced at save time.
  String? _validateUrl(String? value, AppLocalizations t) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;

    final stripped = v.contains('://') ? v.split('://').last : v;
    final hostPort = stripped.split('/').first;
    final parts = hostPort.split(':');
    if (parts.length != 2) return t.node_config_url_invalid;

    final host = parts[0];
    final port = int.tryParse(parts[1]);
    if (host.isEmpty) return t.node_config_url_invalid;
    if (port == null || port <= 0 || port > 65535) {
      return t.node_config_url_invalid;
    }
    return null;
  }

  bool _isDirty(NodeSettingsState state) {
    final base = _baseline;
    if (base == null) return true;
    return state.isCustomMode != base.isCustomMode ||
        state.bitcoinUrl.trim() != base.bitcoinUrl.trim() ||
        state.liquidUrl.trim() != base.liquidUrl.trim() ||
        state.fallbackEnabled != base.fallbackEnabled;
  }

  /// Returns true when the form was successfully persisted, false on
  /// validation failure or save error.
  Future<bool> _attemptSave() async {
    final t = AppLocalizations.of(context);
    final controller = ref.read(nodeSettingsControllerProvider.notifier);
    final current = ref.read(nodeSettingsControllerProvider).value;
    if (current == null) return false;

    if (current.isCustomMode) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return false;
      final btc = _bitcoinController.text.trim();
      final liquid = _liquidController.text.trim();
      // At least one endpoint must be set in custom mode; an entirely
      // blank custom config is indistinguishable from default mode.
      if (btc.isEmpty && liquid.isEmpty) {
        AppSnackBar.error(context, t.node_config_at_least_one);
        return false;
      }
      controller.setBitcoinUrl(btc);
      controller.setLiquidUrl(liquid);
    }

    setState(() => _saving = true);
    final error = await controller.save();
    if (!mounted) return false;
    setState(() => _saving = false);

    if (error == null) {
      final refreshed = ref.read(nodeSettingsControllerProvider).value;
      if (refreshed != null) _baseline = refreshed;
      AppSnackBar.success(context, t.node_config_save_success);
      return true;
    }

    AppSnackBar.error(context, t.node_config_save_error(error));
    return false;
  }

  Future<void> _handleSave() async {
    await _attemptSave();
  }

  /// Shows the unsaved-changes dialog and returns whether the user
  /// confirmed exit. When the user picks "save", we attempt to persist
  /// first and only allow exit if the save succeeded.
  Future<bool> _confirmExit(AppLocalizations t) async {
    final colorScheme = Theme.of(context).colorScheme;
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(t.node_config_unsaved_title),
            content: Text(t.node_config_unsaved_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(_ExitChoice.cancel),
                child: Text(t.common_cancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                onPressed: () => Navigator.of(ctx).pop(_ExitChoice.discard),
                child: Text(t.node_config_unsaved_discard),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(_ExitChoice.save),
                child: Text(t.common_save),
              ),
            ],
          ),
    );

    switch (choice) {
      case _ExitChoice.save:
        return await _attemptSave();
      case _ExitChoice.discard:
        return true;
      case _ExitChoice.cancel:
      case null:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final asyncState = ref.watch(nodeSettingsControllerProvider);
    final currentState = asyncState.value;

    // Seed the controllers and baseline from the first loaded snapshot
    // here — before computing canPop — so an untouched screen reports no
    // unsaved changes and doesn't pop the exit dialog on the first frame.
    if (currentState != null && !_initialized) {
      _bitcoinController.text = currentState.bitcoinUrl;
      _liquidController.text = currentState.liquidUrl;
      _baseline = currentState;
      _initialized = true;
    }

    // Block accidental exit only when there are unsaved changes and we
    // aren't already in the middle of a save.
    final canPop =
        currentState == null ? true : !_isDirty(currentState) && !_saving;

    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExit(t);
        if (!mounted) return;
        if (shouldExit) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.node_config_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            // Goes through PopScope so the unsaved-changes dialog
            // surfaces consistently with system back / iOS swipe-back.
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: PlatformSafeArea(
          child: asyncState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, _) => _ErrorView(
                  message: t.node_config_load_error,
                  color: colorScheme.error,
                ),
            data: (state) => _buildContent(context, t, state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations t,
    NodeSettingsState state,
  ) {
    final controller = ref.read(nodeSettingsControllerProvider.notifier);
    final isCustom = state.isCustomMode;
    final dirty = _isDirty(state);

    return Form(
      key: _formKey,
      autovalidateMode:
          isCustom
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: t.node_config_section_mode),
            NodeModeCard(
              icon: Icons.shield_moon_rounded,
              title: t.node_config_mode_default_title,
              subtitle: t.node_config_mode_default_subtitle,
              selected: !isCustom,
              onTap: () {
                controller.setCustomMode(false);
                _formKey.currentState?.reset();
              },
            ),
            const SizedBox(height: 10),
            NodeModeCard(
              icon: Icons.tune_rounded,
              title: t.node_config_mode_custom_title,
              subtitle: t.node_config_mode_custom_subtitle,
              selected: isCustom,
              onTap: () => controller.setCustomMode(true),
            ),
            const SizedBox(height: 28),

            // Custom-mode block: smoothly expands/collapses with
            // mode toggle. AnimatedSize controls the height,
            // AnimatedSwitcher cross-fades the contents so the
            // transition feels natural rather than abrupt.
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder:
                    (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                child:
                    isCustom
                        ? _CustomModeSection(
                          key: const ValueKey('custom-section'),
                          t: t,
                          state: state,
                          bitcoinController: _bitcoinController,
                          liquidController: _liquidController,
                          onBitcoinChanged: controller.setBitcoinUrl,
                          onLiquidChanged: controller.setLiquidUrl,
                          onFallbackChanged: controller.setFallbackEnabled,
                          urlValidator: (v) => _validateUrl(v, t),
                        )
                        : const SizedBox(
                          key: ValueKey('default-section'),
                          width: double.infinity,
                        ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: t.node_config_save,
              onPressed: _handleSave,
              isEnabled: dirty && !_saving,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomModeSection extends StatelessWidget {
  final AppLocalizations t;
  final NodeSettingsState state;
  final TextEditingController bitcoinController;
  final TextEditingController liquidController;
  final ValueChanged<String> onBitcoinChanged;
  final ValueChanged<String> onLiquidChanged;
  final ValueChanged<bool> onFallbackChanged;
  final FormFieldValidator<String> urlValidator;

  const _CustomModeSection({
    super.key,
    required this.t,
    required this.state,
    required this.bitcoinController,
    required this.liquidController,
    required this.onBitcoinChanged,
    required this.onLiquidChanged,
    required this.onFallbackChanged,
    required this.urlValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdvancedWarning(message: t.node_config_advanced_warning),
        const SizedBox(height: 18),
        _SectionHeader(label: t.node_config_section_custom),
        _UrlField(
          controller: bitcoinController,
          label: t.node_config_bitcoin_label,
          hint: t.node_config_bitcoin_hint,
          helper: t.node_config_bitcoin_helper,
          onChanged: onBitcoinChanged,
          validator: urlValidator,
        ),
        const SizedBox(height: 18),
        _UrlField(
          controller: liquidController,
          label: t.node_config_liquid_label,
          hint: t.node_config_liquid_hint,
          helper: t.node_config_liquid_helper,
          onChanged: onLiquidChanged,
          validator: urlValidator,
        ),
        const SizedBox(height: 22),
        _FallbackTile(
          value: state.fallbackEnabled,
          onChanged: onFallbackChanged,
          title: t.node_config_fallback_toggle_title,
          subtitle: t.node_config_fallback_toggle_subtitle,
        ),
        const SizedBox(height: 16),
        _LightningNote(text: t.node_config_lightning_note),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdvancedWarning extends StatelessWidget {
  final String message;
  const _AdvancedWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const _UrlField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontFamily: 'monospace',
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const _FallbackTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}

class _LightningNote extends StatelessWidget {
  final String text;
  const _LightningNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.flash_on_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Color color;
  const _ErrorView({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
