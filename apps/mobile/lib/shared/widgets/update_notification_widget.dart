import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_banner.dart';
import 'package:mooze_mobile/shared/providers/update_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// A new version of the app, as a glass banner under the home header.
///
/// The banner names the new version. A tap opens the [UpdateSheet], with
/// the current and the new version and the button to the store. The close
/// button puts the banner away for this session. The banner fades in and
/// out, and the content below it moves smoothly.
class UpdateNotificationWidget extends ConsumerWidget {
  const UpdateNotificationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final shouldShow = ref.watch(shouldShowUpdateNotificationProvider);
    final state = ref.watch(updateNotifierProvider);
    final newVersion = state.newVersion ?? '';
    final localVersion = state.localVersion ?? '';
    return SizeFadeSwitcher(
      duration: Motion.durationBase,
      child: shouldShow
          ? Padding(
              key: const ValueKey('update-banner'),
              padding: const EdgeInsets.only(bottom: 8),
              child: StatusBanner(
                icon: PixIcons.refresh,
                color: context.colors.primaryColor,
                title: t.update_available_short,
                message:
                    '${t.update_version_label(newVersion)} · '
                    '${t.update_available_body}',
                onTap: () => showUpdateSheet(
                  context,
                  newVersion: newVersion,
                  localVersion: localVersion,
                ),
                onDismiss: () =>
                    ref.read(updateNotifierProvider.notifier).dismissUpdate(),
                dismissTooltip: t.common_close,
              ),
            )
          : const SizedBox(key: ValueKey('no-update'), width: double.infinity),
    );
  }
}

/// Shows the [UpdateSheet] of [newVersion] in a floating glass sheet.
Future<void> showUpdateSheet(
  BuildContext context, {
  required String newVersion,
  required String localVersion,
}) {
  return showFloatingGlassSheet<void>(
    context,
    builder: (_) => UpdateSheet(
      newVersion: newVersion,
      localVersion: localVersion,
      onUpdate: _openUpdateStore,
    ),
  );
}

/// A floating glass sheet about a new version of the app.
///
/// The header names the new version. Below it, why to update, and the
/// current and the new version side by side. The button to the store
/// closes the sheet first and then runs [onUpdate]. "Later" only closes
/// the sheet: the banner stays on the home.
class UpdateSheet extends StatelessWidget {
  const UpdateSheet({
    super.key,
    required this.newVersion,
    required this.localVersion,
    required this.onUpdate,
  });

  final String newVersion;
  final String localVersion;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSheetHeader(
            title: t.update_dialog_title,
            subtitle: t.update_version_label(newVersion),
            leading: GlassSheetBadge(
              icon: PixIcons.refresh,
              color: context.colors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${t.update_dialog_body} ${t.update_dialog_recommend}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _VersionStep(current: localVersion, next: newVersion),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PrimaryButton(
              text: t.update_available_button,
              onPressed: () {
                Navigator.of(context).pop();
                onUpdate();
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                // The way back stays neutral. The brand color is for the
                // main action.
                foregroundColor: context.colors.textPrimary,
                minimumSize: const Size(64, 48),
              ),
              child: Text(t.update_later),
            ),
          ),
        ],
      ),
    );
  }
}

/// The current and the new version side by side in a glass lens, with an
/// arrow between them. The new version carries the emphasis.
class _VersionStep extends StatelessWidget {
  const _VersionStep({required this.current, required this.next});

  final String current;
  final String next;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: GlassStyle.of(context).lensFill,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Version(
              label: _withoutColon(t.update_current_version),
              version: current,
              emphasized: false,
            ),
          ),
          PixIcon(
            PixIcons.arrowRight,
            size: 18,
            color: context.colors.textTertiary,
          ),
          Expanded(
            child: _Version(
              label: _withoutColon(t.update_new_version),
              version: next,
              emphasized: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// One version: its label, and the number below it.
class _Version extends StatelessWidget {
  const _Version({
    required this.label,
    required this.version,
    required this.emphasized,
  });

  final String label;
  final String version;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            version.isEmpty ? '—' : version,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: emphasized
                  ? context.colors.textPrimary
                  : context.colors.textSecondary,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Some labels end with a ":" in the translations, such as "Versão atual:".
/// The label sits above its value here, so it goes without.
String _withoutColon(String label) =>
    label.endsWith(':') ? label.substring(0, label.length - 1) : label;

void _openUpdateStore() {
  if (Platform.isAndroid) {
    launchUrlString("https://mooze.app", mode: LaunchMode.externalApplication);
  } else if (Platform.isIOS) {
    launchUrlString(
      "https://testflight.apple.com/join/BmxNjKb1",
      mode: LaunchMode.externalApplication,
    );
  }
}
