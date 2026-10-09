import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/product_flows.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class PixDepositController {
  final PixRepository _pixRepository;

  final void Function(AnalyticsEvent) _track;
  final void Function(PixDeposit)? _observe;
  PixDepositController(
    PixRepository pixRepository, {
    void Function(AnalyticsEvent)? track,
    void Function(PixDeposit)? observe,
  }) : _pixRepository = pixRepository,
       _track = track ?? ((_) {}),
       _observe = observe;

  /// Creates a deposit that pays to a new Liquid wallet address. The core
  /// generates the address.
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    Asset asset, {
    String? taxIdNumber,
  }) {
    return TaskEither(() async {
      final result = await trackOperation(
        track: _track,
        started: const AnalyticsEvent('pix_request_started', {}),
        failed: const AnalyticsEvent('pix_request_failed', {}),
        outcome: (value) => AnalyticsEvent(
          value.isRight() ? 'pix_request_created' : 'pix_request_failed',
          const {},
        ),
        run: () => _pixRepository
            .newDeposit(amountInCents, asset: asset, taxIdNumber: taxIdNumber)
            .run(),
      );
      result.map((deposit) {
        _observe?.call(deposit);
        return deposit;
      });
      return result;
    });
  }

  TaskEither<String, PixDeposit> getDeposit(String depositId) {
    return _pixRepository
        .getDeposit(depositId)
        .flatMap(
          (optionDeposit) => optionDeposit.fold(
            () =>
                TaskEither<String, PixDeposit>.left("Depósito não encontrado"),
            (deposit) {
              _observe?.call(deposit);
              return TaskEither.right(deposit);
            },
          ),
        );
  }
}
