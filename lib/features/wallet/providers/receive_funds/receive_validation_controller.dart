import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/shared/prices/providers/price_service_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/payment_limits_provider.dart';

enum AmountDisplayMode { fiat, bitcoin, selectedAsset }

class ReceiveValidationState {
  final String? amountError;
  final bool isValid;
  final bool isLoading;
  final double? amountValue;
  final Asset? selectedAsset;
  final NetworkType? selectedNetwork;

  const ReceiveValidationState({
    this.amountError,
    this.isValid = false,
    this.isLoading = false,
    this.amountValue,
    this.selectedAsset,
    this.selectedNetwork,
  });

  ReceiveValidationState copyWith({
    String? amountError,
    bool? isValid,
    bool? isLoading,
    double? amountValue,
    Asset? selectedAsset,
    NetworkType? selectedNetwork,
  }) {
    return ReceiveValidationState(
      amountError: amountError,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
      amountValue: amountValue ?? this.amountValue,
      selectedAsset: selectedAsset ?? this.selectedAsset,
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
    );
  }
}

class ReceiveValidationController
    extends StateNotifier<ReceiveValidationState> {
  ReceiveValidationController(this.ref)
    : super(const ReceiveValidationState()) {
    _initializeValidation();
  }

  final Ref ref;

  void _initializeValidation() async {
    await Future.delayed(Duration.zero);

    final asset = ref.read(selectedReceiveAssetProvider);
    final network = ref.read(selectedReceiveNetworkProvider);

    if (asset != null && network != null) {
      await _performInitialValidation(asset, network);
    }
  }

  Future<void> _performInitialValidation(
    Asset asset,
    NetworkType network,
  ) async {
    try {
      if (network == NetworkType.liquid) {
        state = state.copyWith(
          selectedAsset: asset,
          selectedNetwork: network,
          isValid: true,
          amountError: null,
        );
        return;
      }

      if ((network == NetworkType.lightning ||
              network == NetworkType.bitcoin) &&
          (state.amountValue == null || state.amountValue! <= 0)) {
        final networkName =
            network == NetworkType.lightning ? 'Lightning' : 'Bitcoin';
        state = state.copyWith(
          selectedAsset: asset,
          selectedNetwork: network,
          isValid: false,
          amountError: 'Amount é obrigatório para $networkName',
        );
        return;
      }

      final isValid = await _checkIfValid(
        state.amountValue,
        asset,
        network,
        AmountDisplayMode.bitcoin,
      );

      state = state.copyWith(
        selectedAsset: asset,
        selectedNetwork: network,
        isValid: isValid,
      );
    } catch (e) {
      // In error case, keep initial state
    }
  }

  void validateAmount(
    double? amount, [
    AmountDisplayMode displayMode = AmountDisplayMode.bitcoin,
  ]) async {
    final asset = ref.read(selectedReceiveAssetProvider);
    final network = ref.read(selectedReceiveNetworkProvider);

    String? errorMessage;

    try {
      if (network == NetworkType.lightning) {
        if (amount == null || amount <= 0) {
          errorMessage = 'Amount é obrigatório para Lightning';
        } else {
          final btcAmount = await _convertToBitcoin(amount, displayMode);
          if (btcAmount < 0.000001) {
            errorMessage = 'Valor mínimo: 100 sats (0.000001 BTC)';
          }
        }
      } else if (network == NetworkType.bitcoin) {
        if (amount == null || amount <= 0) {
          errorMessage = 'Amount é obrigatório para Bitcoin';
        } else {
          final btcAmount = await _convertToBitcoin(amount, displayMode);
          if (btcAmount < 0.00025) {
            errorMessage = 'Valor mínimo: 0.00025 BTC';
          }
        }
      } else if (amount != null) {
        final btcAmount = await _convertToBitcoin(amount, displayMode);
        if (btcAmount < 0.00025 && network == NetworkType.bitcoin) {
          errorMessage = 'Valor mínimo: 0.00025 BTC';
        }
      }

      final isFormValid = await _checkIfValid(
        amount,
        asset,
        network,
        displayMode,
      );

      state = state.copyWith(
        amountValue: amount,
        amountError: errorMessage,
        isValid: isFormValid,
      );
    } catch (e) {
      state = state.copyWith(
        amountValue: amount,
        amountError:
            e.toString().contains('Serviços de preço indisponíveis')
                ? 'Serviços de preço indisponíveis. Tente novamente mais tarde.'
                : 'Erro ao validar valor. Tente novamente.',
        isValid: false,
      );
    }
  }

  Future<double> _convertToBitcoin(
    double amount,
    AmountDisplayMode displayMode,
  ) async {
    final selectedAsset = ref.read(selectedReceiveAssetProvider);

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        try {
          final btcPrice = await ref.read(bitcoinPriceProvider.future);
          return amount / btcPrice;
        } catch (e) {
          try {
            final priceServiceResult =
                await ref.read(priceServiceProvider).run();
            final service = priceServiceResult.fold(
              (error) =>
                  throw Exception('Serviço de preços indisponível: $error'),
              (service) => service,
            );

            final btcPriceResult = await service.getCoinPrice(Asset.btc).run();
            final btcPrice = btcPriceResult.fold(
              (error) =>
                  throw Exception('Erro ao obter preço do Bitcoin: $error'),
              (priceOption) => priceOption.fold(
                () => throw Exception('Preço do Bitcoin não disponível'),
                (price) => price,
              ),
            );

            return amount / btcPrice;
          } catch (fallbackError) {
            throw Exception(
              'Serviços de preço indisponíveis. Tente novamente mais tarde.',
            );
          }
        }

      case AmountDisplayMode.bitcoin:
        return amount;

      case AmountDisplayMode.selectedAsset:
        if (selectedAsset == Asset.btc) {
          return amount;
        } else {
          try {
            final priceServiceResult =
                await ref.read(priceServiceProvider).run();
            final service = priceServiceResult.fold(
              (error) =>
                  throw Exception('Serviço de preços indisponível: $error'),
              (service) => service,
            );

            final assetPriceResult =
                await service.getCoinPrice(selectedAsset!).run();
            final assetPrice = assetPriceResult.fold(
              (error) =>
                  throw Exception('Erro ao obter preço do ativo: $error'),
              (priceOption) => priceOption.fold(
                () => throw Exception('Preço do ativo não disponível'),
                (price) => price,
              ),
            );

            final btcPrice = await ref.read(bitcoinPriceProvider.future);

            final fiatValue = amount * assetPrice;
            return fiatValue / btcPrice;
          } catch (e) {
            try {
              final btcPrice = await ref.read(bitcoinPriceProvider.future);

              const usdtToBrlRate = 5.0;
              final fiatValue = amount * usdtToBrlRate;
              return fiatValue / btcPrice;
            } catch (fallbackError) {
              throw Exception(
                'Serviços de preço indisponíveis. Tente novamente mais tarde.',
              );
            }
          }
        }
    }
  }

  void validateAsset(Asset? asset) async {
    final network = ref.read(selectedReceiveNetworkProvider);
    final amount = state.amountValue;

    final isValid = await _checkIfValid(
      amount,
      asset,
      network,
      AmountDisplayMode.bitcoin,
    );

    state = state.copyWith(selectedAsset: asset, isValid: isValid);

    if (network == NetworkType.liquid && asset != null) {
      state = state.copyWith(isValid: true);
    }
  }

  void validateNetwork(NetworkType? network) async {
    final asset = state.selectedAsset;
    final amount = state.amountValue;

    final isValid = await _checkIfValid(
      amount,
      asset,
      network,
      AmountDisplayMode.bitcoin,
    );

    state = state.copyWith(selectedNetwork: network, isValid: isValid);

    if (network == NetworkType.lightning && amount == null) {
      state = state.copyWith(
        amountError: 'Amount é obrigatório para Lightning',
        isValid: false,
      );
    } else if (network == NetworkType.bitcoin && amount == null) {
      state = state.copyWith(
        amountError: 'Amount é obrigatório para Bitcoin',
        isValid: false,
      );
    } else if (network == NetworkType.liquid && asset != null) {
      state = state.copyWith(isValid: true, amountError: null);
    }
  }

  Future<bool> _checkIfValid(
    double? amount,
    Asset? asset,
    NetworkType? network, [
    AmountDisplayMode displayMode = AmountDisplayMode.bitcoin,
  ]) async {
    try {
      if (asset == null) return false;

      if (network == null) return false;

      if (network == NetworkType.lightning) {
        if (amount == null || amount <= 0) return false;

        final btcAmount = await _convertToBitcoin(amount, displayMode);
        if (btcAmount < 0.000001) return false;

        return await _checkDynamicLimits(amount, network, displayMode);
      }

      if (network == NetworkType.bitcoin) {
        return true;
      }

      if (network == NetworkType.liquid) {
        return true;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDynamicLimits(
    double amount,
    NetworkType network,
    AmountDisplayMode displayMode,
  ) async {
    try {
      final btcAmount = await _convertToBitcoin(amount, displayMode);
      final amountSats = BigInt.from((btcAmount * 100000000).round());

      if (network == NetworkType.lightning) {
        final lightningLimits = await ref.read(lightningLimitsProvider.future);
        if (lightningLimits != null) {
          return amountSats >= lightningLimits.send.minSat &&
              amountSats <= lightningLimits.send.maxSat;
        }
        return true;
      } else if (network == NetworkType.bitcoin) {
        final onchainLimits = await ref.read(onchainLimitsProvider.future);
        if (onchainLimits != null) {
          return amountSats >= onchainLimits.send.minSat &&
              amountSats <= onchainLimits.send.maxSat;
        }
        return true;
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  void reset() {
    state = const ReceiveValidationState();
  }
}

final receiveValidationControllerProvider =
    StateNotifierProvider<ReceiveValidationController, ReceiveValidationState>(
      (ref) => ReceiveValidationController(ref),
    );
