import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_level_color_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Bottom sheet showing the full detail of a single log entry, styled to
/// match the wallet's card-based design language.
class LogDetailModal extends StatelessWidget {
  final LogEntry log;

  const LogDetailModal({super.key, required this.log});

  static void show(BuildContext context, LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
        return Column(
          children: [
            const SizedBox(height: 10),
            _GripHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildContent(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: _buildCopyButton(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.textTheme;
    final extra = context.appColors;
    final color = log.level.color(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(log.level.icon, size: 21, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings_log_details,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                log.tag,
                style: tt.bodySmall?.copyWith(color: extra.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final extra = context.appColors;
    final color = log.level.color(context);
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata card.
        Container(
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _MetaRow(
                label: t.logs_detail_level,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.level.displayName,
                    style: tt.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              _MetaDivider(),
              _MetaRow(
                label: t.logs_detail_tag,
                child: Text(
                  log.tag,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              _MetaDivider(),
              _MetaRow(
                label: t.logs_detail_timestamp,
                child: Text(
                  log.timestamp.toIso8601String(),
                  style: tt.bodySmall?.copyWith(
                    color: extra.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle(text: t.logs_detail_message),
        const SizedBox(height: 8),
        SelectableText(
          log.message,
          style: tt.bodyMedium?.copyWith(height: 1.4),
        ),
        if (log.error != null) ...[
          const SizedBox(height: 20),
          _SectionTitle(text: t.logs_detail_error_label, color: cs.error),
          const SizedBox(height: 8),
          _CodeBlock(
            text: log.error.toString(),
            textColor: cs.error,
            backgroundColor: cs.error.withValues(alpha: 0.08),
            borderColor: cs.error.withValues(alpha: 0.18),
          ),
        ],
        if (log.stackTrace != null) ...[
          const SizedBox(height: 20),
          _SectionTitle(
            text: t.logs_detail_stack_trace,
            color: extra.warning,
          ),
          const SizedBox(height: 8),
          _CodeBlock(
            text: log.stackTrace.toString(),
            textColor: extra.textTertiary,
            backgroundColor: cs.onSurface.withValues(alpha: 0.04),
            borderColor: cs.onSurface.withValues(alpha: 0.06),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _GripHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorScheme.onSurface.withValues(alpha: 0.15),
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
    final tt = context.textTheme;
    final extra = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: extra.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
        ],
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: context.colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    final tt = context.textTheme;
    return Text(
      text.replaceAll(':', '').toUpperCase(),
      style: tt.bodySmall?.copyWith(
        color: color ?? extra.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String text;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: SelectableText(
        text,
        style: tt.bodySmall?.copyWith(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
