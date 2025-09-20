import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';

class QRGenerationState {
  final bool isLoading;
  final String? error;
  final String? displayAddress;

  const QRGenerationState({
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
      isLoading: isLoading ?? this.isLoading,
      error: error,
      displayAddress: displayAddress ?? this.displayAddress,
    );
  }
}

class QRGenerationAsyncNotifier extends AsyncNotifier<QRGenerationState> {
  @override
  FutureOr<QRGenerationState> build() {
    return const QRGenerationState();
  }

  Future<void> generateQRCode({
    required NetworkType network,
    required Asset asset,
    double? amount,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    try {
      final walletRepositoryResult = await ref.read(
        walletRepositoryProvider.future,
      );
      final walletRepository = walletRepositoryResult.fold(
        (error) =>
            throw Exception(
              'Failed to get wallet repository: ${error.description}',
            ),
        (repository) => repository,
      );

      final result = switch (network) {
        NetworkType.bitcoin => _generateBitcoinPaymentRequest(
          walletRepository,
          amount,
          description,
        ),
        NetworkType.lightning =>
          amount == null || amount <= 0
              ? TaskEither<WalletError, QRGenerationState>.left(
                const WalletError(
                  WalletErrorType.invalidAmount,
                  'Amount é obrigatório para Lightning',
                ),
              )
              : _generateLightningPaymentRequest(
                walletRepository,
                amount,
                description,
              ),
        NetworkType.liquid =>
          asset == Asset.btc
              ? _generateLiquidBitcoinPaymentRequest(
                walletRepository,
                amount,
                description,
              )
              : _generateStablecoinPaymentRequest(
                walletRepository,
                asset,
                amount,
                description,
              ),
        NetworkType.unknown => TaskEither<WalletError, QRGenerationState>.left(
          const WalletError(
            WalletErrorType.invalidAsset,
            'Network não suportada',
          ),
        ),
      };

      final finalResult = await result.run();

      finalResult.fold(
        (error) =>
            state = AsyncValue.data(
              QRGenerationState(isLoading: false, error: error.description),
            ),
        (qrState) => state = AsyncValue.data(qrState),
      );
    } catch (e) {
      state = AsyncValue.data(
        QRGenerationState(isLoading: false, error: 'Erro ao gerar QR code: $e'),
      );
    }
  }

  TaskEither<WalletError, QRGenerationState> _generateBitcoinPaymentRequest(
    LiquidWalletRepository walletRepository,
    double? amount,
    String? description,
  ) {
    final amountSats =
        amount != null ? BigInt.from((amount * 100000000).round()) : null;

    return walletRepository
        .createBitcoinInvoice(
          Option.fromNullable(amountSats),
          Option.fromNullable(description),
        )
        .map((paymentRequest) {
          final displayAddress = paymentRequest.address;
          final qrData = _formatBitcoinURI(displayAddress, amount, description);

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  TaskEither<WalletError, QRGenerationState> _generateLightningPaymentRequest(
    LiquidWalletRepository walletRepository,
    double amount,
    String? description,
  ) {
    final amountSats = BigInt.from((amount * 100000000).round());

    return walletRepository
        .createLightningInvoice(amountSats, Option.fromNullable(description))
        .map((paymentRequest) {
          final displayAddress = paymentRequest.address;

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  TaskEither<WalletError, QRGenerationState>
  _generateLiquidBitcoinPaymentRequest(
    LiquidWalletRepository walletRepository,
    double? amount,
    String? description,
  ) {
    final amountSats =
        amount != null ? BigInt.from((amount * 100000000).round()) : null;

    return walletRepository
        .createLiquidBitcoinInvoice(
          Option.fromNullable(amountSats),
          Option.fromNullable(description),
        )
        .map((paymentRequest) {
          final displayAddress = paymentRequest.address;

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  TaskEither<WalletError, QRGenerationState> _generateStablecoinPaymentRequest(
    LiquidWalletRepository walletRepository,
    Asset asset,
    double? amount,
    String? description,
  ) {
    final amountSats =
        amount != null ? BigInt.from((amount * 100000000).round()) : null;

    return walletRepository
        .createStablecoinInvoice(
          asset,
          Option.fromNullable(amountSats),
          Option.fromNullable(description),
        )
        .map((paymentRequest) {
          final displayAddress = paymentRequest.address;

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  String _formatBitcoinURI(
    String address,
    double? amount,
    String? description,
  ) {
    var uri = address;
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

  void reset() {
    state = const AsyncValue.data(QRGenerationState());
  }
}

final qrGenerationControllerProvider =
    AsyncNotifierProvider<QRGenerationAsyncNotifier, QRGenerationState>(
      QRGenerationAsyncNotifier.new,
    );
