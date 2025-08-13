import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PegHistoryScreen extends StatefulWidget {
  const PegHistoryScreen({super.key});

  @override
  State<PegHistoryScreen> createState() => _PegHistoryScreenState();
}

class _PegHistoryScreenState extends State<PegHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de pegs'),
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
