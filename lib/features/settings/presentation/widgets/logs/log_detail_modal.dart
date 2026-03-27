import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Modal bottom sheet displaying detailed log information
class LogDetailModal extends StatelessWidget {
  final LogEntry log;

  const LogDetailModal({super.key, required this.log});

  static void show(BuildContext context, LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildContent(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildCopyButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Log Details',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final color = _getColorForLevel(context, log.level);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(context, 'Level', log.level.displayName, color: color),
        _buildDetailRow(context, 'Tag', log.tag),
        _buildDetailRow(context, 'Timestamp', log.timestamp.toIso8601String()),
        Divider(color: dividerColor),
        Text(
          'Message:',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          log.message,
          style: textTheme.titleSmall,
        ),
        if (log.error != null) ...[
          const SizedBox(height: 16),
          Divider(color: dividerColor),
          Text(
            'Error:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            log.error.toString(),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontFamily: 'monospace',
            ),
          ),
        ],
        if (log.stackTrace != null) ...[
          const SizedBox(height: 16),
          Divider(color: dividerColor),
          Text(
            'Stack Trace:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              log.stackTrace.toString(),
              style: textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.titleSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: log.toFormattedString()));
          Navigator.pop(context);
          AppSnackBar.success(context, 'Log copied!');
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy Log'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Color _getColorForLevel(BuildContext context, LogLevel level) {
    final colorScheme = context.colorScheme;

    switch (level) {
      case LogLevel.debug:
        return context.colors.textTertiary;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return context.appColors.warning;
      case LogLevel.error:
        return colorScheme.error;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
