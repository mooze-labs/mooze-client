import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SwapHistoryScreen extends StatefulWidget {
  const SwapHistoryScreen({super.key});

  @override
  State<SwapHistoryScreen> createState() => _SwapHistoryScreenState();
}

class _SwapHistoryScreenState extends State<SwapHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de swap'),
        leading: IconButton(
          onPressed: () {
            context.go('/menu');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(),
    );
  }
}
