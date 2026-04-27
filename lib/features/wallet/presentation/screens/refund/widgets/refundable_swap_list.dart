import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/widgets/refund_item_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Widget that displays a list of refundable swaps
class RefundableSwapList extends StatelessWidget {
  final List<RefundableSwap> refundables;
  final Function(RefundableSwap) onSwapTap;

  const RefundableSwapList({
    super.key,
    required this.refundables,
    required this.onSwapTap,
  });

  @override
  Widget build(BuildContext context) {
    if (refundables.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).refund_none_found),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: refundables.length,
      itemBuilder: (context, index) {
        return RefundItemCard(
          refundableSwap: refundables[index],
          onTap: () => onSwapTap(refundables[index]),
        );
      },
    );
  }
}
