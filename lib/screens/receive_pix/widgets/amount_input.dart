import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/mooze/user_provider.dart';
import 'package:mooze_mobile/models/user.dart';

class PixInputAmount extends ConsumerStatefulWidget {
  final TextEditingController amountController;
  final Function(String)? onChanged;

  const PixInputAmount({
    super.key,
    required this.amountController,
    this.onChanged,
  });

  @override
  ConsumerState<PixInputAmount> createState() => _PixInputAmountState();
}

class _PixInputAmountState extends ConsumerState<PixInputAmount> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = ref.read(userServiceProvider);

    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Valor do PIX",
            style: TextStyle(fontFamily: "roboto", fontSize: 20),
          ),
          SizedBox(
            width: 250,
            child: TextField(
              controller: widget.amountController,
              onChanged: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
              },
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: "R\$",
                prefixStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: "roboto",
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: "roboto",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              maxLines: 1,
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<User?>(
            future: userService.getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("");
              }

              if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Limite diário indisponível.");
              }

              if (snapshot.data == null) {
                print("Problema de conexão.");
                return Text("Limite diário indisponível.");
              }

              final user = snapshot.data!;

              if (user.isFirstTransaction) {
                return Text(
                  "Limite de primeira transação: R\$ 250",
                  style: TextStyle(fontFamily: "roboto", fontSize: 16),
                );
              }

              return Text(
                "Limite diário restante: R\$ ${5000 - user.dailySpending * 100}",
                style: TextStyle(fontFamily: "roboto", fontSize: 16),
              );
            },
          ),
        ],
      ),
    );
  }
}
