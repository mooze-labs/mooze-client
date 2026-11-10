import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The payer of the user's own deposits: the favorite payer marked as
/// "my user", or null.
///
/// It is the only source of the payer document of an own deposit. It
/// follows the favorites, so a removed payer, a removed mark or a changed
/// document reaches the next deposit. A document that fails the check
/// digits reads as no payer.
final ownDepositPayerProvider = FutureProvider<FavoritePayer?>((ref) async {
  final own = await ref.watch(ownFavoritePayerProvider.future);
  return own != null && CpfValidator.isValid(own.cpf) ? own : null;
});

/// Reads [ownDepositPayerProvider] once. Favorites that cannot be read give
/// null, so no deposit starts without a document.
Future<FavoritePayer?> readOwnDepositPayer(WidgetRef ref) async {
  try {
    return await ref.read(ownDepositPayerProvider.future);
  } catch (_) {
    return null;
  }
}

/// Asks the user to register their document and mark it as "my user"
/// before a deposit. The action opens the favorite payers.
Future<void> showOwnPayerRequiredSheet(BuildContext context) {
  final t = AppLocalizations.of(context);
  return showGlassInfoSheet(
    context,
    title: t.pix_deposit_own_payer_required_title,
    steps: [
      (
        t.pix_deposit_own_payer_step_add_title,
        t.pix_deposit_own_payer_step_add_body,
      ),
      (
        t.pix_deposit_own_payer_step_mark_title,
        t.pix_deposit_own_payer_step_mark_body,
      ),
    ],
    actionLabel: t.pix_deposit_own_payer_required_action,
    onAction: () => context.push('/favorite-payers'),
  );
}
