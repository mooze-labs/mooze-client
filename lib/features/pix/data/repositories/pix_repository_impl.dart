import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventflux/eventflux.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repository.dart';

import '../datasources/pix_deposit_db.dart';
import '../models.dart';

class PixRepositoryImpl implements PixRepository {
  final Dio _dio;
  final PixDepositDatabase _database;

  PixRepositoryImpl(Dio dio, PixDepositDatabase database)
    : _dio = dio,
      _database = database;

  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  }) {
    return _requestNewPixDeposit(
      amountInCents,
      address,
      asset,
      network,
    ).flatMap(
      (response) => _database
          .addNewDeposit(response.depositId, asset.id, amountInCents)
          .map((_) {
            // Start background subscription to status updates
            _subscribeToStatusUpdates(response.depositId)
                .timeout(Duration(minutes: 20))
                .listen(
                  (statusUpdate) => statusUpdate.fold(
                    (error) => {}, // Handle errors silently
                    (update) => _updateTransactionStatus(update).run(),
                  ),
                  onError: (error) {
                    if (error is TimeoutException) {
                      _updateTransactionStatus(
                        PixStatusEvent(
                          depositId: response.depositId,
                          status: "expired",
                        ),
                      ).run();
                    }
                  },
                );

            return PixDeposit(
              depositId: response.depositId,
              asset: asset,
              amountInCents: amountInCents,
              network: network,
              status: DepositStatus.pending,
            );
          }),
    );
  }

  @override
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId) {
    return _database
        .getDeposit(depositId)
        .flatMap(
          (f) => f.fold(
            () => TaskEither.right(Option<PixDeposit>.none()),
            (f) => TaskEither.fromEither(parseDepositStatus(f.status)).flatMap(
              (s) => TaskEither.right(
                Option.of(
                  PixDeposit(
                    depositId: f.depositId,
                    amountInCents: f.amountInCents,
                    asset: Asset.fromId(f.assetId),
                    network: "liquid",
                    status: s,
                    blockchainTxid: f.blockchainTxid,
                    assetAmount: f.assetAmount,
                  ),
                ),
              ),
            ),
          ),
        );
  }

  @override
  TaskEither<String, List<PixDeposit>> getAllDeposits() {
    return _database
        .getAllDeposits()
        .map(
          (deposits) => deposits
              .map(
                (deposit) => parseDepositStatus(deposit.status).map(
                  (status) => PixDeposit(
                    depositId: deposit.depositId,
                    amountInCents: deposit.amountInCents,
                    asset: Asset.fromId(deposit.assetId),
                    network: "liquid",
                    status: status,
                    blockchainTxid: deposit.blockchainTxid,
                    assetAmount: deposit.assetAmount,
                  ),
                ),
              )
              .where((either) => either.isRight())
              .map((either) => either.fold((l) => throw Exception(l), (r) => r))
              .toList(),
        );
  }

  Stream<Either<String, PixStatusEvent>> _subscribeToStatusUpdates(
    String pixId,
  ) {
    final controller = StreamController<Either<String, PixStatusEvent>>();
    final baseUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: 'https://api.mooze.app/v1/',
    );

    final eventChannel = EventFlux.spawn();
    eventChannel.connect(
      EventFluxConnectionType.get,
      "$baseUrl/subscribe?event_type=transaction&event_id=$pixId",
      tag: 'pix-status-update-stream',
      onSuccessCallback: (EventFluxResponse? response) {
        response?.stream?.listen(
          (data) {
            final update = PixStatusEvent.fromJson(jsonDecode(data.data));
            controller.add(Right(update));
          },
          onError: (error) => controller.add(Left(error.toString())),
          onDone: () => controller.close(),
        );
      },
      onError: (error) {
        controller.add(Left(error.toString()));
        controller.close();
      },
      autoReconnect: true,
      reconnectConfig: ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: Duration(seconds: 1),
        maxAttempts: 5,
      ),
    );

    return controller.stream.map(
      (either) => either.fold(
        (error) => Either.left(error.toString()),
        (update) => Either.right(update),
      ),
    );
  }

  TaskEither<String, PixDepositResponse> _requestNewPixDeposit(
    int amountInCents,
    String address,
    Asset asset,
    String network,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await _dio.post(
        '/transactions/deposit',
        data: {
          "address": address,
          "amount_in_cents": amountInCents,
          "asset": asset.id,
          "network": network,
        },
      );

      if (response.statusCode != 200) {
        throw Exception("${response.statusCode} ${response.statusMessage}");
      }

      return PixDepositResponse.fromJson(response.data);
    }, (error, stackTrace) => "Erro ao gerar QR code: $error");
  }

  TaskEither<String, Unit> _updateTransactionStatus(PixStatusEvent pixStatus) {
    return _database.updateDepositStatus(pixStatus.depositId, pixStatus.status);
  }
}

Either<String, DepositStatus> parseDepositStatus(String status) {
  switch (status) {
    case "pending":
      return right(DepositStatus.pending);
    case "processing":
      return right(DepositStatus.processing);
    case "expired":
      return right(DepositStatus.expired);
    case "finished":
      return right(DepositStatus.finished);
    default:
      return left("Invalid status");
  }
}
