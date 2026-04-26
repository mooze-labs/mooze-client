import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/delete_wallet/delete_wallet_sign.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

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
    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.delete_wallet_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TitleAndSubtitleCreateWallet(
                          title: t.delete_wallet_warning_title,
                          highlighted: t.delete_wallet_word,
                          subtitle: t.delete_wallet_warning_subtitle,
                        ),

                        const SizedBox(height: 20),

                        DeleteWalletSign(
                          title: t.delete_wallet_pix_limits_title,
                          description: t.delete_wallet_pix_limits_desc,
                          isSelected: _trustAware,
                          onTap: () {
                            setState(() {
                              _trustAware = !_trustAware;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        DeleteWalletSign(
                          title: t.delete_wallet_funds_loss_title,
                          description: t.delete_wallet_funds_loss_desc,
                          isSelected: _recoveryAware,
                          onTap: () {
                            setState(() {
                              _recoveryAware = !_recoveryAware;
                            });
                          },
                        ),

                        const Spacer(),

                        const SizedBox(height: 16),

                        PrimaryButton(
                          text: t.delete_wallet_button,
                          onPressed:
                              (_trustAware && _recoveryAware)
                                  ? () => _verifyAndDeleteWallet(context)
                                  : null,
                          isEnabled: _trustAware && _recoveryAware,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
            builder:
                (dialogContext) => const PopScope(
                  canPop: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
          );

          // Call centralized delete method from WalletDataManager
          final success =
              await ref.read(walletDataManagerProvider.notifier).deleteWallet();

          // Close loading dialog using captured navigator
          navigator.pop();

          if (success) {
            if (context.mounted) {
              context.go('/setup/first-access');
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
