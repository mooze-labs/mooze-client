import 'dart:math';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:mooze_mobile/features/wallet/data/breez/dto/payment_request_dto.dart';

import 'package:mooze_mobile/features/wallet/domain/entities/payment_request.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';

import './datasources/breez_wallet_data_source.dart';
import './dto/psbt_dto.dart';

class BreezWalletRepositoryImpl extends WalletRepository {
  final BindingLiquidSdk _breez;
  PrepareSendResponse? _cachedSendResponse;

  BreezWalletRepositoryImpl(this._breez);

  @override
  Future<PaymentRequest> createInvoice(
    Asset asset,
    Blockchain blockchain,
    BigInt? amount,
    String? description,
  ) async {
    if (asset != Asset.btc) {
      if (blockchain != Blockchain.liquid) {
        throw ArgumentError('Custom assets are only supported on Liquid.');
      }

      return await _createAssetPaymentRequest(
        Asset.toId(asset),
        amount,
        description,
      );
    }

    if (blockchain == Blockchain.bitcoin) {
      return await _createOnchainBitcoinPaymentRequest(amount, description);
    }

    if (blockchain == Blockchain.lightning) {
      return await _createLightningPaymentRequest(amount, description);
    }

    return await _createLiquidBitcoinPaymentRequest(amount, description);
  }

  Future<PaymentRequest> _createLiquidBitcoinPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    final optionalAmount =
        (amount != null) ? ReceiveAmount_Bitcoin(payerAmountSat: amount) : null;

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.liquidAddress,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.liquidAddress,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createLightningPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    if (amount == null) {
      throw ArgumentError('Amount is required for lightning invoices');
    }

    final optionalAmount = ReceiveAmount_Bitcoin(payerAmountSat: amount);

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.lightning,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.lightning,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createOnchainBitcoinPaymentRequest(
    BigInt? amount,
    String? description,
  ) async {
    final optionalAmount =
        (amount != null) ? ReceiveAmount_Bitcoin(payerAmountSat: amount) : null;
    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.bitcoinAddress,
        amount: optionalAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromBitcoin(
      paymentResponse: res,
      paymentMethod: PaymentMethod.bitcoinAddress,
      feesSat: prepareReceivePayment.feesSat,
      amount: optionalAmount,
      description: description,
    ).toDomain();
  }

  Future<PaymentRequest> _createAssetPaymentRequest(
    String assetId,
    BigInt? amount,
    String? description,
  ) async {
    final assetAmount =
        (amount != null) ? (amount.toInt() / pow(10, 8)).toDouble() : null;
    final recvAmount = ReceiveAmount_Asset(
      assetId: assetId,
      payerAmount: assetAmount,
    );

    final prepareReceivePayment = await _breez.prepareReceivePayment(
      req: PrepareReceiveRequest(
        paymentMethod: PaymentMethod.liquidAddress,
        amount: recvAmount,
      ),
    );

    final ReceivePaymentResponse res = await _breez.receivePayment(
      req: ReceivePaymentRequest(
        prepareResponse: prepareReceivePayment,
        description: description,
      ),
    );

    return BreezPaymentRequestDto.fromAsset(
      paymentResponse: res,
      amount: recvAmount,
      feesSat: prepareReceivePayment.feesSat,
      description: description,
    ).toDomain();
  }

  @override
  Future<PartiallySignedTransaction> buildTransaction(
    String destination,
    Asset asset,
    BigInt amount,
  ) async {
    if (asset != Asset.btc) {
      return await _buildAssetTransaction(destination, asset, amount);
    }

    return await _buildBitcoinTransaction(destination, amount);
  }

  Future<PartiallySignedTransaction> _buildAssetTransaction(
    String destination,
    Asset asset,
    BigInt amount,
  ) async {
  }

  Future<PartiallySignedTransaction> _buildBitcoinTransaction(
    String destination,
    BigInt amount,
  ) async {
    throw UnimplementedError();
  }
}
