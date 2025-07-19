import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories/pix_repository.dart';

class MockPixRepositoryImpl implements PixRepository {
  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  }) {
    return TaskEither.of(
      PixDeposit(
        id: 'mock-pix-id',
        qrCopyPaste: "mock-qr-copy-paste",
        qrImageUrl: "https://example.com/mock-qr-image.png",
      ),
    );
  }

  @override
  Stream<PixStatusUpdate> subscribeToStatusUpdates(String pixId) async* {
    // First status: pending
    yield PixStatusUpdate(id: pixId, status: 'pending');

    // Wait a bit before next status
    await Future.delayed(Duration(seconds: 2));

    // Second status: processing
    yield PixStatusUpdate(id: pixId, status: 'processing');

    // Wait a bit before final status
    await Future.delayed(Duration(seconds: 3));

    // Final status: finished with blockchain transaction ID
    yield PixStatusUpdate(
      id: pixId,
      status: 'finished',
      blockchainTxid: 'mock-blockchain-txid-123456789',
    );
  }
}
