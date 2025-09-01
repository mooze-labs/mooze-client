import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/qr_generation_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/amount_field_receive.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/price_service_provider.dart';

class GenerateQRButton extends ConsumerWidget {
  const GenerateQRButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationState = ref.watch(receiveValidationControllerProvider);
    final qrState = ref.watch(qrGenerationControllerProvider);

    final isLoading = qrState.isLoading;
    final isEnabled = validationState.isValid && !isLoading;

    return PrimaryButton(
      onPressed: isEnabled ? () => _generateQR(context, ref) : null,
      text: 'Gerar QR Code',
      isEnabled: isEnabled,
    );
  }

  void _generateQR(BuildContext context, WidgetRef ref) async {
    final selectedAsset = ref.read(selectedReceiveAssetProvider);
    final selectedNetwork = ref.read(selectedReceiveNetworkProvider);
    final amountText = ref.read(receiveAmountProvider);
    final displayMode = ref.read(receiveAmountDisplayModeProvider);
    final currentCurrency = ref.read(currencyControllerProvider);

    if (selectedAsset == null || selectedNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um ativo e rede')),
      );
      return;
    }

    double? finalAmount;
    if (amountText.isNotEmpty) {
      final inputAmount = double.tryParse(amountText);
      if (inputAmount != null) {
        double? assetPrice;
        double? bitcoinPrice;

        if (displayMode == AmountDisplayMode.fiat ||
            displayMode == AmountDisplayMode.bitcoin ||
            displayMode == AmountDisplayMode.selectedAsset ||
            displayMode == AmountDisplayMode.sats) {
          final priceServiceResult = await ref.read(priceServiceProvider).run();
          await priceServiceResult.fold(
            (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao obter serviço de preços: $error'),
                ),
              );
              return;
            },
            (service) async {
              final assetPriceResult =
                  await service.getCoinPrice(selectedAsset).run();
              assetPriceResult.fold(
                (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao obter cotação de ${selectedAsset.name}: $error',
                      ),
                    ),
                  );
                  return;
                },
                (priceOption) {
                  priceOption.fold(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Preço de ${selectedAsset.name} não disponível',
                        ),
                      ),
                    );
                    return;
                  }, (price) => assetPrice = price);
                },
              );

              final bitcoinPriceResult =
                  await service.getCoinPrice(Asset.btc).run();
              bitcoinPriceResult.fold((error) {}, (priceOption) {
                priceOption.fold(() {}, (price) => bitcoinPrice = price);
              });
            },
          );
        }

        finalAmount = _convertToAssetUnit(
          inputAmount,
          displayMode,
          selectedAsset,
          currentCurrency,
          assetPrice,
          bitcoinPrice,
        );
      }
    }

    final qrController = ref.read(qrGenerationControllerProvider.notifier);

    await qrController.generateQRCode(
      network: selectedNetwork,
      asset: selectedAsset,
      amount: finalAmount,
      description: null,
    );
    final qrState = ref.read(qrGenerationControllerProvider);

    if (qrState.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(qrState.error!)));
    } else if (qrState.qrData != null) {
      context.push(
        '/receive-qr',
        extra: {
          'qrData': qrState.qrData!,
          'displayAddress': qrState.displayAddress!,
          'asset': selectedAsset,
          'network': selectedNetwork,
          'amount': finalAmount,
          'description': null,
        },
      );
    }
  }

  double _convertToAssetUnit(
    double amount,
    AmountDisplayMode displayMode,
    Asset selectedAsset,
    dynamic currentCurrency,
    double? realAssetPrice,
    double? bitcoinPrice,
  ) {
    switch (displayMode) {
      case AmountDisplayMode.fiat:
        if (realAssetPrice != null) {
          return amount / realAssetPrice;
        } else if (bitcoinPrice != null) {
          return amount / bitcoinPrice;
        } else {
          throw Exception(
            'Serviços de preço indisponíveis. Tente novamente mais tarde.',
          );
        }
      case AmountDisplayMode.bitcoin:
        return amount;
      case AmountDisplayMode.selectedAsset:
        return amount;
      case AmountDisplayMode.sats:
        // Para sats, precisamos converter para o ativo selecionado
        if (selectedAsset == Asset.btc) {
          // Se for Bitcoin, converter sats diretamente para BTC
          return amount / 100000000;
        } else {
          // Se for outro ativo (como DEPIX), converter sats para valor equivalente no ativo
          if (realAssetPrice != null && bitcoinPrice != null) {
            // Converter sats para BTC
            final btcAmount = amount / 100000000;
            // Converter BTC para valor fiat
            final fiatValue = btcAmount * bitcoinPrice;
            // Converter valor fiat para o ativo selecionado
            return fiatValue / realAssetPrice;
          } else {
            throw Exception(
              'Serviços de preço indisponíveis. Tente novamente mais tarde.',
            );
          }
        }
    }
  }
}
