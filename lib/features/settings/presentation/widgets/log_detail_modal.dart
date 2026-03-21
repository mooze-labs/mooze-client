import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

/// Modal bottom sheet displaying detailed log information
class LogDetailModal extends StatelessWidget {
  final LogEntry log;

  const LogDetailModal({super.key, required this.log});

  static void show(BuildContext context, LogEntry log) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHighest,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Log Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();
    final color = _getColorForLevel(context, log.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(context, 'Level', log.level.displayName, color: color),
        _buildDetailRow(context, 'Tag', log.tag),
        _buildDetailRow(context, 'Timestamp', log.timestamp.toIso8601String()),
        Divider(color: colorScheme.outlineVariant),
        Text(
          'Message:',
          style: TextStyle(
            color: colorScheme.outlineVariant,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          log.message,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
        ),
        if (log.error != null) ...[
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant),
          Text(
            'Error:',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            log.error.toString(),
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
        if (log.stackTrace != null) ...[
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant),
          Text(
            'Stack Trace:',
            style: TextStyle(
              color: extraColors?.warning ?? Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              log.stackTrace.toString(),
              style: TextStyle(
                color: colorScheme.outlineVariant,
                fontSize: 11,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: colorScheme.outlineVariant,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Color _getColorForLevel(BuildContext context, LogLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();

    switch (level) {
      case LogLevel.debug:
        return colorScheme.outlineVariant;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return extraColors?.warning ?? Colors.orange;
      case LogLevel.error:
        return colorScheme.error;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
