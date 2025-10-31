import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventflux/eventflux.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_api.dart';
import 'package:mooze_mobile/shared/authentication/services/session_manager_service.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

import '../datasources/pix_deposit_db.dart';
import '../models.dart';

class PixRepositoryImpl implements PixRepository {
  final Dio _dio;
  final PixDepositDatabase _database;
  final PixDepositApi _api;
  final SessionManagerService _sessionManager;

  final _statusUpdatesController = StreamController<PixStatusEvent>.broadcast();

  Stream<PixStatusEvent> get statusUpdates => _statusUpdatesController.stream;

  PixRepositoryImpl(
    Dio dio,
    PixDepositDatabase database,
    SessionManagerService sessionManager,
  ) : _dio = dio,
      _database = database,
      _api = PixDepositApi(dio),
      _sessionManager = sessionManager;

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
            _subscribeToStatusUpdates(response.depositId)
                .timeout(Duration(minutes: 20))
                .listen(
                  (statusUpdate) => statusUpdate.fold(
                    (error) => {},
                    (update) {
                      _statusUpdatesController.add(update);
                      _updateTransactionStatus(update).run();
                    },
                  ),
                  onError: (error) {
                    if (error is TimeoutException) {
                      final expiredEvent = PixStatusEvent(
                        depositId: response.depositId,
                        status: "expired",
                      );
                      _statusUpdatesController.add(expiredEvent);
                      _updateTransactionStatus(expiredEvent).run();
                    }
                  },
                );

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

  @override
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId) {
    final deposit = _database
        .getDeposit(depositId)
        .flatMap(
          (f) => f.fold(
            () => TaskEither.right(Option<PixDeposit>.none()),
            (f) => TaskEither.fromEither(parseDepositStatus(f.status)).flatMap(
              (s) => TaskEither.right(
                Option.of(
                  PixDeposit(
                    depositId: f.depositId,
                    pixKey: f.pixKey,
                    amountInCents: f.amountInCents,
                    asset: Asset.fromId(f.assetId),
                    network: "liquid",
                    status: s,
                    createdAt: f.createdAt,
                    blockchainTxid: f.blockchainTxid,
                    assetAmount: f.assetAmount,
                  ),
                ),
              ),
            ),
          ),
        );

    return deposit;
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
                  (deposit) => parseDepositStatus(deposit.status)
                      .flatMap(
                        (status) => Either.tryCatch(
                          () => PixDeposit(
                            depositId: deposit.depositId,
                            pixKey: deposit.pixKey,
                            amountInCents: deposit.amountInCents,
                            asset: Asset.fromId(deposit.assetId),
                            network: "liquid",
                            status: status,
                            createdAt: deposit.createdAt,
                            blockchainTxid: deposit.blockchainTxid,
                            assetAmount: deposit.assetAmount,
                          ),
                          (error, _) =>
                              "Invalid asset ID '${deposit.assetId}' for deposit ${deposit.depositId}: $error",
                        ),
                      )
                      .mapLeft(
                        (error) =>
                            "Invalid deposit status '${deposit.status}' for deposit ${deposit.depositId}: $error",
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

  Stream<Either<String, PixStatusEvent>> _subscribeToStatusUpdates(
    String pixId,
  ) async* {
    final controller = StreamController<Either<String, PixStatusEvent>>();
    final baseUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: 'http://10.0.2.2:3000',
    );

    final sseUrl = "$baseUrl/subscribe?event_type=transaction&event_id=$pixId";
    print("🔗 Connecting to SSE: $sseUrl");

    final sessionResult = await _sessionManager.getSession().run();

    await sessionResult.fold(
      (error) async {
        print("❌ Failed to get session: $error");
        controller.add(Left("Authentication failed: $error"));
        controller.close();
      },
      (session) async {
        print("✅ Got JWT token, connecting...");

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
            print("❌ SSE Connection error: $error");
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

  TaskEither<String, PixDepositResponse> _requestNewPixDeposit(
    int amountInCents,
    String address,
    Asset asset,
    String network,
  ) {
    return TaskEither.tryCatch(() async {
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
      return PixDepositResponse.fromJson(jsonResponse['data']);
    }, (error, stackTrace) => "Falha ao conectar com o servidor $error");
  }

  TaskEither<String, Unit> _updateTransactionStatus(PixStatusEvent pixStatus) {
    return _database.updateDeposit(
      pixStatus.depositId,
      pixStatus.status,
      assetAmount:
          pixStatus.assetAmount != null
              ? BigInt.from(pixStatus.assetAmount!)
              : null,
      blockchainTxid: pixStatus.blockchainTxid,
    );
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