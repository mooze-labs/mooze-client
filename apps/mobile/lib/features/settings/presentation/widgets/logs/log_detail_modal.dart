import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Bottom sheet showing the full detail of a single log entry, on a
/// floating glass sheet.
class LogDetailModal extends StatelessWidget {
  final LogEntry log;

  const LogDetailModal({super.key, required this.log});

  static void show(BuildContext context, LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LogDetailModal(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GlassSheet(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _GripHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                child: _buildHeader(context),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildContent(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _buildCopyButton(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.textTheme;
    final colors = context.colors;
    final color = log.level.color(context);

    return Row(
      children: [
        Icon(log.level.icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings_log_details,
                style: tt.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                log.tag,
                style: tt.bodySmall?.copyWith(color: colors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final tt = context.textTheme;
    final colors = context.colors;
    final color = log.level.color(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata rows, split by hairlines, directly on the sheet.
        _MetaRow(
          label: t.logs_detail_level,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                log.level.displayName,
                style: tt.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const PanelDivider(),
        _MetaRow(
          label: t.logs_detail_tag,
          child: Text(
            log.tag,
            style: tt.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const PanelDivider(),
        _MetaRow(
          label: t.logs_detail_timestamp,
          child: Text(
            log.timestamp.toIso8601String(),
            style: tt.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const PanelDivider(),
        const SizedBox(height: 20),
        _SectionTitle(text: t.logs_detail_message),
        const SizedBox(height: 8),
        SelectableText(
          log.message,
          style: tt.bodyMedium?.copyWith(
            color: colors.textPrimary,
            height: 1.4,
          ),
        ),
        if (log.error != null) ...[
          const SizedBox(height: 20),
          _SectionTitle(
            text: t.logs_detail_error_label,
            color: colors.errorColor,
          ),
          const SizedBox(height: 8),
          _CodeBlock(text: log.error.toString(), textColor: colors.errorColor),
        ],
        if (log.stackTrace != null) ...[
          const SizedBox(height: 20),
          _SectionTitle(text: t.logs_detail_stack_trace),
          const SizedBox(height: 8),
          _CodeBlock(
            text: log.stackTrace.toString(),
            textColor: colors.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: log.toFormattedString()));
          Navigator.pop(context);
          AppSnackBar.success(context, t.logs_detail_copied);
        },
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: Text(t.logs_detail_copy),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _GripHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppSurfaces.hairline(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.replaceAll(':', ''),
        style: context.textTheme.labelMedium?.copyWith(
          color: color ?? context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Monospace block for the error and the stack trace, on a glass panel.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          text,
          style: context.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
