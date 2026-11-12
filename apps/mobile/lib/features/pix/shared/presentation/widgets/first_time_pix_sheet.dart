import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_notice_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Notice about the security review of Pix payments, shown on the first
/// access to Pix, in a floating glass sheet.
///
/// The user must accept it: a tap outside or a drag does not close it, and
/// the accept button unlocks after the reading time. The sheet returns true
/// when the user accepts.
class FirstTimePixSheet extends StatelessWidget {
  const FirstTimePixSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showFloatingGlassSheet<bool>(
      context,
      dismissible: false,
      builder: (context) => const FirstTimePixSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixNoticeSheet(
      // An attention notice: the warning tone, an alert shape, and the title
      // together carry the meaning.
      icon: PixIcons.shieldAlert,
      tone: PixTone.warning,
      title: t.pix_first_time_title,
      intro: t.pix_first_time_description,
      actionLabel: t.pix_first_time_accept_button,
      onAction: () => Navigator.of(context).pop(true),
      readingSeconds: PixNoticeSheet.noticeReadingSeconds,
      countingLabel: t.pix_first_time_accept_button_counting,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OutcomeRow(
            icon: PixIcons.clock,
            text: 'a) ${t.pix_first_time_item_completed}',
          ),
          const SizedBox(height: 12),
          _OutcomeRow(
            icon: PixIcons.restart,
            text: 'b) ${t.pix_first_time_item_refunded}',
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: AppSurfaces.hairline(context),
          ),
          const SizedBox(height: 16),
          PixNoticeNote(
            icon: PixIcons.shieldCheck,
            text: t.pix_first_time_security_note,
          ),
        ],
      ),
    );
  }
}

/// One possible outcome of the review: an icon well and a short text.
class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.icon, required this.text});

  final PixIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PixIconWell(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
