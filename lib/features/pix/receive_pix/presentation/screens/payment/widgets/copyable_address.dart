import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class CopyableAddress extends ConsumerStatefulWidget {
  final String pixKey;

  const CopyableAddress({super.key, required this.pixKey});

  @override
  ConsumerState<CopyableAddress> createState() => _CopyableAddressState();
}

class _CopyableAddressState extends ConsumerState<CopyableAddress> {
  bool _isCopied = false;

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _isCopied = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isCopied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyToClipboard(widget.pixKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isCopied
                  ? context.colors.primaryColor.withValues(alpha: 0.08)
                  : context.colors.pinBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isCopied
                    ? context.colors.primaryColor.withValues(alpha: 0.5)
                    : context.colors.primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.qr_code_rounded,
              color:
                  _isCopied
                      ? context.colors.primaryColor
                      : context.colors.primaryColor.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chave PIX',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.pixKey,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _isCopied
                          ? context.colors.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(
              _isCopied ? Icons.check_rounded : Icons.copy_rounded,
              color:
                  _isCopied
                      ? context.colors.primaryColor
                      : context.colors.primaryColor.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
