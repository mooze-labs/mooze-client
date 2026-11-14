import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The bare address of a receive request, which a tap anywhere on the
/// field copies.
///
/// The field is a glass lens with a copy icon at its end, and no word: the
/// icon says it. After a copy the icon turns into a check for
/// [copiedDuration], with a selection haptic, and a screen reader announces
/// "Copied!", so the feedback never depends on the icon alone.
class ReceiveAddressField extends StatefulWidget {
  const ReceiveAddressField({
    super.key,
    required this.label,
    required this.address,
  });

  final String label;
  final String address;

  /// Time the check shows after a copy.
  static const copiedDuration = Duration(seconds: 2);

  @override
  State<ReceiveAddressField> createState() => _ReceiveAddressFieldState();
}

class _ReceiveAddressFieldState extends State<ReceiveAddressField> {
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
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (!mounted) return;
    SemanticsService.sendAnnouncement(view, t.receive_qr_copied, direction);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(ReceiveAddressField.copiedDuration, () {
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
      value: widget.address,
      hint: _copied ? t.receive_qr_copied : t.receive_qr_copy_address,
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                        widget.address,
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
                  child: PixIcon(
                    _copied ? PixIcons.check : PixIcons.copy,
                    key: ValueKey(_copied),
                    size: 20,
                    color: _copied ? primary : context.colors.textSecondary,
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
