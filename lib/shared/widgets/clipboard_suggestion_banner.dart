import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Compact banner offering to use a value found in the clipboard.
///
/// Purely presentational. The caller decides what counts as a usable value
/// and what happens on [onUse]. [preview] is shown truncated so the user can
/// recognise the value before accepting it.
class ClipboardSuggestionBanner extends StatelessWidget {
  final String title;
  final String preview;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  const ClipboardSuggestionBanner({
    super.key,
    required this.title,
    required this.preview,
    required this.onUse,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = context.colors.primaryColor;

    return Semantics(
      container: true,
      label: '$title: $preview',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.content_paste_rounded, size: 18, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onUse, child: Text(t.send_clipboard_use)),
            IconButton(
              onPressed: onDismiss,
              tooltip: t.common_close,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
