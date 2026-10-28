import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_icons.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_method_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// First step of the send flow: how the payer informs the destination.
///
/// Every method ends in a Pix key, because the withdrawal API pays a key.
/// The recent recipients list is not offered: its data is fictional, and a
/// real payment must never use it.
///
/// The methods are a stack of equal glass cards. The screen has no main
/// action, because each card is the way forward.
class PixSendMethodScreen extends StatelessWidget {
  const PixSendMethodScreen({super.key});

  /// Space between two method cards.
  static const double _cardGap = 12;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PixScreenScaffold(
      title: t.pix_hub_send_title,
      subtitle: t.pix_hub_send_method_question,
      children: [
        PixMethodCard(
          icon: pixSendMethodIcon(PixSendMethod.key),
          title: t.pix_hub_method_key,
          description: t.pix_hub_action_pay_key_subtitle,
          onTap: () => context.push('/pix/send/key'),
        ),
        const SizedBox(height: _cardGap),
        PixMethodCard(
          icon: pixSendMethodIcon(PixSendMethod.qrCode),
          title: t.pix_hub_method_qr,
          description: t.pix_hub_send_method_qr_description,
          onTap: () => context.push('/pix/send/scan'),
        ),
        const SizedBox(height: _cardGap),
        PixMethodCard(
          icon: pixSendMethodIcon(PixSendMethod.copyPaste),
          title: t.pix_hub_method_copy_paste,
          description: t.pix_hub_send_method_code_description,
          onTap: () => context.push('/pix/send/code'),
        ),
      ],
    );
  }
}
