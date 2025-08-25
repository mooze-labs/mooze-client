import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserIdContainerWidget extends StatefulWidget {
  final String userId;
  final bool hasError;
  final ColorScheme colorScheme;

  const UserIdContainerWidget({
    super.key,
    required this.userId,
    required this.hasError,
    required this.colorScheme,
  });

  @override
  State<UserIdContainerWidget> createState() => _UserIdContainerWidgetState();
}

class _UserIdContainerWidgetState extends State<UserIdContainerWidget> {
  bool _codeCopied = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            widget.hasError
                ? widget.colorScheme.errorContainer.withValues(alpha: 0.1)
                : _codeCopied
                ? widget.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              widget.hasError
                  ? widget.colorScheme.error.withValues(alpha: 0.3)
                  : _codeCopied
                  ? widget.colorScheme.primary.withValues(alpha: 0.3)
                  : widget.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.hasError
                      ? Icons.error_rounded
                      : Icons.fingerprint_rounded,
                  color:
                      widget.hasError
                          ? widget.colorScheme.error
                          : widget.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.hasError
                        ? 'Erro ao carregar código'
                        : 'Código único',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.hasError
                              ? widget.colorScheme.error
                              : widget.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!widget.hasError)
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.userId),
                      );
                      setState(() {
                        _codeCopied = true;
                      });
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() {
                          _codeCopied = false;
                        });
                      }
                    },
                    icon: Icon(
                      _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                      color:
                          _codeCopied
                              ? widget.colorScheme.primary
                              : widget.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.userId,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    widget.hasError
                        ? widget.colorScheme.error
                        : widget.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
