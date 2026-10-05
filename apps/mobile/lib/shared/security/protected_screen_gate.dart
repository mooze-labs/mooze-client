import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'screen_security_controller.dart';

class ProtectedScreenGate extends StatefulWidget {
  const ProtectedScreenGate({super.key, required this.child, this.logo});

  final Widget child;

  final Widget? logo;

  @override
  State<ProtectedScreenGate> createState() => _ProtectedScreenGateState();
}

class _ProtectedScreenGateState extends State<ProtectedScreenGate> {
  bool _revealed = false;

  void _reveal() {
    ScreenSecurityController.instance.enable();
    setState(() => _revealed = true);
  }

  @override
  void dispose() {
    if (_revealed) ScreenSecurityController.instance.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) return widget.child;

    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final warning = context.appColors.warning;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.logo ??
                    SvgPicture.asset(
                      'assets/logos/logo_primary.svg',
                      width: 140,
                      colorFilter: ColorFilter.mode(
                        context.colors.logoColor,
                        BlendMode.srcIn,
                      ),
                    ),
                const SizedBox(height: 40),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  t.screenshot_blocked_title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.screenshot_blocked_message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.screenshot_blocked_warning,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: warning,
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: t.screenshot_blocked_acknowledge,
                    onPressed: _reveal,
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
