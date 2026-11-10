import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/domain/entities/export_method.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Dialog for choosing how to export logs (email or share)
class ExportLogsDialog extends StatelessWidget {
  const ExportLogsDialog({super.key});

  static Future<ExportMethod?> show(BuildContext context) {
    return showDialog<ExportMethod>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ExportLogsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final t = AppLocalizations.of(context);

    return GlassDialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 32,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              t.export_logs_title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.export_logs_description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(ExportMethod.email),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                child: Text(t.export_logs_by_email),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(ExportMethod.share),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: AppSurfaces.hairline(context)),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  t.export_logs_share,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
