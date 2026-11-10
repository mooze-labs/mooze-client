import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/own_deposit_payer.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_deposit_profile_service_provider.dart';

/// Starts a deposit into the user's own wallet.
///
/// The deposit needs the document of the payer marked as "my user". Without
/// it, a sheet asks the user to register and mark it, and nothing opens.
/// Before the first deposit, the ownership notice opens first.
Future<void> openOwnPixDeposit(BuildContext context, WidgetRef ref) async {
  final own = await readOwnDepositPayer(ref);
  if (!context.mounted) return;
  if (own == null) return showOwnPayerRequiredSheet(context);

  final profile = ref.read(pixDepositProfileServiceProvider);
  context.push(
    profile.hasAcknowledgedOwnershipNotice()
        ? '/pix/deposit'
        : '/pix/deposit/cpf',
  );
}
