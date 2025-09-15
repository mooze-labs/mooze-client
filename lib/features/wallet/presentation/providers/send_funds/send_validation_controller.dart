import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'selected_asset_provider.dart';
import 'amount_provider.dart';
import 'address_provider.dart';
import 'network_detection_provider.dart';
import 'selected_asset_balance_provider.dart';

class SendValidationController extends StateNotifier<SendValidationState> {
  final Ref ref;

  SendValidationController(this.ref) : super(const SendValidationState());

  Future<void> validateTransaction() async {
    final asset = ref.read(selectedAssetProvider);
    final amount = ref.read(finalAmountProvider);
    final address = ref.read(addressStateProvider);
    final networkType = ref.read(networkDetectionProvider(address));

    final errors = <String>[];

    if (address.isEmpty) {
      errors.add('Endereço é obrigatório');
    } else if (networkType == NetworkType.unknown) {
      errors.add('Endereço inválido ou não suportado');
    }

    if (address.isNotEmpty && networkType != NetworkType.unknown) {
      if (asset != Asset.btc && networkType != NetworkType.liquid) {
        errors.add('${asset.name} só pode ser enviado pela rede Liquid');
      }
    }

    if (amount <= 0) {
      errors.add('Valor deve ser maior que zero');
    }

    if (asset == Asset.btc &&
        amount < 25000 &&
        networkType == NetworkType.bitcoin) {
      errors.add('Valor mínimo para bitcoin onchain é 25.000 sats');
    }

    if (asset == Asset.btc &&
        amount < 21 &&
        networkType == NetworkType.lightning) {
      errors.add('Valor mínimo para bitcoin lightning é 21 sats');
    }

    if (asset == Asset.usdt &&
        amount < 50000000 &&
        networkType == NetworkType.liquid) {
      errors.add('Valor mínimo para USDT é 0.5 USDT');
    }

    if (asset == Asset.depix &&
        amount < 100000000 &&
        networkType == NetworkType.liquid) {
      errors.add('Valor mínimo para Depix é 1.0 Depix');
    }

    try {
      final balanceResult = await ref.read(
        selectedAssetBalanceRawProvider.future,
      );
      balanceResult.fold(
        (error) => errors.add('Erro ao verificar saldo disponível'),
        (balance) {
          if (amount > balance.toInt()) {
            errors.add('Valor informado é maior que o saldo disponível');
          }
        },
      );
    } catch (e) {
      errors.add('Erro ao verificar saldo disponível');
    }

    state = SendValidationState(
      isValid: errors.isEmpty,
      errors: errors,
      canProceed: errors.isEmpty && address.isNotEmpty && amount > 0,
    );
  }

  void clearValidation() {
    state = const SendValidationState();
  }
}

class SendValidationState {
  final bool isValid;
  final List<String> errors;
  final bool canProceed;

  const SendValidationState({
    this.isValid = false,
    this.errors = const [],
    this.canProceed = false,
  });
}

final sendValidationControllerProvider =
    StateNotifierProvider<SendValidationController, SendValidationState>((ref) {
      return SendValidationController(ref);
    });
