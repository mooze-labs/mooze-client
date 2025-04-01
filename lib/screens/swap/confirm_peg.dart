import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/external/mempool_repository_provider.dart';
import 'package:mooze_mobile/providers/peg_operation_provider.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_wallet_repository_provider.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/screens/swap/check_peg_status.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_address_qr_code.dart';
import 'package:mooze_mobile/screens/swap/widgets/peg_details.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class ConfirmPegScreen extends ConsumerStatefulWidget {
  final bool pegIn;
  final bool sendFromExternalWallet;
  final int minAmount;
  final String? address;
  final double? sendAmount;
  final OwnedAsset? ownedAsset;

  const ConfirmPegScreen({
    super.key,
    required this.pegIn,
    required this.minAmount,
    this.address,
    this.sendFromExternalWallet = false,
    this.sendAmount,
    this.ownedAsset,
  });

  @override
  ConsumerState<ConfirmPegScreen> createState() => _ConfirmPegScreenState();
}

class _ConfirmPegScreenState extends ConsumerState<ConfirmPegScreen> {
  String? address;
  Future<PegOrderResponse?>? _pegResponseFuture;
  PartiallySignedTransaction? _preparedTransaction;
  bool _isTransactionPreparing = false;

  @override
  void initState() {
    super.initState();
    _pegResponseFuture = _requestPeg();

    // If we're not using an external wallet, prepare the transaction
    if (!widget.sendFromExternalWallet &&
        widget.ownedAsset != null &&
        widget.sendAmount != null) {
      _prepareTransaction();
    }
  }

  Future<void> _prepareTransaction() async {
    setState(() {
      _isTransactionPreparing = true;
    });

    try {
      // Wait for the peg response to complete
      final pegResponse = await _pegResponseFuture;

      // Check if we have a valid response and the widget is still mounted
      if (pegResponse != null && mounted) {
        // Build the transaction
        final pst = await buildPartiallySignedTransaction(pegResponse);

        if (mounted) {
          setState(() {
            _preparedTransaction = pst;
            _isTransactionPreparing = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isTransactionPreparing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing transaction: $e')),
        );
        setState(() {
          _isTransactionPreparing = false;
        });
      }
    }
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

  Future<PartiallySignedTransaction> buildPartiallySignedTransaction(
    PegOrderResponse pegResponse,
  ) async {
    final wallet =
        (widget.pegIn)
            ? ref.read(bitcoinWalletRepositoryProvider)
            : ref.read(liquidWalletRepositoryProvider);

    if (widget.ownedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao acessar sua carteira. Tente novamente mais tarde',
          ),
        ),
      );
    }

    if (widget.sendAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Valor inserido é inválido. Você pode fazer um depósito por uma carteira externa.',
          ),
        ),
      );
    }

    final mempoolRepository = ref.watch(
      mempoolRepositoryProvider(widget.ownedAsset!.asset.network),
    );
    final recommendedFees = await mempoolRepository.getRecommendedFees();
    final feeRate = recommendedFees.halfHourFee.toDouble();

    final satoshiAmount = (widget.sendAmount! * pow(10, 8)).toInt();
    final pst = await wallet.buildPartiallySignedTransaction(
      widget.ownedAsset!,
      pegResponse.pegAddress,
      satoshiAmount,
      feeRate,
    );

    return pst;
  }

  Future<void> onPegConfirm(
    PartiallySignedTransaction pst,
    String orderId,
    bool pegIn,
  ) async {
    final wallet =
        (pegIn)
            ? ref.read(bitcoinWalletRepositoryProvider)
            : ref.read(liquidWalletRepositoryProvider);

    final tx = await wallet.signTransaction(pst);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fundos enviados para peg-out.\nID: ${tx.txid}'),
          action: SnackBarAction(
            label: "Copiar ID",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: tx.txid));
            },
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => CheckPegStatusScreen(pegIn: pegIn, orderId: orderId),
        ),
      );
    }
  }

  Future<void> onTap(PegOrderResponse pegResponse) async {
    // Save the peg operation to persistence
    await ref
        .read(activePegOperationProvider.notifier)
        .startPegOperation(pegResponse.orderId, widget.pegIn);

    if (widget.sendFromExternalWallet) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CheckPegStatusScreen(
                pegIn: widget.pegIn,
                orderId: pegResponse.orderId,
              ),
        ),
      );
      return;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => VerifyPinScreen(
                onPinConfirmed: () async {
                  // Use the pre-prepared transaction if available
                  final pst =
                      _preparedTransaction ??
                      await buildPartiallySignedTransaction(pegResponse);
                  await onPegConfirm(pst, pegResponse.orderId, widget.pegIn);
                },
              ),
        ),
      );
    }
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
        future: _pegResponseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao gerar ordem: ${snapshot.error}'),
            );
          }
          if (snapshot.data == null) {
            return Center(child: Text('Não foi possível criar a ordem'));
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
                    destinationAddress: address!,
                  ),

                  SizedBox(height: 24),
                  _isTransactionPreparing
                      ? DeactivatedButton(text: "Preparando...")
                      : PrimaryButton(
                        text:
                            (widget.sendFromExternalWallet
                                ? "Ver status"
                                : "Confirmar"),
                        onPressed: () => onTap(pegResponse),
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
