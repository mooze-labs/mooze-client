import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/node_settings_controller.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/node_settings/node_mode_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: Text(t.node_config_unsaved_title),
        content: Text(t.node_config_unsaved_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ExitChoice.cancel),
            child: Text(t.common_cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ctx.colors.negativeColor,
            ),
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
    final canPop = currentState == null
        ? true
        : !_isDirty(currentState) && !_saving;

    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExit(t);
        if (!mounted) return;
        if (shouldExit) navigator.pop();
      },
      child: SettingsPageScaffold(
        title: t.node_config_title,
        leading: BackButton(
          // Goes through PopScope so the unsaved-changes dialog
          // surfaces consistently with system back / iOS swipe-back.
          onPressed: () => Navigator.maybePop(context),
        ),
        // The save button only exists once the settings are loaded, as
        // before, and stays pinned above the bottom edge.
        bottomAction: asyncState.maybeWhen(
          data: (state) => PrimaryButton(
            text: t.node_config_save,
            onPressed: _handleSave,
            isEnabled: _isDirty(state) && !_saving,
            isLoading: _saving,
          ),
          orElse: () => null,
        ),
        body: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorView(message: t.node_config_load_error),
          data: (state) => _buildContent(context, t, state),
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

    return Form(
      key: _formKey,
      autovalidateMode: isCustom
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGlassSection(
              title: t.node_config_section_mode,
              child: Column(
                children: [
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
                  const PanelDivider(indent: 70),
                  NodeModeCard(
                    icon: Icons.tune_rounded,
                    title: t.node_config_mode_custom_title,
                    subtitle: t.node_config_mode_custom_subtitle,
                    selected: isCustom,
                    onTap: () => controller.setCustomMode(true),
                  ),
                ],
              ),
            ),

            // Custom-mode block: smoothly expands/collapses with
            // mode toggle. AnimatedSize controls the height,
            // AnimatedSwitcher cross-fades the contents so the
            // transition feels natural rather than abrupt.
            AnimatedSize(
              duration: Motion.of(context, Motion.durationBase),
              curve: Motion.curveMove,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.durationFast),
                switchInCurve: Motion.curveEnter,
                switchOutCurve: Motion.curveExit,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: isCustom
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdvancedWarning(message: t.node_config_advanced_warning),
        SettingsGlassSection(
          title: t.node_config_section_custom,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UrlField(
                controller: bitcoinController,
                label: t.node_config_bitcoin_label,
                hint: t.node_config_bitcoin_hint,
                helper: t.node_config_bitcoin_helper,
                onChanged: onBitcoinChanged,
                validator: urlValidator,
              ),
              const SizedBox(height: 20),
              _UrlField(
                controller: liquidController,
                label: t.node_config_liquid_label,
                hint: t.node_config_liquid_hint,
                helper: t.node_config_liquid_helper,
                onChanged: onLiquidChanged,
                validator: urlValidator,
              ),
            ],
          ),
        ),
        SettingsGlassSection(
          child: _FallbackTile(
            value: state.fallbackEnabled,
            onChanged: onFallbackChanged,
            title: t.node_config_fallback_toggle_title,
            subtitle: t.node_config_fallback_toggle_subtitle,
          ),
        ),
      ],
    );
  }
}

/// A plain note on the gutter that flags custom nodes as an advanced
/// setting. The warning color stays on the icon, so the note does not
/// become a colored card.
class _AdvancedWarning extends StatelessWidget {
  final String message;
  const _AdvancedWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SettingsPageScaffold.gutter + 16,
        16,
        SettingsPageScaffold.gutter + 16,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: context.appColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
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

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: width),
    );
    final codeStyle = context.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      // iOS has no font named "monospace", so it takes the fallback.
      fontFamilyFallback: const ['Menlo', 'Courier'],
      color: colors.textPrimary,
    );

    return Column(
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
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: colors.primaryColor,
          style: codeStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: codeStyle?.copyWith(color: colors.textTertiary),
            filled: true,
            fillColor: GlassStyle.of(context).lensFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            errorMaxLines: 2,
            errorStyle: context.textTheme.bodySmall?.copyWith(
              color: colors.negativeColor,
            ),
            border: frame(hairline, 1),
            enabledBorder: frame(hairline, 1),
            focusedBorder: frame(colors.primaryColor, 1.5),
            errorBorder: frame(colors.negativeColor, 1),
            focusedErrorBorder: frame(colors.negativeColor, 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8),
          child: Text(
            helper,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// The fallback switch as a row of its glass panel.
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
    final colors = context.colors;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            height: 1.35,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.negativeColor;
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
              style: context.textTheme.bodyMedium?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
