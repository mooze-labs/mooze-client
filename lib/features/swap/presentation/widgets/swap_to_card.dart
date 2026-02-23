import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

class SwapToCard extends ConsumerWidget {
  final core.Asset selectedAsset;
  final List<core.Asset> availableAssets;
  final String displayAmount;
  final BigInt? receiveAmount;
  final ValueChanged<core.Asset> onAssetChanged;

  const SwapToCard({
    super.key,
    required this.selectedAsset,
    required this.availableAssets,
    required this.displayAmount,
    required this.receiveAmount,
    required this.onAssetChanged,
  });

  Future<String> _getBalance(WidgetRef ref) async {
    final either = await ref.read(balanceProvider(selectedAsset).future);
    return either.match((l) => '0', (r) => selectedAsset.formatBalance(r));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.read(currencyControllerProvider.notifier);

    return Container(
      height: 115,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2D2E2A), AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Você recebe',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      FutureBuilder<String>(
                        future: _getBalance(ref),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? "...",
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Asset selector e display de quantidade
              Row(
                children: [
                  SvgPicture.asset(
                    selectedAsset.iconPath,
                    width: 25,
                    height: 25,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dropdown de assets
                        DropdownButton<core.Asset>(
                          value: selectedAsset,
                          underline: const SizedBox.shrink(),
                          icon: SvgPicture.asset(
                            'assets/icons/menu/arrow_down.svg',
                          ),
                          onChanged: (core.Asset? newAsset) {
                            if (newAsset != null) {
                              onAssetChanged(newAsset);
                            }
                          },
                          items:
                              availableAssets.map<DropdownMenuItem<core.Asset>>(
                                (core.Asset asset) {
                                  return DropdownMenuItem<core.Asset>(
                                    value: asset,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          asset.iconPath,
                                          width: 20,
                                          height: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          asset.ticker,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return availableAssets.map<Widget>((
                              core.Asset asset,
                            ) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    asset.ticker,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                              );
                            }).toList();
                          },
                        ),

                        // Display de quantidade
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            displayAmount,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Footer com nome do asset e valor em fiat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedAsset.name),
                  FutureBuilder<Either<String, double>>(
                    future: ref.read(fiatPriceProvider(selectedAsset).future),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (error) => const Text('0.00'),
                          (price) {
                            final amount = receiveAmount ?? BigInt.zero;
                            final usd = selectedAsset.toUsd(amount, price);
                            return Text(
                              '${currency.icon}${usd.toStringAsFixed(2)}',
                            );
                          },
                        );
                      }
                      return const Text('...');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
