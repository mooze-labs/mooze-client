import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

/// Coarse grouping of receive-flow failures, kept for logging/telemetry.
enum ReceiveErrorCategory { connection, amount, asset, generation }

enum ReceiveErrorCode {
  connection,
  invalidAmount,
  invalidAsset,
  generationFailed,
}

/// Presentation-layer error for the receive / QR-generation flow.
///
/// Mirrors [SendValidationError]: the controller classifies raw failures
/// (SDK exceptions, [WalletError]s from invoice generation) into a small set
/// of codes, and the UI only ever calls [localize] — no error-string matching
/// in widgets.
class ReceiveError {
  final ReceiveErrorCode code;
  final ReceiveErrorCategory category;

  /// Underlying raw text, surfaced for codes that carry a specific message and
  /// kept for logging. Never shown to the user for [ReceiveErrorCode.connection].
  final String? detail;

  const ReceiveError({required this.code, required this.category, this.detail});

  /// Classifies a [WalletError] returned by invoice generation / validation.
  factory ReceiveError.fromWalletError(WalletError error) {
    if (_isConnectionFailure(error)) {
      return const ReceiveError(
        code: ReceiveErrorCode.connection,
        category: ReceiveErrorCategory.connection,
      );
    }
    switch (error.type) {
      case WalletErrorType.invalidAmount:
        return ReceiveError(
          code: ReceiveErrorCode.invalidAmount,
          category: ReceiveErrorCategory.amount,
          detail: error.customDescription,
        );
      case WalletErrorType.invalidAsset:
        return ReceiveError(
          code: ReceiveErrorCode.invalidAsset,
          category: ReceiveErrorCategory.asset,
          detail: error.customDescription,
        );
      default:
        return ReceiveError(
          code: ReceiveErrorCode.generationFailed,
          category: ReceiveErrorCategory.generation,
          detail: error.description,
        );
    }
  }

  /// Classifies an unexpected exception thrown during QR generation.
  factory ReceiveError.fromException(Object error) {
    final raw = error.toString();
    if (_isConnectionError(raw)) {
      return const ReceiveError(
        code: ReceiveErrorCode.connection,
        category: ReceiveErrorCategory.connection,
      );
    }
    return ReceiveError(
      code: ReceiveErrorCode.generationFailed,
      category: ReceiveErrorCategory.generation,
      detail: raw,
    );
  }

  /// Returns the user-facing localized message. Connection failures collapse
  /// to a friendly retry message; raw SDK text is never shown for those.
  String localize(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (code) {
      case ReceiveErrorCode.connection:
        return t.receive_connection_error;
      case ReceiveErrorCode.invalidAmount:
        final d = detail;
        return (d == null || d.isEmpty) ? t.wallet_errors_invalid_amount : d;
      case ReceiveErrorCode.invalidAsset:
        final d = detail;
        return (d == null || d.isEmpty) ? t.wallet_errors_invalid_asset : d;
      case ReceiveErrorCode.generationFailed:
        return t.receive_qr_error(detail ?? '');
    }
  }

  @override
  String toString() =>
      '${category.name}:${code.name}${detail != null ? '($detail)' : ''}';
}

bool _isConnectionFailure(WalletError error) {
  if (error.type == WalletErrorType.networkError ||
      error.type == WalletErrorType.connectionError) {
    return true;
  }
  return _isConnectionError(error.description);
}

/// Detects whether a raw backend/SDK error string is a connectivity failure
/// (e.g. Boltz returning `ECONNREFUSED` / "No connection established"), so the
/// UI can show a friendly retry message instead of the raw error details.
bool _isConnectionError(String raw) {
  final lower = raw.toLowerCase();
  const markers = [
    'econnrefused',
    'no connection established',
    'connection refused',
    'connection error',
    'failed host lookup',
    'socketexception',
    'network is unreachable',
    'timed out',
    'timeout',
    'conexão falhou',
    'erro de conexão',
  ];
  return markers.any(lower.contains);
}

class QRGenerationState {
  final bool isLoading;
  final ReceiveError? error;
  final String? displayAddress;

  const QRGenerationState({
    this.isLoading = false,
    this.error,
    this.displayAddress,
  });

