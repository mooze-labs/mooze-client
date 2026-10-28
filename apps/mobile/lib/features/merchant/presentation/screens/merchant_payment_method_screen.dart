import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/merchant_payment_method.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_method_card.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_cpf_config.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Lets the merchant choose how the customer pays a confirmed amount.
///
/// The screen only returns the choice. The charge screen runs the flow, so
/// the QR Code flow keeps its code and the amount stays with the caller.
class MerchantPaymentMethodScreen extends ConsumerWidget {
  /// The confirmed amount, shown in the header.
  final int amountInCents;

  /// The asset the merchant receives, chosen on the charge screen.
  final Asset asset;

  const MerchantPaymentMethodScreen({
    super.key,
    required this.amountInCents,
    required this.asset,
  });

  /// Opens the screen. Returns the chosen method, or null when the merchant
  /// goes back.
  static Future<MerchantPaymentMethod?> choose(
    BuildContext context, {
    required int amountInCents,
    required Asset asset,
  }) {
    return Navigator.of(context).push<MerchantPaymentMethod>(
      MaterialPageRoute(
        builder: (_) => MerchantPaymentMethodScreen(
          amountInCents: amountInCents,
          asset: asset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final cpfRequired = ref.watch(pixCpfRequiredProvider);

    return MerchantFlowScaffold(
      title: t.merchant_payment_method_title,
      subtitle: t.merchant_payment_method_subtitle,
      amountInCents: amountInCents,
      amountCaption: MerchantHeaderChip(
        icon: Icons.account_balance_wallet_outlined,
        label: t.merchant_payment_receive_in(asset.ticker),
      ),
      children: [
        PixMethodCard(
          icon: PixIcons.qrCode,
          title: t.merchant_payment_method_qr_title,
          description: t.merchant_payment_method_qr_description,
          tags: [
            t.merchant_payment_method_tag_instant,
            if (cpfRequired) t.merchant_payment_method_tag_cpf,
          ],
          onTap: () =>
              Navigator.of(context).pop(MerchantPaymentMethod.pixQrCode),
        ),
        const SizedBox(height: 12),
        PixMethodCard(
          icon: PixIcons.link,
          title: t.merchant_payment_method_link_title,
          description: t.merchant_payment_method_link_description,
          tags: [
            t.merchant_payment_method_tag_remote,
            t.merchant_payment_method_tag_browser,
          ],
          onTap: () =>
              Navigator.of(context).pop(MerchantPaymentMethod.paymentLink),
        ),
      ],
    );
  }
}
