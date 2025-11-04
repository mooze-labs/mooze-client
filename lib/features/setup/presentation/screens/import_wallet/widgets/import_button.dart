import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_holdings_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';

import '../providers/mnemonic_input_provider.dart';
import '../../../providers/mnemonic_controller_provider.dart';

class ImportButton extends ConsumerWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final mnemonicController = ref.watch(mnemonicControllerProvider);
    return PrimaryButton(
      text: "Importar",
      onPressed: () async {
        final result =
            await mnemonicController.saveMnemonic(mnemonicInput).run();
        result.match(
          (failure) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure))),
          (success) async {
            final allAssets = ref.read(allAssetsProvider);

            ref.invalidate(mnemonicProvider);
            ref.invalidate(bdkDatasourceProvider);
            ref.invalidate(liquidDataSourceProvider);
            ref.invalidate(breezClientProvider);
            ref.invalidate(walletRepositoryProvider);
            ref.invalidate(transactionControllerProvider);
            ref.invalidate(transactionHistoryProvider);

            ref.invalidate(balanceControllerProvider);
            ref.invalidate(
              allBalancesProvider,
            );

            for (final asset in allAssets) {
              ref.invalidate(balanceProvider(asset));
            }

            ref.invalidate(walletHoldingsProvider);
            ref.invalidate(walletHoldingsWithBalanceProvider);
            ref.invalidate(totalWalletValueProvider);
            ref.invalidate(totalWalletBitcoinProvider);
            ref.invalidate(totalWalletSatoshisProvider);
            ref.invalidate(totalWalletVariationProvider);

            debugPrint('[ImportButton] Pre-loading balances in background...');
            for (final asset in allAssets) {
              ref
                  .read(balanceProvider(asset).future)
                  .then((balance) {
                    balance.fold(
                      (error) => debugPrint(
                        '[ImportButton] Error pre-loading $asset: $error',
                      ),
                      (value) => debugPrint(
                        '[ImportButton] Pre-loaded $asset: $value',
                      ),
                    );
                  })
                  .catchError((error) {
                    debugPrint(
                      '[ImportButton] Exception pre-loading asset: $error',
                    );
                  });
            }

            if (context.mounted) {
              context.push("/setup/pin/new");
            }
          },
        );
      },
    );
  }
}
