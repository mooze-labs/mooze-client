import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyButton extends StatefulWidget {
  final String textToCopy;
  final String? displayText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final int? maxLines;
  final TextOverflow? overflow;
  final VoidCallback? onCopied;
  final Widget? prefix;
  final Widget? suffix;
  final bool showCopyIcon;
  final double? iconSize;
  final Duration animationDuration;
  final Duration resetDuration;

  const CopyButton({
    super.key,
    required this.textToCopy,
    this.displayText,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.maxLines = 3,
    this.overflow = TextOverflow.ellipsis,
    this.onCopied,
    this.prefix,
    this.suffix,
    this.showCopyIcon = true,
    this.iconSize = 14,
    this.animationDuration = const Duration(milliseconds: 200),
    this.resetDuration = const Duration(seconds: 2),
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyToClipboard(context),
      child: Container(
        width: double.infinity,
        padding: widget.padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            if (widget.prefix != null) ...[
              widget.prefix!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.displayText ?? widget.textToCopy,
                style:
                    widget.textStyle ??
                    const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                overflow: widget.overflow,
                maxLines: widget.maxLines,
              ),
            ),
            if (widget.suffix != null) ...[
              const SizedBox(width: 8),
              widget.suffix!,
            ],
            if (widget.showCopyIcon) ...[
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: widget.animationDuration,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      _isCopied
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                  size: widget.iconSize,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));

    setState(() {
      _isCopied = true;
    });

    widget.onCopied?.call();

    Future.delayed(widget.resetDuration, () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }
}
