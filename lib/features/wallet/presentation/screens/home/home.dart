import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/widgets/asset_section.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/widgets/section_header.dart';

import 'consts.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LogoHeader(),
                _buildWalletSection(),
                _buildActionButtons(),
                const SizedBox(height: 32),
                AssetSection(),
                SectionHeader(
                  onAction: () => (),
                  title: "Transações",
                  actionDescription: "Ver mais",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildWalletSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      WalletHeader(),
      const SizedBox(height: 15),
      WalletBalanceDisplay(),
      const SizedBox(height: 25),
    ],
  );
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: ReceiveButton()),
          const SizedBox(width: cardSpacing),
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
