import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatefulWidget {

  const TransactionHistoryScreen({ super.key });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {

   @override
   Widget build(BuildContext context) {
       return Scaffold(
           appBar: AppBar(title: const Text('TransactionHistoryScreen'),),
           body: Container(),
       );
  }
}