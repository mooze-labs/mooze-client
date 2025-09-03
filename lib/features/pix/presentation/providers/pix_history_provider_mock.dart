import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final pixDepositHistoryProviderMock =
    FutureProvider<Either<String, List<PixDeposit>>>((ref) async {
      await Future.delayed(const Duration(seconds: 1));

      final mockDeposits = _generateMockPixDeposits();
      return right(mockDeposits);
    });

final pixDepositProviderMock =
    FutureProvider.family<Either<String, Option<PixDeposit>>, String>((
      ref,
      depositId,
    ) async {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockDeposits = _generateMockPixDeposits();
      final deposit =
          mockDeposits.where((d) => d.depositId == depositId).firstOrNull;

      return right(Option.fromNullable(deposit));
    });

List<PixDeposit> _generateMockPixDeposits() {
  final now = DateTime.now();

  return [
    PixDeposit(
      depositId: 'pix_001_btc_finished',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.btc,
      amountInCents: 50000,
      network: 'PIX',
      status: DepositStatus.finished,
      createdAt: now.subtract(const Duration(hours: 2)),
      blockchainTxid:
          'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
      assetAmount: BigInt.from(875432),
    ),

    PixDeposit(
      depositId: 'pix_003_btc_pending',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.btc,
      amountInCents: 25000,
      network: 'PIX',
      status: DepositStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 15)),
      blockchainTxid: null,
      assetAmount: null,
    ),

    PixDeposit(
      depositId: 'pix_004_depix_expired',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.depix,
      amountInCents: 75000,
      network: 'PIX',
      status: DepositStatus.expired,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      blockchainTxid: null,
      assetAmount: null,
    ),

    PixDeposit(
      depositId: 'pix_006_btc_processing',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.btc,
      amountInCents: 150000,
      network: 'PIX',
      status: DepositStatus.processing,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      blockchainTxid: null,
      assetAmount: null,
    ),

    PixDeposit(
      depositId: 'pix_007_depix_finished',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.depix,
      amountInCents: 80000,
      network: 'PIX',
      status: DepositStatus.finished,
      createdAt: now.subtract(const Duration(days: 2, hours: 8)),
      blockchainTxid:
          'c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567ab2',
      assetAmount: BigInt.from(79432100),
    ),

    PixDeposit(
      depositId: 'pix_009_btc_finished_week',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.btc,
      amountInCents: 120000,
      network: 'PIX',
      status: DepositStatus.finished,
      createdAt: now.subtract(const Duration(days: 7)),
      blockchainTxid:
          'd4e5f6789012345678901234567890abcdef1234567890abcdef1234567abc3',
      assetAmount: BigInt.from(2100543),
    ),

    PixDeposit(
      depositId: 'pix_010_btc_expired',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/F4BECBEA7500BACA5D5790815AC7E6D18975204000053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630413E6',
      asset: Asset.btc,
      amountInCents: 60000,
      network: 'PIX',
      status: DepositStatus.expired,
      createdAt: now.subtract(const Duration(days: 5, hours: 12)),
      blockchainTxid: null,
      assetAmount: null,
    ),
  ];
}
