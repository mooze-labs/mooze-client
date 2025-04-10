import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/models/transaction.dart';
import 'package:mooze_mobile/providers/wallet/network_wallet_repository_provider.dart';
import 'package:mooze_mobile/screens/confirm_send_transaction/widgets/sent_transaction_info.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionSentScreen extends ConsumerStatefulWidget {
  final Transaction transaction;
  final int amount;

  const TransactionSentScreen({
    Key? key,
    required this.transaction,
    required this.amount,
  }) : super(key: key);

  @override
  _TransactionSentScreenState createState() => _TransactionSentScreenState();
}

class _TransactionSentScreenState extends ConsumerState<TransactionSentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(
        title: 'Detalhes da transação',
        action: IconButton(
          icon: Icon(Icons.home),
          onPressed: () => Navigator.pushNamed(context, "/wallet"),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SentTransactionInfo(
                    address: widget.transaction.destinationAddress,
                    asset: widget.transaction.asset,
                    feeRate: widget.transaction.feeAmount,
                    amount: widget.amount,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "ID da transação: ",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.transaction.txid,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 14.5,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.transaction.txid),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "ID copiado para a área de transferência",
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.content_copy_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: PrimaryButton(
                text: "Abrir no navegador",
                onPressed: () {
                  if (widget.transaction.network == Network.liquid) {
                    launchUrl(
                      Uri.parse(
                        'https://liquid.network/pt/tx/${widget.transaction.txid}',
                      ),
                    );
                    return;
                  } else {
                    launchUrl(
                      Uri.parse(
                        "https://mempool.space/tx/${widget.transaction.txid}",
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
