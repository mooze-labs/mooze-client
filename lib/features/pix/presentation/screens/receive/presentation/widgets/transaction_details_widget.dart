import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import '../../providers.dart';

class AssetAmountDisplay extends ConsumerWidget {
  const AssetAmountDisplay({super.key});

  Widget _returnError(BuildContext context) {
    return Text(
      "N/A",
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final depositAmount = ref.read(depositAmountProvider);
    final assetQuote = ref.watch(assetQuoteProvider(selectedAsset));
    final discountedDepositAmount = ref.watch(
      discountedFeesDepositProvider(depositAmount),
    );

    return assetQuote.when(
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(error.toString());
        }
        return _returnError(context);
      },
      data:
          (data) => data.fold(
            (error) {
              if (kDebugMode) {
                debugPrint(error.toString());
              }
              return _returnError(context);
            },
            (val) => val.fold(
              () => _returnError(context),
              (quote) => discountedDepositAmount.when(
                data: (depositAmount) {
                  final amount = depositAmount / quote;
                  final decimalPlaces = selectedAsset == Asset.depix ? 2 : 8;
                  return Text(
                    '=${amount.toStringAsFixed(decimalPlaces)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  );
                },
                error: (error, stackTrace) {
                  if (kDebugMode) {
                    debugPrint(error.toString());
                  }
                  return _returnError(context);
                },
                loading:
                    () => Shimmer.fromColors(
                      baseColor: Colors.grey[800]!,
                      highlightColor: Colors.grey[600]!,
                      child: Container(
                        width: 30,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
              ),
            ),
          ),
      loading:
          () => Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
    );
  }
}

class FeeDisplay extends ConsumerWidget {
  const FeeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositAmount = ref.read(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);

    if (!validation.isValid) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            InfoRow(label: "Taxa Mooze", value: "-"),
            SizedBox(height: 6),
            InfoRow(label: "Percentual", value: "-"),
            SizedBox(height: 6),
            InfoRow(label: "Taxa da processadora", value: "-"),
            SizedBox(height: 6),
            InfoRow(label: "Valor final", value: "-"),
          ],
        ),
      );
    }

    final feeRate = ref.watch(feeRateProvider(depositAmount));
    final feeAmount = ref.watch(feeAmountProvider(depositAmount));
    final discountedDeposit = ref.watch(
      discountedFeesDepositProvider(depositAmount),
    );
    final hasReferral = ref.watch(hasReferralProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          feeAmount.when(
            data: (data) {
              return (depositAmount < 55)
                  ? InfoRow(
                    label: "Taxa Mooze",
                    value: "R\$ 1,00 + taxas de rede",
                  )
                  : InfoRow(
                    label: "Taxa Mooze",
                    value: "R\$ ${data.toStringAsFixed(2)}",
                  );
            },
            error:
                (error, stackTrace) =>
                    InfoRow(label: "Taxa Mooze", value: "Erro"),
            loading: () => ShimmerInfoRow(label: "Taxa Mooze"),
          ),
          SizedBox(height: 6),
          feeRate.when(
            data: (data) {
              return (depositAmount < 55)
                  ? InfoRow(label: "Percentual", value: "R\$ 1,00 (FIXO)")
                  : InfoRow(
                    label: "Percentual",
                    value: "${data.toStringAsFixed(2)}%",
                  );
            },
            error:
                (error, stackTrace) =>
                    InfoRow(label: "Percentual", value: "Erro"),
            loading: () => ShimmerInfoRow(label: "Percentual"),
          ),
          SizedBox(height: 6),
          hasReferral.when(
            data: (hasRef) {
              if (hasRef && depositAmount >= 55) {
                return Column(
                  children: [
                    InfoRow(
                      label: "Desconto referral",
                      value: "-15%",
                      valueColor: Colors.green,
                    ),
                    SizedBox(height: 6),
                  ],
                );
              }
              return SizedBox.shrink();
            },
            error: (_, __) => SizedBox.shrink(),
            loading: () => SizedBox.shrink(),
          ),
          InfoRow(label: "Taxa da processadora", value: "R\$ 1.00"),
          SizedBox(height: 6),
          discountedDeposit.when(
            data:
                (data) => InfoRow(
                  label: "Valor final",
                  value: data.toStringAsFixed(2),
                ),
            error:
                (error, stackTrace) =>
                    InfoRow(label: "Valor final", value: "Erro"),
            loading: () => ShimmerInfoRow(label: "Valor final"),
          ),
          SizedBox(height: 6),
        ],
      ),
    );
  }
}

class TransactionDisplayWidget extends ConsumerWidget {
  const TransactionDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);

    return Container(
      decoration: _buildContainerDecoration(),
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildHeader(context),
            _buildAssetInfo(selectedAsset, ref),
            Divider(color: Colors.white24, thickness: 1),
            FeeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Text(
        'Dados da transação',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssetInfo(Asset asset, WidgetRef ref) {
    final validation = ref.watch(depositValidationProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAssetLabel(asset),
          validation.isValid
              ? AssetAmountDisplay()
              : Text(
                "-",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildAssetLabel(Asset asset) {
    return Row(
      children: [
        SvgPicture.asset(asset.iconPath, width: 24, height: 24),
        SizedBox(width: 10),
        Text(
          asset.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: AppColors.pinBackground,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
