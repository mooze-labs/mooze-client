import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import 'package:mooze_mobile/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:mooze_mobile/features/wallet/domain/entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class BtcLbtcFeeEstimate {
  final BigInt boltzServiceFeeSat;
  final BigInt networkFeeSat;
  final BigInt totalFeeSat;

  BtcLbtcFeeEstimate({
    required this.boltzServiceFeeSat,
    required this.networkFeeSat,
    required this.totalFeeSat,
  });
}

class BtcLbtcSwapController {
  final WalletController _walletController;
  final _log = AppLoggerService();
  static const _tag = 'Swap';

  BtcLbtcSwapController(this._walletController);

  static const int minSwapAmount = 25000;

  TaskEither<String, BtcLbtcFeeEstimate> prepareFeeEstimate({
    required BigInt amount,
    required bool isPegIn,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    _log.debug(
      _tag,
      'prepareFeeEstimate — amount: $amount sats, isPegIn: $isPegIn, '
      'drain: $drain, feeRate: $feeRateSatPerVByte sat/vB',
    );

    if (!drain && amount < BigInt.from(minSwapAmount)) {
      _log.warning(
        _tag,
        'prepareFeeEstimate rejected: amount $amount is below minimum $minSwapAmount sats',
      );
      return TaskEither.left(
        'Quantidade mínima é ${(minSwapAmount / 1000).toStringAsFixed(0)}k sats devido às taxas',
      );
    }

    if (isPegIn) {
      return _walletController
          .preparePegInFullFees(
            amount: amount,
            feeRateSatPerVByte: feeRateSatPerVByte,
          )
          .mapLeft((error) {
            _log.error(_tag, 'preparePegInFullFees failed: $error');
            return 'Erro ao preparar peg-in: $error';
          })
          .map((fees) {
            _log.info(
              _tag,
              '[PegIn] Fee estimate — service (Breez): ${fees.breezFeesSat} sats, '
              'network (BDK): ${fees.bdkFeesSat} sats '
              '(${feeRateSatPerVByte ?? 3} sat/vB), '
              'total: ${fees.breezFeesSat + fees.bdkFeesSat} sats',
            );
            return BtcLbtcFeeEstimate(
              boltzServiceFeeSat: fees.breezFeesSat,
              networkFeeSat: fees.bdkFeesSat,
              totalFeeSat: fees.breezFeesSat + fees.bdkFeesSat,
            );
          });
    } else {
      return _walletController.getBitcoinReceiveAddress().flatMap((
        bitcoinAddress,
      ) {
        _log.debug(
          _tag,
          '[PegOut] Preparing fee estimate for address: '
          '${bitcoinAddress.substring(0, bitcoinAddress.length.clamp(0, 14))}...',
        );
        return _walletController
            .beginNewTransaction(
              destination: bitcoinAddress,
              asset: Asset.lbtc,
              blockchain: Blockchain.bitcoin,
              amount: amount,
              feeRateSatPerVByte: feeRateSatPerVByte,
              drain: drain,
            )
            .mapLeft((error) {
              _log.error(_tag, '[PegOut] beginNewTransaction failed: $error');
              return 'Erro ao preparar peg-out: $error';
            })
            .map((psbt) {
              final claimFee =
                  (psbt is PreparedOnchainBitcoinTransaction)
                      ? (psbt.claimFeesSat ?? BigInt.zero)
                      : BigInt.zero;
              final serviceFee = psbt.networkFees - claimFee;

              _log.info(
                _tag,
                '[PegOut] Fee estimate — total: ${psbt.networkFees} sats, '
                'network (claim): $claimFee sats, '
                'service (Boltz): $serviceFee sats',
              );

              return BtcLbtcFeeEstimate(
                boltzServiceFeeSat: serviceFee,
                networkFeeSat: claimFee,
                totalFeeSat: psbt.networkFees,
              );
            });
      });
    }
  }

  TaskEither<String, Transaction> executePegIn({
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (!drain && amount < BigInt.from(minSwapAmount)) {
      _log.warning(
        _tag,
        '[PegIn] executePegIn rejected: amount $amount is below minimum $minSwapAmount sats',
      );
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    _log.info(
      _tag,
      '[PegIn] Executing peg-in — amount: $amount sats, drain: $drain, feeRate: $feeRateSatPerVByte sat/vB',
    );

    return _walletController.executePegIn(
      amount: amount,
      feeRateSatPerVByte: feeRateSatPerVByte,
      drain: drain,
    );
  }

  TaskEither<String, Transaction> executePegOut({
    required BigInt amount,
    int? feeRateSatPerVByte,
    bool drain = false,
  }) {
    if (!drain && amount < BigInt.from(minSwapAmount)) {
      _log.warning(
        _tag,
        '[PegOut] executePegOut rejected: amount $amount is below minimum $minSwapAmount sats',
      );
      return TaskEither.left('Quantidade mínima é $minSwapAmount sats');
    }

    _log.info(
      _tag,
      '[PegOut] Executing peg-out — amount: $amount sats, '
      'drain: $drain, feeRate: $feeRateSatPerVByte sat/vB',
    );

    return _walletController.getBitcoinReceiveAddress().flatMap((
      bitcoinAddress,
    ) {
      _log.debug(
        _tag,
        '[PegOut] Got Bitcoin address for peg-out: '
        '${bitcoinAddress.substring(0, bitcoinAddress.length.clamp(0, 14))}...',
      );
      return _walletController.executePegOut(
        btcAddress: bitcoinAddress,
        amount: amount,
        feeRateSatPerVByte: feeRateSatPerVByte,
        drain: drain,
      );
    });
  }

  bool isValidAmount(BigInt? amount) {
    if (amount == null) return false;
    return amount >= BigInt.from(minSwapAmount);
  }

  String formatSatsToBtc(BigInt sats) {
    final btc = sats.toDouble() / 100000000;
    return btc.toStringAsFixed(8);
  }
}
