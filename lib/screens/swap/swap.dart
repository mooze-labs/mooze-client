import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import 'package:mooze_mobile/screens/swap/swap_confirm.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_balance.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_card.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_asset_row.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_change_directions.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_peg_warn.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class SideswapScreen extends ConsumerStatefulWidget {
  const SideswapScreen({super.key});

  @override
  ConsumerState<SideswapScreen> createState() => _SideswapScreenState();
}

class _SideswapScreenState extends ConsumerState<SideswapScreen> {
  @override
  void initState() {
    super.initState();
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.ensureConnection();
    sideswap.stopQuotes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(sideswapRepositoryProvider).stopQuotes();
        }
      },
      child: Scaffold(
        appBar: MoozeAppBar(title: 'Swap'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Você envia",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  SendAssetRow(),
                  SizedBox(height: 4),
                  SendAssetBalance(),
                ],
              ),
              SizedBox(height: 16),
              SwapChangeDirections(),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Você recebe",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  ReceiveAssetRow(),
                  SizedBox(height: 4),
                  ReceiveAssetBalance(),
                ],
              ),
              Spacer(),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                PrimaryButton(
                  text: "Continuar",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SwapConfirm()),
                    );
                  },
                ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
