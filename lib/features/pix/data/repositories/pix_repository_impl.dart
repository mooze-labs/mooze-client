import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventflux/eventflux.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repository.dart';

import '../datasources/pix_deposit_db.dart';

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
      (pixDeposit) => _database
          .addNewDeposit(pixDeposit.id, asset.id, amountInCents)
          .map((_) {
            // Start background subscription to status updates
            subscribeToStatusUpdates(pixDeposit.id)
                .timeout(Duration(minutes: 20))
                .listen(
              (statusUpdate) => statusUpdate.fold(
                (error) => {}, // Handle errors silently
                (update) => _updateTransactionStatus(update).run(),
              ),
              onError: (error) {
                if (error is TimeoutException) {
                  _updateTransactionStatus(PixStatusUpdate(
                    id: pixDeposit.id,
                    status: "expired",
                  )).run();
                }
              },
            );
            return pixDeposit;
          }),
    );
  }

  @override
  Stream<Either<String, PixStatusUpdate>> subscribeToStatusUpdates(
    String pixId,
  ) {
    final controller = StreamController<Either<String, PixStatusUpdate>>();
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
            final update = PixStatusUpdate.fromJson(jsonDecode(data.data));
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

  TaskEither<String, PixDeposit> _requestNewPixDeposit(
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

      return PixDeposit.fromJson(response.data);
    }, (error, stackTrace) => "Erro ao gerar QR code: $error");
  }

  TaskEither<String, Unit> _updateTransactionStatus(PixStatusUpdate pixStatus) {
    return _database.updateDepositStatus(pixStatus.id, pixStatus.status);
  }
}
