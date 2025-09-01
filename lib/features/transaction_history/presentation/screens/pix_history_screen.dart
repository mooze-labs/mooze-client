import 'package:flutter/material.dart';

class PixHistoryScreen extends StatefulWidget {
  const PixHistoryScreen({super.key});

  @override
  State<PixHistoryScreen> createState() => _PixHistoryScreenState();
}

class _PixHistoryScreenState extends State<PixHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico do PIX')),
      body: Container(),
    );
  }
}
