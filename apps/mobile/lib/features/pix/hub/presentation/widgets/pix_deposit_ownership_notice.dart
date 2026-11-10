import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Mandatory notice about who may pay a Pix deposit.
///
/// The user has to read it before the first deposit, and it stays reachable
/// afterwards. Mooze cannot check who owns the paying account, so the notice is
/// the only control over third-party payments.
class PixDepositOwnershipNotice extends StatelessWidget {
  const PixDepositOwnershipNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PixWarningPanel(
      title: t.pix_hub_deposit_notice_title,
      body: t.pix_hub_deposit_notice_body,
    );
  }
}

/// A rule, or a step the user still has to take, in a warning tint.
///
/// The block is a warning tint, not glass: the color tells the user that the
/// text needs attention. The icon and the title carry the same message, so
/// the meaning never depends on color alone. An optional action sits below
/// the text.
class PixWarningPanel extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PixWarningPanel({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = actionLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        // The light page is bright, so a weaker tint gives the same weight.
        color: warning.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: AppSurfaces.panelRadius,
        border: Border.all(color: warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen readers read the title and the body as one notice. The
          // action stays a button of its own.
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PixIconWell(
                  icon: PixIcons.warning,
                  tone: PixTone.warning,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The title aligns with the center of the icon well.
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          title,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (label != null)
            Padding(
              // The action lines up with the text, past the icon well.
              padding: const EdgeInsets.only(left: 36),
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  minimumSize: const Size(64, 48),
                  textStyle: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(label),
              ),
            ),
        ],
      ),
    );
  }
}
