import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/delete_wallet/delete_wallet_sign.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/authentication/providers/session_manager_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/user_level_storage_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_data_provider.dart';
import 'package:mooze_mobile/shared/network/providers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/key_management/store/mnemonic_store_impl.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/pin_store_provider.dart';
import 'package:mooze_mobile/shared/key_management/providers/has_pin_provider.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:mooze_mobile/features/swap/di/providers/swap_repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletar carteira'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Título principal
            const TitleAndSubtitleCreateWallet(
              title: 'Atenção ao deletar sua ',
              highlighted: 'carteira',
              subtitle:
                  'Ao deletar, será necessário passar novamente pelo sistema TRUST e você perderá acesso aos fundos se não tiver salvo sua frase de recuperação.',
            ),

            const SizedBox(height: 20),
            DeleteWalletSign(
              title: 'Limites PIX',
              description:
                  'Eu estou ciente de que precisarei passar novamente pelo sistema TRUST e que meus limites de PIX serão resetados.',
              isSelected: _trustAware,
              onTap: () {
                setState(() {
                  _trustAware = !_trustAware;
                });
              },
            ),
            const SizedBox(height: 16),
            DeleteWalletSign(
              title: 'Perda de fundos',
              description:
                  'Eu estou ciente que perderei acesso aos meus fundos caso não tenha guardado minha frase de recuperação.',
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
              text: 'Deletar carteira',
              onPressed:
                  (_trustAware && _recoveryAware)
                      ? () => _verifyAndDeleteWallet(context)
                      : null,
              isEnabled: _trustAware && _recoveryAware,
            ),

            // const SizedBox(height: 20),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _verifyAndDeleteWallet(BuildContext context) {
    final verifyPinArgs = VerifyPinArgs(
      onPinConfirmed: () async {
        final secureStorage = SecureStorageProvider.instance;

        await secureStorage.delete(key: mnemonicKey);

        ref.invalidate(mnemonicProvider);
        await Future.delayed(const Duration(milliseconds: 300));

        await secureStorage.delete(key: 'jwt');
        await secureStorage.delete(key: 'refresh_token');

        ref.invalidate(sessionManagerServiceProvider);
        ref.invalidate(authenticatedClientProvider);
        ref.invalidate(ensureAuthSessionProvider);
        ref.invalidate(userDataProvider);

        await Future.delayed(const Duration(milliseconds: 500));

        try {
          final workingDir = await getApplicationDocumentsDirectory();
          final breezDir = Directory("${workingDir.path}/mooze");
          if (await breezDir.exists()) {
            await breezDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint('Error deleting Breez directory: $e');
        }

        try {
          final localDir = await getApplicationSupportDirectory();
          final lwkDir = Directory("${localDir.path}/lwk-db");
          if (await lwkDir.exists()) {
            await lwkDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint('Error deleting LWK directory: $e');
        }

        // Clear user verification level
        final prefs = await SharedPreferences.getInstance();
        final userLevelStorage = UserLevelStorageService(prefs);
        await userLevelStorage.clearVerificationLevel();

        // Delete PIN
        final pinStore = ref.read(pinStoreProvider);
        await pinStore.deletePin().run();

        // Invalidate remaining providers (mnemonic already invalidated earlier)
        ref.invalidate(hasPinProvider);
        ref.invalidate(bdkDatasourceProvider);
        ref.invalidate(liquidDataSourceProvider);
        ref.invalidate(breezClientProvider);
        ref.invalidate(walletRepositoryProvider);
        ref.invalidate(transactionControllerProvider);
        ref.invalidate(transactionHistoryProvider);

        // Invalidate swap/websocket providers to stop reconnection attempts
        ref.invalidate(sideswapServiceProvider);
        ref.invalidate(sideswapApiProvider);
        ref.invalidate(swapWalletProvider);
        ref.invalidate(swapRepositoryProvider);

        // Invalidate ALL balance-related providers
        ref.invalidate(balanceControllerProvider);
        ref.invalidate(
          allBalancesProvider,
        ); // Invalida o provider que busca os saldos

        // Invalidate balance providers for each asset individually
        final allAssets = ref.read(allAssetsProvider);
        for (final asset in allAssets) {
          ref.invalidate(balanceProvider(asset));
        }

        // Invalidate wallet providers
        ref.invalidate(walletHoldingsProvider);
        ref.invalidate(walletHoldingsWithBalanceProvider);
        ref.invalidate(totalWalletValueProvider);
        ref.invalidate(totalWalletBitcoinProvider);
        ref.invalidate(totalWalletSatoshisProvider);
        ref.invalidate(totalWalletVariationProvider);

        // Clear caches of transactions and price history
        ref.read(assetPriceHistoryCacheProvider.notifier).reset();
        ref.read(transactionHistoryCacheProvider.notifier).reset();

        // Wait before navigation to ensure all invalidations are processed
        await Future.delayed(const Duration(milliseconds: 200));

        if (context.mounted) {
          context.go('/setup/first-access');
        }
      },
      forceAuth: true,
    );
    context.push('/setup/pin/verify', extra: verifyPinArgs);
  }
}
