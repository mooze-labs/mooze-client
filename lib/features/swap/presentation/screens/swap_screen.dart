import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/confirm_swap_screen.dart';
import 'package:mooze_mobile/features/swap/presentation/providers/swap_providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/buttons/text_button.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  final TextEditingController _fromAmountController = TextEditingController();

  @override
  void dispose() {
    _fromAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapState = ref.watch(swapNotifierProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Swap')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.surfaceColor,
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              from(swapState),
              GestureDetector(
                onTap:
                    () => ref.read(swapNotifierProvider.notifier).swapAssets(),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/new_ui_wallet/assets/icons/menu/swap.svg',
                    ),
                  ),
                ),
              ),
              to(swapState),
              SizedBox(height: 15),
              if (swapState.isLoading)
                Shimmer.fromColors(
                  baseColor: AppColors.baseColor,
                  highlightColor: AppColors.highlightColor,
                  child: Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '1 ${swapState.fromAsset.ticker} = ${_getExchangeRate(swapState)} ${swapState.toAsset.ticker}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
              if (swapState.error != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Error: ${swapState.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 15),
              Center(child: Text('Powered by sideswap.io')),
              SizedBox(height: 15),
              PrimaryButton(
                text: 'swap',
                onPressed:
                    swapState.fromAmount.isNotEmpty &&
                            swapState.toAmount.isNotEmpty &&
                            !swapState.isLoading
                        ? () async {
                          final result =
                              await ref
                                  .read(swapNotifierProvider.notifier)
                                  .startSwap();

                          result.fold(
                            (error) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $error')),
                                ),
                            (operation) {
                              ref
                                  .read(swapOperationNotifierProvider.notifier)
                                  .setCurrentOperation(operation);
                              ConfirmSwapBottomSheet.show(context);
                            },
                          );
                        }
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExchangeRate(SwapUiState state) {
    if (state.exchangeRate != null) {
      return state.exchangeRate!.toStringAsFixed(8);
    }
    return '...';
  }

  Widget from(SwapUiState swapState) {
    final notifier = ref.read(swapNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColors.backgroundColor,
      ),
      height: 115,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Você envia', style: Theme.of(context).textTheme.labelLarge),
              Row(
                children: [
                  Text('Balance: ${notifier.getBalance(swapState.fromAsset)}'),
                  SizedBox(width: 5),
                  TransparentTextButton(
                    text: 'MAX',
                    onPressed: () {
                      final maxBalance = notifier.getBalance(
                        swapState.fromAsset,
                      );
                      _fromAmountController.text = maxBalance;
                      notifier.setFromAmount(maxBalance);
                    },
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              SvgPicture.asset(
                notifier.getAssetIconPath(swapState.fromAsset),
                width: 30,
                height: 30,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<Asset>(
                      value: swapState.fromAsset,
                      underline: SizedBox.shrink(),
                      icon: SvgPicture.asset(
                        'assets/new_ui_wallet/assets/icons/menu/arrow_down.svg',
                      ),
                      onChanged: (Asset? newAsset) {
                        if (newAsset != null) {
                          notifier.setFromAsset(newAsset);
                        }
                      },
                      items:
                          Asset.values.map<DropdownMenuItem<Asset>>((
                            Asset asset,
                          ) {
                            return DropdownMenuItem<Asset>(
                              value: asset,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    notifier.getAssetIconPath(asset),
                                    width: 20,
                                    height: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    asset.ticker,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return Asset.values.map<Widget>((Asset asset) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                asset.ticker,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(width: 5),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _fromAmountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: true,
                          hintText: '0',
                          hintStyle: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        onChanged: (value) {
                          notifier.setFromAmount(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(notifier.getAssetDescription(swapState.fromAsset)),
              Text(
                notifier.getUsdValue(swapState.fromAsset, swapState.fromAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget to(SwapUiState swapState) {
    final notifier = ref.read(swapNotifierProvider.notifier);

    return Container(
      height: 115,
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
                      Text(
                        'Balance: ${notifier.getBalance(swapState.toAsset)}',
                        style:
                            Theme.of(context).textTheme.labelLarge!.copyWith(),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    notifier.getAssetIconPath(swapState.toAsset),
                    width: 30,
                    height: 30,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<Asset>(
                          value: swapState.toAsset,
                          underline: SizedBox.shrink(),
                          icon: SvgPicture.asset(
                            'assets/new_ui_wallet/assets/icons/menu/arrow_down.svg',
                          ),
                          onChanged: (Asset? newAsset) {
                            if (newAsset != null) {
                              notifier.setToAsset(newAsset);
                            }
                          },
                          items:
                              Asset.values.map<DropdownMenuItem<Asset>>((
                                Asset asset,
                              ) {
                                return DropdownMenuItem<Asset>(
                                  value: asset,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        notifier.getAssetIconPath(asset),
                                        width: 20,
                                        height: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        asset.ticker,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return Asset.values.map<Widget>((Asset asset) {
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
                                  SizedBox(width: 5),
                                ],
                              );
                            }).toList();
                          },
                        ),
                        Text(
                          swapState.toAmount.isNotEmpty
                              ? swapState.toAmount
                              : '0',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(notifier.getAssetDescription(swapState.toAsset)),
                  Text(
                    notifier.getUsdValue(swapState.toAsset, swapState.toAmount),
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
