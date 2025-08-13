import 'package:flutter/material.dart';

class PegHistoryScreen extends StatefulWidget {
  const PegHistoryScreen({super.key});

  @override
  State<PegHistoryScreen> createState() => _PegHistoryScreenState();
}

class _PegHistoryScreenState extends State<PegHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(title: const Text('PegHistoryScreen')),
      body: Container(
        child: Center(child: Text('data'),),
      ),
    );
  }
}
