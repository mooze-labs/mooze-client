import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';

/// A Pix code or link the user can copy, with the copy analytics event.
///
/// The surface and the copy feedback come from [PixCopyField].
class CopyableAddress extends ConsumerWidget {
  final String pixKey;

  /// Label above the value. Defaults to the Pix key label.
  final String? label;

  /// Icon at the start of the field.
  final PixIconData icon;

  /// Sends the `pix_code_copied` event. Turn it off for values that are not
  /// Pix codes, because the analytics schema accepts known events only.
  final bool trackCopy;

  const CopyableAddress({
    super.key,
    required this.pixKey,
    this.label,
    this.icon = PixIcons.qrCode,
    this.trackCopy = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read now: ref is not usable after the widget is disposed, and the copy
    // ends after an await.
    final analytics = trackCopy ? ref.read(analyticsProvider) : null;
    return PixCopyField(
      label: label ?? AppLocalizations.of(context).human_verif_pix_key,
      value: pixKey,
      icon: icon,
      onCopied: analytics == null
          ? null
          : () => analytics.track(const AnalyticsEvent('pix_code_copied', {})),
    );
  }
}
