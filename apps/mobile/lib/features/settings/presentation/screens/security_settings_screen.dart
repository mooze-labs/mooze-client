import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/settings/domain/entities/session_lock_timeout.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/security_settings_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Dedicated Security settings screen for the session lock, the privacy shield,
/// and the "Lock After" timeout. The timeout selector is hidden when the
/// session lock is disabled.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final sessionLockEnabled = ref.watch(sessionLockEnabledProvider);
    final privacyShieldEnabled = ref.watch(privacyShieldEnabledProvider);
    final timeout = ref.watch(sessionLockTimeoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings_security),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, t.settings_section_security),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: t.security_session_lock_title,
                        subtitle: t.security_session_lock_subtitle,
                        toggle: Toggle(
                          value: sessionLockEnabled,
                          onChange:
                              (v) => ref
                                  .read(sessionLockEnabledProvider.notifier)
                                  .setEnabled(v),
                        ),
                      ),
                      const LabelDivider(),
                      if (!sessionLockEnabled)
                        _SwitchRow(
                          title: t.security_privacy_shield_title,
                          subtitle: t.security_privacy_shield_subtitle,
                          toggle: Toggle(
                            value: privacyShieldEnabled,
                            onChange:
                                (v) => ref
                                    .read(privacyShieldEnabledProvider.notifier)
                                    .setEnabled(v),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (sessionLockEnabled) ...[
                _sectionHeader(context, t.security_lock_after),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: colorScheme.surfaceContainerLow,
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < SessionLockTimeout.values.length;
                          i++
                        ) ...[
                          _TimeoutRow(
                            label: _timeoutLabel(
                              t,
                              SessionLockTimeout.values[i],
                            ),
                            selected: timeout == SessionLockTimeout.values[i],
                            onTap:
                                () => ref
                                    .read(sessionLockTimeoutProvider.notifier)
                                    .setTimeout(SessionLockTimeout.values[i]),
                          ),
                          if (i < SessionLockTimeout.values.length - 1)
                            const LabelDivider(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 15, left: 20, bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );

  String _timeoutLabel(AppLocalizations t, SessionLockTimeout timeout) =>
      switch (timeout) {
        SessionLockTimeout.immediate => t.security_timeout_immediate,
        SessionLockTimeout.seconds15 => t.security_timeout_15s,
        SessionLockTimeout.seconds30 => t.security_timeout_30s,
        SessionLockTimeout.minute1 => t.security_timeout_1m,
        SessionLockTimeout.minutes5 => t.security_timeout_5m,
      };
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Toggle toggle;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: toggle.value,
      onChanged: toggle.onChange,
    );
  }
}

class _TimeoutRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeoutRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color:
                    selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
