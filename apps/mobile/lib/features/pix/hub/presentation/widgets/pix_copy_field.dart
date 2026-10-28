import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A value the user can copy: a Pix code, a key, a link, or an ID.
///
/// The field is a glass lens. A tap anywhere on it copies the value, gives
/// a selection haptic, and switches the trailing "Copy" label to "Copied!"
/// with a check for two seconds. A screen reader announces the copy too, so
/// the feedback never depends on the color change.
class PixCopyField extends StatefulWidget {
  const PixCopyField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.maxLines = 2,
    this.onCopied,
  });

  final String label;
  final String value;

  /// Optional icon at the start of the field.
  final PixIconData? icon;

  /// Lines of [value] before it ends with an ellipsis.
  final int maxLines;

  /// Called after the value reaches the clipboard, for example to send an
  /// analytics event.
  final VoidCallback? onCopied;

  /// Time the field shows "Copied!".
  static const copiedDuration = Duration(seconds: 2);

  @override
  State<PixCopyField> createState() => _PixCopyFieldState();
}

class _PixCopyFieldState extends State<PixCopyField> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final t = AppLocalizations.of(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: widget.value));
    widget.onCopied?.call();
    if (!mounted) return;
    SemanticsService.sendAnnouncement(view, t.receive_qr_copied, direction);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(PixCopyField.copiedDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = context.colors.primaryColor;
    final duration = Motion.of(context, Motion.durationFast);
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      button: true,
      label: widget.label,
      value: widget.value,
      hint: _copied ? t.receive_qr_copied : t.pix_hub_copy,
      excludeSemantics: true,
      onTap: _copy,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _copy,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: duration,
            curve: Motion.curveMove,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: _copied
                  ? primary.withValues(alpha: 0.08)
                  : GlassStyle.of(context).lensFill,
              border: Border.all(
                color: _copied
                    ? primary.withValues(alpha: 0.5)
                    : AppSurfaces.hairline(context),
              ),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  PixIconWell(icon: widget.icon!, size: 36),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        maxLines: widget.maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: duration,
                  child: _CopyBadge(
                    key: ValueKey(_copied),
                    copied: _copied,
                    label: _copied ? t.receive_qr_copied : t.pix_hub_copy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The trailing "Copy" or "Copied!" label with its icon.
class _CopyBadge extends StatelessWidget {
  const _CopyBadge({super.key, required this.copied, required this.label});

  final bool copied;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = copied
        ? context.colors.primaryColor
        : context.colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixIcon(
          copied ? PixIcons.check : PixIcons.copy,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
