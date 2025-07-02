import 'package:flutter/material.dart';

class TransactionDisplay extends StatelessWidget {
  const TransactionDisplay({super.key});

  @override 
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.25,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('Transações'),
        ],
      ),
    );
  }
}