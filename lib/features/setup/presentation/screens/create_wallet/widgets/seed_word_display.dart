import 'package:flutter/material.dart';

class SeedWordDisplay extends StatelessWidget {
  final String word;
  final int position;

  const SeedWordDisplay({
    required this.word,
    required this.position,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Text("Palavra #$position: ", style: TextStyle(fontFamily: "Inter")),
          SizedBox(width: (position >= 10) ? 8 : 14),
          Expanded(child: Text(word, style: TextStyle(fontFamily: "Inter"))),
        ],
      ),
    );
  }
}
