import 'package:flutter/material.dart';

class LabelDivider extends StatelessWidget {
  const LabelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(height: 0.1, thickness: 1),
    );
  }
}
