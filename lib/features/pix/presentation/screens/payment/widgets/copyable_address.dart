import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isCopied
                    ? AppColors.primaryColor.withValues(alpha: 0.5)
                    : AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.qr_code_rounded,
              color:
                  _isCopied
                      ? AppColors.primaryColor
                      : AppColors.primaryColor.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chave PIX',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.pixKey,
                    style: TextStyle(
                      color: _isCopied ? AppColors.primaryColor : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _isCopied ? Icons.check_rounded : Icons.copy_rounded,
              color:
                  _isCopied
                      ? AppColors.primaryColor
                      : AppColors.primaryColor.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
