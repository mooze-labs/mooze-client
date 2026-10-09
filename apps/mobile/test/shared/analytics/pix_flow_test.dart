import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/controllers/pix_deposit_controller.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class _Repository extends Mock implements PixRepository {}

void main() {
  test(
    'PIX creation reports request outcome, not settlement, and keeps sensitive data local',
    () async {
      final repo = _Repository();
      final events = <AnalyticsEvent>[];
      final deposit = PixDeposit(
        depositId: 'private-id',
        pixKey: 'private-code',
        asset: Asset.depix,
        amountInCents: 1234,
        network: 'liquid',
        status: DepositStatus.pending,
        createdAt: DateTime(2026),
      );
      when(
        () => repo.newDeposit(
          1234,
          asset: Asset.depix,
          taxIdNumber: 'private-cpf',
        ),
      ).thenReturn(TaskEither.right(deposit));
      final controller = PixDepositController(repo, track: events.add);
      final task = controller.newDeposit(
        1234,
        Asset.depix,
        taxIdNumber: 'private-cpf',
      );
      expect(events, isEmpty); // Lazy tasks don't count until executed.
      final result = await task.run();
      expect(result.getRight().toNullable(), same(deposit));
      expect(events.map((e) => e.name), [
        'pix_request_started',
        'pix_request_created',
      ]);
      expect(events.map((e) => e.properties), [{}, {}]);

      when(
        () => repo.newDeposit(
          1234,
          asset: Asset.depix,
          taxIdNumber: 'private-cpf',
        ),
      ).thenReturn(TaskEither.left('private server error'));
      final failed = await controller
          .newDeposit(1234, Asset.depix, taxIdNumber: 'private-cpf')
          .run();
      expect(failed.getLeft().toNullable(), 'private server error');
      expect(events.skip(2).map((e) => e.name), [
        'pix_request_started',
        'pix_request_failed',
      ]);
      expect(events.last.properties, isEmpty);
    },
  );
}
