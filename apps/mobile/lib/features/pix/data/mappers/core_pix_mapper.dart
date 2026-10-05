import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Maps mooze-core PIX DTOs to the app entities.
///
/// The enum names of [DepositStatusDto] and [DepositStatus] are equal.
DepositStatus depositStatusFromDto(DepositStatusDto status) =>
    DepositStatus.values.byName(status.name);

PixDeposit pixDepositFromDto(PixDepositDto dto) => PixDeposit(
      depositId: dto.depositId,
      pixKey: dto.pixKey,
      asset: Asset.fromId(dto.assetId),
      amountInCents: dto.amountInCents.toInt(),
      network: dto.network,
      status: depositStatusFromDto(dto.status),
      createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdAtMs.toInt()),
      blockchainTxid: dto.blockchainTxid,
      assetAmount: dto.assetAmount,
    );

PixStatusEvent pixStatusEventFromDto(PixStatusEventDto dto) => PixStatusEvent(
      depositId: dto.depositId,
      status: depositStatusFromDto(dto.status),
      blockchainTxid: dto.blockchainTxid,
      assetAmount: dto.assetAmount?.toInt(),
      errorMessage: dto.errorMessage,
    );

FavoritePayer favoritePayerFromDto(FavoritePayerDto dto) => FavoritePayer(
      id: dto.id?.toInt(),
      label: dto.label,
      cpf: dto.cpf,
    );
