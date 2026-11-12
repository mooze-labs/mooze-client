import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const minimumAmountForVariableFee = 55 * 100;

/// What the deposit delivers and which fees apply, in the panel of the
/// transaction details.
///
/// Each row is a label on the left and a value on the right, split by
/// hairlines. A value that waits for a quote shows a skeleton. [rows] follow
/// the fees in the same list, such as the code to copy, and [links] close
/// the panel, such as the share.
class PaymentDetailsDisplay extends ConsumerWidget {
  final PixDeposit deposit;

  /// Rows after the fees, in the same list.
  final List<Widget> rows;

  /// Actions at the end of the panel.
  final List<Widget> links;

  const PaymentDetailsDisplay({
    super.key,
    required this.deposit,
    this.rows = const [],
    this.links = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final depositAmountInReais = deposit.amountInCents.toDouble() / 100;
    final assetQuote = ref.read(assetQuoteProvider(deposit.asset).future);
    final feeRate = ref.read(feeRateProvider(depositAmountInReais).future);
    final discountedAmount = ref.read(
      discountedFeesDepositProvider(depositAmountInReais).future,
    );
    final locale = Localizations.localeOf(context).toString();
    final assetQuantity = discountedAmount.then(
      (amount) => _getAssetQuantity(assetQuote, amount, deposit.asset, locale),
    );
    final isFixedFee = deposit.amountInCents < minimumAmountForVariableFee;

    return TxMetaPanel(
      cells: const [],
      links: links,
      ids: [
        _DetailRow(
          label: t.pix_you_will_receive,
          highlight: true,
          value: FutureBuilder<String>(
            future: assetQuantity,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _ValueText(snapshot.data!, highlight: true);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ValueSkeleton(width: 96);
              }
              return const _ValueText('N/A', muted: true);
            },
          ),
        ),
        if (isFixedFee)
          _DetailRow(
            label: t.pix_fee_fixed_label,
            value: const _ValueText('R\$ 1,00'),
          )
        else
          _DetailRow(
            label: t.pix_fee_mooze,
            value: FutureBuilder<double>(
              future: feeRate,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final feeAmount =
                      depositAmountInReais * (snapshot.data! / 100);
                  return _ValueText(
                    'R\$ ${feeAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ValueSkeleton(width: 56);
                }
                return const _ValueText('N/A', muted: true);
              },
            ),
          ),
        _DetailRow(
          label: t.pix_fee_processor,
          value: const _ValueText('R\$ 1,00'),
        ),
        ...rows,
      ],
    );
  }
}

/// A label and its value on one line. Both wrap when they do not fit.
///
/// The value keeps its own width, up to 60% of the row. The label takes the
/// rest, so a short value does not make a long label wrap.
class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: MergeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: highlight
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.6,
                ),
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The value of a row, with tabular figures.
class _ValueText extends StatelessWidget {
  final String text;
  final bool highlight;
  final bool muted;

  const _ValueText(this.text, {this.highlight = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final style = highlight
        ? context.textTheme.titleMedium
        : context.textTheme.bodyMedium;
    return Text(
      text,
      textAlign: TextAlign.end,
      style: style?.copyWith(
        color: muted
            ? context.colors.textSecondary
            : context.colors.textPrimary,
        fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Placeholder of a value that waits for a quote.
class _ValueSkeleton extends StatelessWidget {
  final double width;

  const _ValueSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SkeletonBox(width: width, height: 14, radius: 6),
    );
  }
}

Future<String> _getAssetQuantity(
  Future<Either<String, Option<double>>> futureEitherOptionQuote,
  double amountAfterFees,
  Asset asset,
  String locale,
) {
  return futureEitherOptionQuote.then(
    (x) => x.fold(
      (err) => "N/A",
      (optionQuote) => optionQuote.fold(() => "N/A", (quote) {
        final quantity = amountAfterFees / quote;
        return asset.formatQuoteAmount(quantity, locale: locale);
      }),
    ),
  );
}
