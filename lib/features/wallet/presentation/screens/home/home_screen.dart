import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/holding_asset/widgets/wallet_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/widgets/asset_section.dart';

import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _configureSystemUi();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LogoHeader(),
                WalletHeaderWidget(),
                const SizedBox(height: 15),
                _buildActionButtons(),
                const SizedBox(height: 32),
                AssetSection(),
                TransactionSection(),
                SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: ReceiveButton()),
          const SizedBox(width: 8),
          Expanded(child: SendButton()),
        ],
      ),
    ],
  );
}

void _configureSystemUi() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}
