import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/delete_wallet/delete_wallet_sign.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/utils/mnemonic.dart';
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
        final mnemonicHandler = MnemonicHandler();
        await mnemonicHandler.deleteMnemonic("mainWallet");

        // Invalidate seed/mnemonic providers
        ref.invalidate(mnemonicProvider);
        ref.invalidate(bdkDatasourceProvider);
        ref.invalidate(liquidDataSourceProvider);
        ref.invalidate(breezClientProvider);
        ref.invalidate(walletRepositoryProvider);
        ref.invalidate(transactionControllerProvider);
        ref.invalidate(transactionHistoryProvider);

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

        await Future.delayed(const Duration(milliseconds: 100));

        if (context.mounted) {
          context.go('/setup/first-access');
        }
      },
      forceAuth: true,
    );
    context.push('/setup/pin/verify', extra: verifyPinArgs);
  }
}
