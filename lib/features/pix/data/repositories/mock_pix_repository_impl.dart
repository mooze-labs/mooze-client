import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories/pix_repository.dart';
import '../models/pix_status_event.dart';

class MockPixRepositoryImpl implements PixRepository {
  final List<PixDeposit> _mockDeposits = [];
  final _statusUpdatesController = StreamController<PixStatusEvent>.broadcast();

  @override
  Stream<PixStatusEvent> get statusUpdates => _statusUpdatesController.stream;

  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  }) {
    final deposit = PixDeposit(
      depositId: 'mock-deposit-${DateTime.now().millisecondsSinceEpoch}',
      pixKey: "chave-pix-aqui",
      asset: asset,
      amountInCents: amountInCents,
      network: network,
      status: DepositStatus.pending,
      createdAt: DateTime.now(),
    );

    _mockDeposits.add(deposit);

    return TaskEither.of(deposit);
  }

  @override
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId) {
    final deposit =
        _mockDeposits.where((d) => d.depositId == depositId).firstOrNull;

    return TaskEither.of(Option.fromNullable(deposit));
  }

  @override
  TaskEither<String, List<PixDeposit>> getDeposits({int? limit, int? offset}) {
    return TaskEither.of(List.from(_mockDeposits));
  }

  @override
  TaskEither<String, List<PixDeposit>> updateDepositDetails(
    List<String> depositIds,
  ) {
    return TaskEither.of(List.from(_mockDeposits));
  }
}