  QRGenerationState copyWith({
    String? qrData,
    bool? isLoading,
    ReceiveError? error,
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
    final log = AppLoggerService();

    // Trace the exact origin of every receive request. This is the only
    // entry point to `walletRepository.createXxxInvoice` from the receive
    // funds screen — anything else hitting `WalletErrorType.networkError`
    // is coming from a different path.
    log.info(
      'qrGenerationController',
      'generateQRCode network=${network.name} asset=${asset.ticker} '
          'amount=${amount?.toString() ?? "null"} '
          'descriptionPresent=${description != null} '
          'origin=legacy(walletRepositoryProvider in features/wallet/di) '
          'targetRepo=WalletRepositoryImpl(legacy)',
    );

    try {
      if (amount != null && amount > 0) {
        final validationError = await _validateAmountLimits(amount, network);
        if (validationError != null) {
          log.warning(
            'qrGenerationController',
            'amount-limit-rejected network=${network.name} amount=$amount '
                'reason=${validationError.description}',
          );
          state = AsyncValue.data(
            QRGenerationState(
              isLoading: false,
              error: ReceiveError.fromWalletError(validationError),
            ),
          );
          return;
        }
      }

      final walletRepositoryResult = await ref.read(
        walletRepositoryProvider.future,
      );
      final walletRepository = walletRepositoryResult.fold(
        (error) {
          log.error(
            'qrGenerationController',
            'walletRepositoryProvider returned Left: ${error.description}',
          );
          throw Exception(
            'Failed to get wallet repository: ${error.description}',
          );
        },
        (repository) {
          log.info(
            'qrGenerationController',
            'walletRepositoryProvider resolved repoType=${repository.runtimeType} '
                'repoHash=${identityHashCode(repository)}',
          );
          return repository;
        },
      );

      final result = switch (network) {
        NetworkType.bitcoin => _generateBitcoinPaymentRequest(
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
        (error) {
          // The customDescription now carries the underlying SDK error
          // (Breez exception text), unlike the previous behaviour of a
          // bare "Conexão falhou." with no cause. Log both halves so a
          // log export from a failing user shows everything triage needs.
          log.error(
            'qrGenerationController',
            'invoice-generation FAILED type=${error.type} '
                'description=${error.description} '
                'customDescription=${error.customDescription ?? "n/a"}',
          );
          state = AsyncValue.data(
            QRGenerationState(
              isLoading: false,
              error: ReceiveError.fromWalletError(error),
            ),
          );
        },
        (qrState) {
          log.info(
            'qrGenerationController',
            'invoice-generation ok displayAddress.length='
                '${qrState.displayAddress?.length ?? 0}',
          );
          state = AsyncValue.data(qrState);
        },
      );
    } catch (e, st) {
      log.error(
        'qrGenerationController',
        'generateQRCode threw unhandled exception: $e',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.data(
        QRGenerationState(
          isLoading: false,
          error: ReceiveError.fromException(e),
        ),
      );
    }
  }

  TaskEither<WalletError, QRGenerationState> _generateBitcoinPaymentRequest(
    WalletRepository walletRepository,
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
          String displayAddress = paymentRequest.address;

          if (amount != null || description != null) {
            final uri = StringBuffer('bitcoin:${paymentRequest.address}');
            final params = <String>[];

            if (amount != null) {
              final btcAmount = amount.toStringAsFixed(8);
              params.add('amount=$btcAmount');
            }

            if (description != null && description.isNotEmpty) {
              final encodedDesc = Uri.encodeComponent(description);
              params.add('message=$encodedDesc');
            }

            if (params.isNotEmpty) {
              uri.write('?${params.join('&')}');
            }

            displayAddress = uri.toString();
          }

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  TaskEither<WalletError, QRGenerationState>
  _generateLiquidBitcoinPaymentRequest(
    WalletRepository walletRepository,
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
          String displayAddress = paymentRequest.address;

          return QRGenerationState(
            isLoading: false,
            displayAddress: displayAddress,
            error: null,
          );
        });
  }

  TaskEither<WalletError, QRGenerationState> _generateStablecoinPaymentRequest(
    WalletRepository walletRepository,
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
          return QRGenerationState(
            isLoading: false,
            displayAddress: paymentRequest.address,
            error: null,
          );
        });
  }

  Future<WalletError?> _validateAmountLimits(
    double amount,
    NetworkType network,
  ) async {
    try {
      switch (network) {
        case NetworkType.bitcoin:
          break;
        case NetworkType.liquid:
          break;
        case NetworkType.unknown:
          return const WalletError(
            WalletErrorType.invalidAsset,
            'Tipo de rede não suportado',
          );
      }

      return null;
    } catch (e) {
      return WalletError(
        WalletErrorType.networkError,
        'Erro ao validar limites: $e',
      );
    }
  }

  void reset() {
    state = const AsyncValue.data(QRGenerationState());
  }
}

final qrGenerationControllerProvider =
    AsyncNotifierProvider<QRGenerationAsyncNotifier, QRGenerationState>(
      QRGenerationAsyncNotifier.new,
    );
