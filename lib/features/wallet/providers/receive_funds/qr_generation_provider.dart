import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';

// Estado para geração de QR code
class QRGenerationState {
  final String? qrData;
  final bool isLoading;
  final String? error;
  final String? displayAddress;

  const QRGenerationState({
    this.qrData,
    this.isLoading = false,
    this.error,
    this.displayAddress,
  });

  QRGenerationState copyWith({
    String? qrData,
    bool? isLoading,
    String? error,
    String? displayAddress,
  }) {
    return QRGenerationState(
      qrData: qrData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      displayAddress: displayAddress ?? this.displayAddress,
    );
  }
}

// Controller para gerenciar geração de QR codes
class QRGenerationController extends StateNotifier<QRGenerationState> {
  QRGenerationController() : super(const QRGenerationState());

  // Gera QR code baseado na network e parâmetros
  Future<void> generateQRCode({
    required NetworkType network,
    required Asset asset,
    double? amount,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      String qrData;
      String displayAddress;

      switch (network) {
        case NetworkType.bitcoin:
          // Para Bitcoin, gera endereço on-chain
          displayAddress = _generateBitcoinAddress();
          qrData = _formatBitcoinURI(displayAddress, amount, description);
          break;

        case NetworkType.lightning:
          if (amount == null || amount <= 0) {
            state = state.copyWith(
              isLoading: false,
              error: 'Amount é obrigatório para Lightning',
            );
            return;
          }
          // Para Lightning, gera invoice
          final invoice = await _generateLightningInvoice(amount, description);
          displayAddress = invoice;
          qrData = invoice;
          break;

        case NetworkType.liquid:
          // Para Liquid, gera endereço liquid
          displayAddress = _generateLiquidAddress();
          qrData = _formatLiquidURI(displayAddress, asset, amount, description);
          break;

        case NetworkType.unknown:
          state = state.copyWith(
            isLoading: false,
            error: 'Network não suportada',
          );
          return;
      }

      state = state.copyWith(
        isLoading: false,
        qrData: qrData,
        displayAddress: displayAddress,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao gerar QR code: $e',
      );
    }
  }

  // Gera endereço Bitcoin (mock)
  String _generateBitcoinAddress() {
    // TODO: Integrar com wallet real
    return 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4';
  }

  // Gera endereço Liquid (mock)
  String _generateLiquidAddress() {
    // TODO: Integrar com wallet real
    return 'lq1qqw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4';
  }

  // Gera invoice Lightning (mock)
  Future<String> _generateLightningInvoice(
    double amount,
    String? description,
  ) async {
    // Simula delay da rede
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Integrar com Lightning wallet real
    final satsAmount = (amount * 100000000).round();
    return 'lnbc${satsAmount}n1p2xqhj8pp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdqqcqzpgxqyz5vqsp5usyxuhqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqgz7n';
  }

  // Formata URI para Bitcoin
  String _formatBitcoinURI(
    String address,
    double? amount,
    String? description,
  ) {
    var uri = 'bitcoin:$address';
    final params = <String>[];

    if (amount != null && amount > 0) {
      params.add('amount=$amount');
    }

    if (description != null && description.isNotEmpty) {
      params.add('label=${Uri.encodeComponent(description)}');
    }

    if (params.isNotEmpty) {
      uri += '?${params.join('&')}';
    }

    return uri;
  }

  // Formata URI para Liquid
  String _formatLiquidURI(
    String address,
    Asset asset,
    double? amount,
    String? description,
  ) {
    var uri = 'liquidnetwork:$address';
    final params = <String>[];

    if (amount != null && amount > 0) {
      params.add('amount=$amount');
    }

    if (asset != Asset.btc) {
      params.add('assetid=${asset.id}');
    }

    if (description != null && description.isNotEmpty) {
      params.add('label=${Uri.encodeComponent(description)}');
    }

    if (params.isNotEmpty) {
      uri += '?${params.join('&')}';
    }

    return uri;
  }

  // Reset do estado
  void reset() {
    state = const QRGenerationState();
  }
}

// Provider do controller
final qrGenerationControllerProvider =
    StateNotifierProvider<QRGenerationController, QRGenerationState>(
      (ref) => QRGenerationController(),
    );
