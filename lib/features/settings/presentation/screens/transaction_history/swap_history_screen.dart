import 'package:flutter/material.dart';

class SwapHistoryScreen extends StatefulWidget {

  const SwapHistoryScreen({ super.key });

  @override
  State<SwapHistoryScreen> createState() => _SwapHistoryScreenState();
}

class _SwapHistoryScreenState extends State<SwapHistoryScreen> {

   @override
   Widget build(BuildContext context) {
       return Scaffold(
        backgroundColor: Colors.amber,
           appBar: AppBar(title: const Text('SwapHistoryScreen'),),
           body: Container(),
       );
  }
}