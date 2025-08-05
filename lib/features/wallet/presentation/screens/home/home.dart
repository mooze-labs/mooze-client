import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/widgets/asset_section.dart';

import 'consts.dart';
import 'providers.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _configureSystemUi();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(bottom: false,
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
                ],
              )
            ),
          ))
    );
  }
}

Widget _buildWalletSection() {
  return Column(
    children: [WalletHeader(), WalletBalanceDisplay(), const SizedBox(height: 24)],
  );
}

Widget _buildActionButtons() {
  return Column(
    children: [
      Row(children: [
        Expanded(child: ReceiveButton()),
        const SizedBox(width: cardSpacing),
        Expanded(child: SendButton())
      ])
    ],
  );
}

void _configureSystemUi() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark
    )
  );
}