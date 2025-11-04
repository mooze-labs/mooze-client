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
      depositId: 'pix_002_btc_pending',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/A1B2C3D4E5F6789ABCDEF00053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***630487A5',
      asset: Asset.btc,
      amountInCents: 10000,
      network: 'PIX',
      status: DepositStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 45)),
    ),
    PixDeposit(
      depositId: 'pix_003_lbtc_processing',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/1234567890ABCDEF11223344550053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***6304B8C9',
      asset: Asset.lbtc,
      amountInCents: 25000,
      network: 'PIX',
      status: DepositStatus.processing,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
    ),
    PixDeposit(
      depositId: 'pix_003_5_btc_under_review',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/UNDERREV1234567890ABC0053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***6304C5D6',
      asset: Asset.btc,
      amountInCents: 30000,
      network: 'PIX',
      status: DepositStatus.underReview,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    PixDeposit(
      depositId: 'pix_004_lbtc_broadcasted',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/FEDCBA9876543210ABCDEF0053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***6304F1A2',
      asset: Asset.lbtc,
      amountInCents: 75000,
      network: 'PIX',
      status: DepositStatus.broadcasted,
      createdAt: now.subtract(const Duration(hours: 3)),
      blockchainTxid:
          'b2c3d4e5f67890123456789012345678901abcdef2345678901abcdef234567',
      assetAmount: BigInt.from(2500000),
    ),
    PixDeposit(
      depositId: 'pix_005_btc_funds_prepared',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/9876543210ABCDEF12345670053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***6304D3E4',
      asset: Asset.btc,
      amountInCents: 15000,
      network: 'PIX',
      status: DepositStatus.fundsPrepared,
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    PixDeposit(
      depositId: 'pix_006_btc_failed',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/ABCDEF1234567890FEDCBA0053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***63046F7G',
      asset: Asset.btc,
      amountInCents: 100000,
      network: 'PIX',
      status: DepositStatus.failed,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    PixDeposit(
      depositId: 'pix_007_depix_depix_sent',
      pixKey:
          '00020101021226860014br.gov.bcb.pix2564qrcode.fitbank.com.br/QR/cob/DEPIX1234567890ABCD0053039865802BR5925PLEBANK.COM.BR SOLUCOES E6007BARUERI61080645400062070503***6304A1B2',
      asset: Asset.depix,
      amountInCents: 50000,
      network: 'PIX',
      status: DepositStatus.depixSent,
      createdAt: now.subtract(const Duration(hours: 8)),
      assetAmount: BigInt.from(5000000),
    ),
  ];
}
