import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';

/// The support code of the user, in a glass panel, with a copy button.
///
/// The muted label sits above the code. After a copy, the copy icon turns
/// into a check in the positive color for a moment.
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

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.userId));
    setState(() {
      _codeCopied = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _codeCopied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasError = widget.hasError;
    final negative = context.colors.negativeColor;

    return GlassPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Icon(
              hasError ? Icons.error_rounded : Icons.fingerprint_rounded,
              color: hasError ? negative : context.colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError
                        ? t.support_user_code_load_error_inline
                        : t.support_user_code_unique,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: hasError ? negative : context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    truncateHashId(widget.userId, length: 10),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: hasError ? negative : context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (!hasError)
              IconButton(
                onPressed: _copy,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.durationFast),
                  switchInCurve: Motion.curveEnter,
                  switchOutCurve: Motion.curveExit,
                  child: Icon(
                    _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(_codeCopied),
                    color: _codeCopied
                        ? context.colors.positiveColor
                        : context.colors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
