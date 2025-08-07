import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';
import 'package:mooze_mobile/screens/send_funds/transaction_sent.dart';
import 'package:mooze_mobile/screens/send_funds/widgets/transaction_info.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class ConfirmSendTransactionScreen extends ConsumerStatefulWidget {
  final OwnedAsset ownedAsset;
  final String address;
  final int amount;
  final int fees;

  const ConfirmSendTransactionScreen({
    super.key,
    required this.ownedAsset,
    required this.address,
    required this.amount,
    required this.fees,
  });

  @override
  ConsumerState<ConfirmSendTransactionScreen> createState() =>
      ConfirmSendTransactionState();
}

class ConfirmSendTransactionState
    extends ConsumerState<ConfirmSendTransactionScreen> {
  PartiallySignedTransaction? _partiallySignedTransaction;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pst = await generatePartiallySignedTransaction();
      setState(() {
        _partiallySignedTransaction = pst;
        _isLoading = false;
      });
    } on bdk.InsufficientFundsException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Fundos insuficientes para cobrir transação + taxas.",
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<PartiallySignedTransaction>
  generatePartiallySignedTransaction() async {
    final signer =
        (widget.ownedAsset.asset.network == Network.bitcoin)
            ? ref.read(bitcoinSignerRepositoryProvider)
            : ref.read(liquidSignerRepositoryProvider);

    final pst = await signer.buildPartiallySignedTransaction(
      widget.address,
      widget.amount - 1,
      feeRate: widget.fees.toDouble(),
    );

    return pst;
  }

  Future<Transaction> signTransaction() async {
    final signer =
        (widget.ownedAsset.asset.network == Network.bitcoin)
            ? ref.read(bitcoinSignerRepositoryProvider)
            : ref.read(liquidSignerRepositoryProvider);

    final transaction = await signer.signTransaction(
      _partiallySignedTransaction!,
    );
    if (kDebugMode) {
      debugPrint(transaction.txid);
    }
    return transaction;
  }

  Future<void> signAndRedirect() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => VerifyPinScreen(
                onPinConfirmed: () async {
                  try {
                    final transaction = await signTransaction();
                    if (kDebugMode) {
                      debugPrint(transaction.txid);
                    }
                    if (mounted) {
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TransactionSentScreen(
                                transaction: transaction,
                                amount: widget.amount,
                              ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Não foi possível assinar a transação: $e",
                          ),
                        ),
                      );
                    }
                  }
                },
                forceAuth: true,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(
        title: "Confirmar transação",
        action: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pushNamed(context, "/wallet"),
        ),
      ),
      body: Center(
        child: Padding(padding: EdgeInsets.all(16), child: buildView()),
      ),
    );
  }

  Widget buildView() {
    if (_isLoading) return CircularProgressIndicator();
    if (_errorMessage != null) return _buildErrorView();
    return _buildConfirmView();
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Erro ao gerar transação",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 16),
        Text(_errorMessage ?? "Erro desconhecido"),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loadTransaction,
          child: Text("Tentar novamente"),
        ),
      ],
    );
  }

  Widget _buildConfirmView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TransactionInfo(
          address: widget.address,
          amount: widget.amount,
          asset: widget.ownedAsset.asset,
          feeRate: _partiallySignedTransaction!.feeAmount!,
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: SwipeToConfirm(
            text: "Confirmar envio",
            onConfirm: () async => await signAndRedirect(),
          ),
        ),
      ],
    );
  }
}
