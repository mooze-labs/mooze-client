import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_address_qr_code.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_details.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class ConfirmPegScreen extends ConsumerStatefulWidget {
  final bool pegIn;
  final bool sendFromExternalWallet;
  final int minAmount;
  final int maxAmount;
  final String? address;
  final double? sendAmount;

  const ConfirmPegScreen({
    super.key,
    required this.pegIn,
    required this.minAmount,
    required this.maxAmount,
    this.address,
    this.sendFromExternalWallet = false,
    this.sendAmount,
  });

  @override
  ConsumerState<ConfirmPegScreen> createState() => _ConfirmPegScreenState();
}

class _ConfirmPegScreenState extends ConsumerState<ConfirmPegScreen> {
  String? address;

  @override
  void initState() {
    super.initState();
  }

  Future<String> generateAddress() async {
    if (widget.address != null) {
      return widget.address!;
    }

    final wallet =
        (widget.pegIn)
            ? ref.read(liquidWalletRepositoryProvider)
            : ref.read(bitcoinWalletRepositoryProvider);
    final address = await wallet.generateAddress();

    return address;
  }

  Future<PegOrderResponse?> _requestPeg() async {
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    final address = await generateAddress();

    this.address = address;

    final pegResponse = await sideswapClient.startPegOperation(
      widget.pegIn,
      address,
    );

    if (pegResponse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao contatar servidor. Tente novamente mais tarde.',
            ),
          ),
        );
      }

      return null;
    }

    return pegResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(
        title: "Finalizar operação",
        action: IconButton(
          icon: Icon(Icons.check),
          onPressed: () => Navigator.pushReplacementNamed(context, "/wallet"),
        ),
      ),
      body: FutureBuilder<PegOrderResponse?>(
        future: _requestPeg(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Erro ao gerar ordem: ${snapshot.error}');
          }

          final pegResponse = snapshot.data!;

          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  PegAddressQrCode(
                    address: pegResponse.pegAddress,
                    pegIn: widget.pegIn,
                    qrSize: 200,
                  ),
                  SizedBox(height: 10),
                  if (widget.sendAmount != null)
                    Text(
                      "Envie ${widget.sendAmount} ${(widget.pegIn) ? "BTC" : "L-BTC"} para o endereço acima.",
                      style: TextStyle(fontSize: 16, fontFamily: "roboto"),
                    ),
                  SizedBox(height: 24),
                  PegDetails(
                    orderId: pegResponse.orderId,
                    pegIn: widget.pegIn,
                    minAmount: widget.minAmount,
                    hotWalletAmount: widget.maxAmount,
                    destinationAddress: address!,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
