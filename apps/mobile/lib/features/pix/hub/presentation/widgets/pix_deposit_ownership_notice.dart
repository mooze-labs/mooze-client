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
///
/// The block is a warning tint, not glass: the color tells the user that the
/// text is a rule. The icon and the title carry the same message, so the
/// meaning never depends on color alone.
class PixDepositOwnershipNotice extends StatelessWidget {
  const PixDepositOwnershipNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final warning = context.appColors.warning;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Screen readers read the title and the body as one notice.
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          // The light page is bright, so a weaker tint gives the same weight.
          color: warning.withValues(alpha: isDark ? 0.10 : 0.08),
          borderRadius: AppSurfaces.panelRadius,
          border: Border.all(color: warning.withValues(alpha: 0.35)),
        ),
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
                      t.pix_hub_deposit_notice_title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.pix_hub_deposit_notice_body,
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
    );
  }
}
