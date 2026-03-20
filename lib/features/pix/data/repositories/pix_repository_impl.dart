import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_api.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

import '../datasources/pix_deposit_db.dart';
import '../models.dart';

class PixRepositoryImpl implements PixRepository {
  final Dio _dio;
  final PixDepositDatabase _database;
  final PixDepositApi _api;

  final _statusUpdatesController = StreamController<PixStatusEvent>.broadcast();

  @override
  Stream<PixStatusEvent> get statusUpdates => _statusUpdatesController.stream;

  PixRepositoryImpl(Dio dio, PixDepositDatabase database)
    : _dio = dio,
      _database = database,
      _api = PixDepositApi(dio);

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
          .addNewDeposit(
            response.depositId,
            response.qrCopyPaste,
            asset.id,
            amountInCents,
          )
          .map((_) {
            // NOTE: Currently using polling due to issues with the API's SSE
            // When SSE is working, replace it with:

            // _subscribeToStatusUpdates(response.depositId)
            //     .timeout(Duration(minutes: 20))
            //     .listen(
            //       (statusUpdate) => statusUpdate.fold((error) => {}, (update) {
            //         _statusUpdatesController.add(update);
            //         _updateTransactionStatus(update).run();
            //       }),
            //       onError: (error) {
            //         if (error is TimeoutException) {
            //           final expiredEvent = PixStatusEvent(
            //             depositId: response.depositId,
            //             status: "expired",
            //           );
            //           _statusUpdatesController.add(expiredEvent);
            //           _updateTransactionStatus(expiredEvent).run();
            //         }
            //       },
            //     );

            // For now, uses polling as a fallback

            // Notify listeners that a new deposit was added
            _statusUpdatesController.add(
              PixStatusEvent(
                depositId: response.depositId,
                status: DepositStatus.pending,
              ),
            );

            _startPollingPixStatus(response.depositId);

            return PixDeposit(
              depositId: response.depositId,
              pixKey: response.qrCopyPaste,
              asset: asset,
              amountInCents: amountInCents,
              createdAt: DateTime.now(),
              network: network,
              status: DepositStatus.pending,
            );
          }),
    );
  }

  void _startPollingPixStatus(String depositId) {
    const pollingInterval = Duration(seconds: 30);
    const maxDuration = Duration(minutes: 20);
    final startTime = DateTime.now();

    Timer.periodic(pollingInterval, (timer) {
      final elapsed = DateTime.now().difference(startTime);

      if (elapsed > maxDuration) {
        timer.cancel();

        final expiredEvent = PixStatusEvent(
          depositId: depositId,
          status: DepositStatus.expired,
        );
        _statusUpdatesController.add(expiredEvent);
        _updateTransactionStatus(expiredEvent).run();
        return;
      }

      _api.getDeposits([depositId]).run().then((result) {
        result.fold(
          (error) {
            // error in polling
          },
          (deposits) {
            if (deposits.isEmpty) {
              timer.cancel();
              return;
            }
            final deposit = deposits.first;
            final parsedStatus = DepositStatus.fromString(deposit.status);
            if (parsedStatus != DepositStatus.pending) {
              final statusEvent = PixStatusEvent(
                depositId: depositId,
                status: parsedStatus,
                assetAmount: deposit.assetAmount,
                blockchainTxid: deposit.blockchainTxid,
              );

              _statusUpdatesController.add(statusEvent);
              _updateTransactionStatus(statusEvent).run();
              timer.cancel();
            }
          },
        );
      });
    });
  }

  @override
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId) {
    return _database
        .getDeposit(depositId)
        .flatMap(
          (f) => f.fold(
            () => TaskEither.right(Option<PixDeposit>.none()),
            (f) => TaskEither.right(
              Option.of(
                PixDeposit(
                  depositId: f.depositId,
                  pixKey: f.pixKey,
                  amountInCents: f.amountInCents,
                  asset: Asset.fromId(f.assetId),
                  network: "liquid",
                  status: DepositStatus.fromString(f.status),
                  createdAt: f.createdAt,
                  blockchainTxid: f.blockchainTxid,
                  assetAmount: f.assetAmount,
                ),
              ),
            ),
          ),
        );
  }

  @override
  TaskEither<String, List<PixDeposit>> updateDepositDetails(List<String> ids) {
    return _api.getDeposits(ids).flatMap((detailList) {
      final updateTasks =
          detailList
              .map(
                (d) => _database.updateDeposit(
                  d.id,
                  d.status,
                  assetAmount:
                      (d.assetAmount != null)
                          ? BigInt.from(d.assetAmount!)
                          : BigInt.zero,
                  blockchainTxid: d.blockchainTxid,
                ),
              )
              .toList();

      return TaskEither.sequenceList(updateTasks).flatMap(
        (_) => getDeposits().map(
          (deposits) =>
              deposits.where((d) => ids.contains(d.depositId)).toList(),
        ),
      );
    });
  }

  @override
  TaskEither<String, List<PixDeposit>> getDeposits({int? limit, int? offset}) {
    return _database
        .getDeposits(limit: limit, offset: offset)
        .flatMap(
          (deposits) => TaskEither.fromEither(
            deposits
                .map(
                  (deposit) => Either.tryCatch(
                    () => PixDeposit(
                      depositId: deposit.depositId,
                      pixKey: deposit.pixKey,
                      amountInCents: deposit.amountInCents,
                      asset: Asset.fromId(deposit.assetId),
                      network: "liquid",
                      status: DepositStatus.fromString(deposit.status),
                      createdAt: deposit.createdAt,
                      blockchainTxid: deposit.blockchainTxid,
                      assetAmount: deposit.assetAmount,
                    ),
                    (error, _) =>
                        "Invalid asset ID '${deposit.assetId}' for deposit ${deposit.depositId}: $error",
                  ),
                )
                .fold<Either<String, List<PixDeposit>>>(
                  right(<PixDeposit>[]),
                  (acc, depositEither) => acc.flatMap(
                    (deposits) =>
                        depositEither.map((deposit) => [...deposits, deposit]),
                  ),
                ),
          ),
        );
  }

  // TODO: Reactivate when SSE is working in the API
  // Method kept commented for future use with Server-Sent Events
  /*
  Stream<Either<String, PixStatusEvent>> _subscribeToStatusUpdates(
    String pixId,
  ) async* {
    final controller = StreamController<Either<String, PixStatusEvent>>();
    final baseUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: 'https://api.mooze.app',
    );

    final sseUrl = "$baseUrl/subscribe?event_type=transaction&event_id=$pixId";
    print("🔗 Connecting to SSE: $sseUrl");

    final sessionResult = await _sessionManager.getSession().run();

    await sessionResult.fold(
      (error) async {
        print("Failed to get session: $error");
        controller.add(Left("Authentication failed: $error"));
        controller.close();
      },
      (session) async {
        print("Got JWT token, connecting...");

        final eventChannel = EventFlux.spawn();
        eventChannel.connect(
          EventFluxConnectionType.get,
          sseUrl,
          tag: 'pix-status-update-stream',
          header: {'Authorization': 'Bearer ${session.jwt}'},
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
            print("SSE Connection error: $error");
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
      },
    );

    yield* controller.stream.map(
      (either) => either.fold(
        (error) => Either.left(error.toString()),
        (update) => Either.right(update),
      ),
    );
  }
  */

  TaskEither<String, PixDepositResponse> _requestNewPixDeposit(
    int amountInCents,
    String address,
    Asset asset,
    String network,
  ) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post(
          '/transactions',
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

        final jsonResponse = response.data;
        final pixResponse = PixDepositResponse.fromJson(jsonResponse['data']);
        return pixResponse;
      },
      (error, stackTrace) {
        if (error is DioException) {
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout) {
            return "Não foi possível conectar ao servidor. Verifique sua conexão com a internet e tente novamente.";
          }

          if (error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            return "O servidor demorou muito para responder. Tente novamente.";
          }

          if (error.response?.statusCode != null) {
            final statusCode = error.response!.statusCode!;
            switch (statusCode) {
              case 400:
                return "Dados inválidos. Verifique o valor e tente novamente.";
              case 401:
                return "Erro ao processar sua solicitação. Tente novamente.";
              case 403:
                return "Você não tem permissão para realizar esta operação.";
              case 404:
                return "Serviço não encontrado. Entre em contato com o suporte.";
              case 500:
              case 502:
              case 503:
              case 504:
                return "O servidor está temporariamente indisponível. Tente novamente em alguns instantes.";
              default:
                return "Erro $statusCode: ${error.response?.statusMessage ?? 'Falha ao conectar com o servidor'}";
            }
          }
        }

        return "Não foi possível processar sua solicitação. Verifique sua conexão e tente novamente.";
      },
    );
  }

  TaskEither<String, Unit> _updateTransactionStatus(PixStatusEvent pixStatus) {
    return _database.updateDeposit(
      pixStatus.depositId,
      pixStatus.status.toApiString,
      assetAmount:
          pixStatus.assetAmount != null
              ? BigInt.from(pixStatus.assetAmount!)
              : null,
      blockchainTxid: pixStatus.blockchainTxid,
    );
  }
}
