import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import '../glass_info_sheet.dart';
import 'send_flow_parts.dart';

/// One-time notice shown on the first access to the Send screen: L-BTC
/// pays the network mining fees.
///
/// A floating glass sheet. The user reads it before going on: a tap
/// outside or a drag does not close it, and the confirm button unlocks
/// after a short countdown. The SWAP link closes it with true.
class LbtcDisclaimerSheet extends StatefulWidget {
  const LbtcDisclaimerSheet({super.key});

  @override
  State<LbtcDisclaimerSheet> createState() => _LbtcDisclaimerSheetState();

  static Future<bool?> show(BuildContext context) {
    return showFloatingGlassSheet<bool>(
      context,
      dismissible: false,
      builder: (context) => const LbtcDisclaimerSheet(),
    );
  }
}

class _LbtcDisclaimerSheetState extends State<LbtcDisclaimerSheet> {
  int _secondsRemaining = 7;
  Timer? _timer;
  TapGestureRecognizer? _swapRecognizer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Navigate to swap and close dialog when SWAP link is tapped
    _swapRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).pop(true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swapRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ready = _secondsRemaining == 0;

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: PixIconWell(icon: PixIcons.info, size: 56),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      t.wallet_send_lbtc_disclaimer_title,
                      textAlign: TextAlign.center,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.wallet_send_lbtc_disclaimer_body,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                    PixIcons.fast,
                    t.wallet_send_lbtc_network_fees_title,
                    t.wallet_send_lbtc_network_fees_desc,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoItem(
                    PixIcons.exchange,
                    t.wallet_send_lbtc_obtain_title,
                    t.wallet_send_lbtc_obtain_desc_disclaimer,
                    highlightText: 'SWAP',
                    highlightRecognizer: _swapRecognizer,
                  ),
                  const SizedBox(height: 18),
                  SendNotice(
                    icon: PixIcons.info,
                    message: t.wallet_send_lbtc_disclaimer_tip,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              text: ready
                  ? t.common_understood
                  : t.wallet_send_lbtc_disclaimer_understood_countdown(
                      _secondsRemaining,
                    ),
              isEnabled: ready,
              onPressed: ready ? () => Navigator.of(context).pop(false) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    PixIconData icon,
    String title,
    String description, {
    String? highlightText,
    TapGestureRecognizer? highlightRecognizer,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final descriptionStyle = textTheme.bodySmall?.copyWith(
      color: context.colors.textSecondary,
      height: 1.4,
    );

    Widget descriptionWidget;
    if (highlightText != null && description.contains(highlightText)) {
      final parts = description.split(highlightText);
      descriptionWidget = RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: descriptionStyle,
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: highlightText,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
              recognizer: highlightRecognizer,
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    } else {
      descriptionWidget = Text(description, style: descriptionStyle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixIconWell(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              descriptionWidget,
            ],
          ),
        ),
      ],
    );
  }
}
