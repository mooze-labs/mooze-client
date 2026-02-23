import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/payment/consts.dart'
    as AppColors;
import 'package:mooze_mobile/services/app_logger_service.dart';

/// Modal bottom sheet displaying detailed log information
class LogDetailModal extends StatelessWidget {
  final LogEntry log;

  const LogDetailModal({super.key, required this.log});

  static void show(BuildContext context, LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2B2D33),
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
                  child: _buildContent(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Log Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final color = _getColorForLevel(log.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Level', log.level.displayName, color: color),
        _buildDetailRow('Tag', log.tag),
        _buildDetailRow('Timestamp', log.timestamp.toIso8601String()),
        const Divider(color: Colors.grey),
        const Text(
          'Message:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          log.message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        if (log.error != null) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const Text(
            'Error:',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            log.error.toString(),
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
        if (log.stackTrace != null) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const Text(
            'Stack Trace:',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              log.stackTrace.toString(),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color ?? Colors.white, fontSize: 14),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log copied!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy Log'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
