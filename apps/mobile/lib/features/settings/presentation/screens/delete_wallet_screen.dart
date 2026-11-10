import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/delete_wallet/delete_wallet_sign.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/shared/authentication/providers.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';

class DeleteWalletScreen extends ConsumerStatefulWidget {
  const DeleteWalletScreen({super.key});

  @override
  ConsumerState<DeleteWalletScreen> createState() => _DeleteWalletScreenState();
}

class _DeleteWalletScreenState extends ConsumerState<DeleteWalletScreen> {
  bool _trustAware = false;
  bool _recoveryAware = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final confirmed = _trustAware && _recoveryAware;
    return SettingsPageScaffold(
      title: t.delete_wallet_title,
      bottomAction: PrimaryButton(
        text: t.delete_wallet_button,
        onPressed: confirmed ? () => _verifyAndDeleteWallet(context) : null,
        isEnabled: confirmed,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SettingsPageScaffold.gutter,
          16,
          SettingsPageScaffold.gutter,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleAndSubtitleCreateWallet(
              title: t.delete_wallet_warning_title,
              highlighted: t.delete_wallet_word,
              subtitle: t.delete_wallet_warning_subtitle,
            ),
            const SizedBox(height: 24),
            // Both risks sit in one panel. The button stays off until the
            // user confirms each of them.
            GlassPanel(
              child: Column(
                children: [
                  DeleteWalletSign(
                    title: t.delete_wallet_pix_limits_title,
                    description: t.delete_wallet_pix_limits_desc,
                    isSelected: _trustAware,
                    onTap: () => setState(() => _trustAware = !_trustAware),
                  ),
                  const PanelDivider(indent: 16),
                  DeleteWalletSign(
                    title: t.delete_wallet_funds_loss_title,
                    description: t.delete_wallet_funds_loss_desc,
                    isSelected: _recoveryAware,
                    onTap: () =>
                        setState(() => _recoveryAware = !_recoveryAware),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyAndDeleteWallet(BuildContext context) {
    final t = AppLocalizations.of(context);
    final verifyPinArgs = VerifyPinArgs(
      onPinConfirmed: () async {
        final navigator = Navigator.of(context);

        try {
          // Show loading indicator using captured navigator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const PopScope(
              canPop: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          );

          ref.invalidate(pixRepositoryProvider);

          final controller = await ref.read(
            appLifecycleControllerProvider.future,
          );
          final result = await controller.deleteWalletAndReimport();

          // Close loading dialog using captured navigator
          navigator.pop();

          final success = result.isRight();
          if (success) {
            ref.invalidate(mnemonicProvider);
            // The core forgets the identity of the deleted mnemonic.
            await ref.read(sessionManagerServiceProvider).resetIdentity().run();
            ref.invalidate(sessionManagerServiceProvider);
            ref.invalidate(authenticatedClientProvider);
            ref.invalidate(pixRepositoryProvider);
            ref.invalidate(userDataProvider);
            ref.invalidate(balanceCacheProvider);
            ref.invalidate(transactionHistoryCacheProvider);
            // Drop the V2 cache-first balance state and force the walletId to
            // be regenerated, so the next wallet starts from an empty snapshot
            // and never sees the deleted wallet's persisted balances.
            ref.invalidate(walletIdProvider);
            ref.invalidate(allBalancesProvider);

            // The delete also reset the onboarding: the app starts over as
            // on its first launch.
            if (context.mounted) {
              context.go('/setup/onboarding');
            }
          } else {
            if (context.mounted) {
              AppSnackBar.error(context, t.delete_wallet_error);
            }
          }
        } catch (e) {
          // Close loading dialog if it's open
          try {
            navigator.pop();
          } catch (_) {
            // Dialog may already be closed
          }

          if (context.mounted) {
            AppSnackBar.error(context, t.error_unexpected(e.toString()));
          }
        }
      },
      forceAuth: true,
    );
    context.push('/setup/pin/verify', extra: verifyPinArgs);
  }
}
