import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventflux/eventflux.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repository.dart';

class PixRepositoryImpl implements PixRepository {
  final Dio dio;

  PixRepositoryImpl({required this.dio});

  @override
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  }) {
    return TaskEither.tryCatch(() async {
      final response = await dio.post(
        '/transactions/deposit',
        data: {
          "address": address,
          "amount_in_cents": amountInCents,
          "asset": asset.id,
          "network": network,
        },
      );

      if (response.statusCode != 200) {
        left("Failed to create deposit: ${response.statusMessage}");
      }

      return PixDeposit.fromJson(response.data);
    }, (error, stackTrace) => throw Exception(error.toString()));
  }

  @override
  Stream<PixStatusUpdate> subscribeToStatusUpdates(String pixId) {
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
      (either) =>
          either.fold((error) => throw Exception(error), (update) => update),
    );
  }
}
