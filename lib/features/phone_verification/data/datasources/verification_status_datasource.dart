import 'dart:async';

import 'package:eventflux/eventflux.dart';
import 'package:fpdart/fpdart.dart';

class VerificationStatusDatasource {
  final String _baseUrl = String.fromEnvironment(
    'BACKEND_API_URL',
    defaultValue: 'https://api.mooze.app/v1/',
  );

  Stream<Either<String, String>> listen(String phoneNumber) {
    final controller = StreamController<Either<String, String>>();

    final eventChannel = EventFlux.spawn();
    eventChannel.connect(
      EventFluxConnectionType.get,
      "$_baseUrl/subscribe?event_type=phone_verification&event_id=$phoneNumber",
      tag: 'phone-verification-status-stream',
      onSuccessCallback: (EventFluxResponse? response) {
        response?.stream?.listen(
          (data) {
            controller.add(Right(data.data));
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

    return controller.stream;
  }
}
