import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/domain/entities/liquid_send_draft.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/key_management/store.dart';

import '../../domain/entities/peg_error.dart';
import '../../domain/repositories/peg_wallet.dart';

class PegWalletImpl implements PegWallet {
  PegWalletImpl({
    required WalletController walletController,
    required LiquidWalletService liquidService,
    required MnemonicStore mnemonicStore,
    LiquidSpendCoordinator? coordinator,
  }) : _wallet = walletController,
       _liquid = liquidService,
       _mnemonicStore = mnemonicStore,
       _coordinator = coordinator ?? LiquidSpendCoordinator.instance;

  final WalletController _wallet;
  final LiquidWalletService _liquid;
  final MnemonicStore _mnemonicStore;
  final LiquidSpendCoordinator _coordinator;

  @override
  TaskEither<PegError, String> getLiquidPayoutAddress() {
    return TaskEither(() async {
      final result = await _liquid.getReceiveAddress();
      return result.fold(
        (f) => left(PegWalletFailure(f.message)),
        (address) => right(address),
      );
    });
  }

  @override
  TaskEither<PegError, String> getBitcoinPayoutAddress() {
    return _wallet.getBitcoinReceiveAddress().mapLeft<PegError>(
      (e) => PegWalletFailure(e),
    );
  }

  static const _liquidPrefixes = ['lq1', 'tlq1', 'ex1', 'tex1', 'el1', 'ert1'];

  static bool _looksLikeLiquidAddress(String address) {
    final a = address.trim().toLowerCase();
    return _liquidPrefixes.any(a.startsWith);
  }

  /// Test seam for the guard above. Exposed because the invariant it protects
  /// — peg-in funding never reaching Breez — is worth asserting directly.
  @visibleForTesting
  static bool looksLikeLiquidAddressForTest(String address) =>
      _looksLikeLiquidAddress(address);

  @override
  TaskEither<PegError, PegFundingQuote> quoteBitcoinFunding({
    required String destination,
    required BigInt amountSat,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (_looksLikeLiquidAddress(destination)) {
      return TaskEither.left(
        PegWalletFailure(
          'destino de peg-in não é um endereço Bitcoin: $destination',
        ),
      );
    }
    return _wallet
        .beginNewTransaction(
          destination: destination,
          asset: Asset.btc,
          blockchain: Blockchain.bitcoin,
          amount: amountSat,
          feeRateSatPerVByte: feeRateSatPerVByte,
          drain: drain,
        )
        .mapLeft<PegError>(_classifyWalletError)
        .map(
          (psbt) => PegFundingQuote(
            handle: psbt,
            // For a drain the PSBT's own value is authoritative; for a fixed
            // amount it equals what we asked for.
            amountSat: drain ? amountSat : amountSat,
            networkFeeSat: psbt.networkFees,
          ),
        );
  }

  @override
  TaskEither<PegError, PegFundingQuote> quoteLiquidFunding({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  }) {
    return TaskEither(() async {
      final result = await _liquid.buildLbtcSend(
        destination: destination,
        amountSat: amountSat,
        feeRateSatPerVb: feeRateSatPerVb,
        drain: drain,
      );
      return result.fold(
        (f) => left(_classifyWalletError(f.message)),
        (draft) => right(
          PegFundingQuote(
            handle: draft,
            amountSat: draft.amountSat,
            networkFeeSat: draft.feeSat,
          ),
        ),
      );
    });
  }

  @override
  TaskEither<PegError, String> broadcastBitcoinFunding(PegFundingQuote quote) {
    final psbt = quote.handle;
    if (psbt is! PartiallySignedTransaction) {
      return TaskEither.left(
        const PegWalletFailure('quote inválido para envio Bitcoin'),
      );
    }
    if (_looksLikeLiquidAddress(psbt.destination)) {
      return TaskEither.left(
        PegWalletFailure(
          'transação de peg-in aponta para endereço Liquid: ${psbt.destination}',
        ),
      );
    }
    return _wallet
        .confirmTransaction(psbt: psbt)
        .mapLeft<PegError>(_classifyWalletError)
        .map((tx) => tx.sendTxId ?? tx.id);
  }

  @override
  TaskEither<PegError, String> broadcastLiquidFunding(PegFundingQuote quote) {
    final draft = quote.handle;
    if (draft is! LiquidSendDraft) {
      return TaskEither.left(
        const PegWalletFailure('quote inválido para envio Liquid'),
      );
    }

    return TaskEither(() async {
      final mnemonicResult = await _mnemonicStore.getMnemonic().run();
      final mnemonic = mnemonicResult.toNullable()?.toNullable();
      if (mnemonic == null || mnemonic.isEmpty) {
        return left(
          const PegWalletFailure('frase de recuperação não encontrada'),
        );
      }

      try {
        final txid = await _coordinator.protect(
          'sideswap:pegOutFunding',
          () async {
            final result = await _liquid.signAndBroadcastPset(
              pset: draft.pset,
              mnemonic: mnemonic,
            );
            return result.fold(
              (f) => throw _PegBroadcastFailure(f.message),
              (txid) => txid,
            );
          },
          beforeSpend: () => _liquid.sync().then((_) {}),
        );
        return right(txid);
      } on _PegBroadcastFailure catch (e) {
        return left(PegWalletFailure(e.message));
      } on LiquidSpendLockTimeout catch (e) {
        return left(PegWalletBusy(e.toString()));
      } catch (e) {
        return left(PegWalletFailure(e.toString()));
      }
    });
  }

  static PegError _classifyWalletError(String message) {
    final m = message.toLowerCase();
    if (m.contains('insufficient') ||
        m.contains('insuficiente') ||
        m.contains('saldo')) {
      return PegInsufficientFunds(message);
    }
    return PegWalletFailure(message);
  }
}

class _PegBroadcastFailure implements Exception {
  _PegBroadcastFailure(this.message);
  final String message;
}
