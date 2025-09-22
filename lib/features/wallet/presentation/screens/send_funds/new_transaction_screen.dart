import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';

import '../../widgets/send_funds/widgets.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  ConsumerState<NewTransactionScreen> createState() =>
      _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoValidationListener(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Enviar ativos"),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          actions: [
            OfflineIndicator(
              onTap: () => OfflinePriceInfoOverlay.show(context),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ).copyWith(top: 10, bottom: 24),
          child: Column(
            children: [
              _buildInstructionText(context),
              const SizedBox(height: 20),
              AssetSelectorWidget(),
              const SizedBox(height: 20),
              BalanceCard(),
              const SizedBox(height: 20),
              AddressField(),
              const SizedBox(height: 15),
              NetworkIndicatorWidget(),
              const SizedBox(height: 15),
              ConditionalAmountField(),
              const SizedBox(height: 15),
              DrainInfoWidget(),
              const SizedBox(height: 20),
              ValidationErrorsWidget(),
              const SizedBox(height: 20),
              ReviewButton(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildInstructionText(BuildContext context) {
  return Center(
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          const TextSpan(text: "Escolha o ativo que quer enviar na "),
          TextSpan(
            text: "Mooze",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    ),
  );
}
