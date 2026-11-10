import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/domain/entities/session_lock_timeout.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/security_settings_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_choice_row.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_switch_row.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';

/// Dedicated Security settings screen for the session lock, the privacy shield,
/// and the "Lock After" timeout. The timeout selector is hidden when the
/// session lock is disabled.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final sessionLockEnabled = ref.watch(sessionLockEnabledProvider);
    final privacyShieldEnabled = ref.watch(privacyShieldEnabledProvider);
    final timeout = ref.watch(sessionLockTimeoutProvider);

    // The rows have no icons, so the hairlines start at the row text.
    const divider = PanelDivider(indent: LabelSettings.horizontalPadding);

    return SettingsPageScaffold(
      title: t.settings_security,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsGlassSection(
              title: t.settings_section_security,
              child: Column(
                children: [
                  SettingsSwitchRow(
                    title: t.security_session_lock_title,
                    subtitle: t.security_session_lock_subtitle,
                    toggle: Toggle(
                      value: sessionLockEnabled,
                      onChange: (v) => ref
                          .read(sessionLockEnabledProvider.notifier)
                          .setEnabled(v),
                    ),
                  ),
                  if (!sessionLockEnabled) ...[
                    divider,
                    SettingsSwitchRow(
                      title: t.security_privacy_shield_title,
                      subtitle: t.security_privacy_shield_subtitle,
                      toggle: Toggle(
                        value: privacyShieldEnabled,
                        onChange: (v) => ref
                            .read(privacyShieldEnabledProvider.notifier)
                            .setEnabled(v),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (sessionLockEnabled)
              SettingsGlassSection(
                title: t.security_lock_after,
                child: Column(
                  children: [
                    for (
                      var i = 0;
                      i < SessionLockTimeout.values.length;
                      i++
                    ) ...[
                      if (i > 0) divider,
                      SettingsChoiceRow(
                        title: _timeoutLabel(t, SessionLockTimeout.values[i]),
                        selected: timeout == SessionLockTimeout.values[i],
                        onTap: () => ref
                            .read(sessionLockTimeoutProvider.notifier)
                            .setTimeout(SessionLockTimeout.values[i]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeoutLabel(AppLocalizations t, SessionLockTimeout timeout) =>
      switch (timeout) {
        SessionLockTimeout.immediate => t.security_timeout_immediate,
        SessionLockTimeout.seconds15 => t.security_timeout_15s,
        SessionLockTimeout.seconds30 => t.security_timeout_30s,
        SessionLockTimeout.minute1 => t.security_timeout_1m,
        SessionLockTimeout.minutes5 => t.security_timeout_5m,
      };
}
