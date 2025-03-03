import 'package:flutter/material.dart';

class MnemonicGridDisplay extends StatelessWidget {
  final String mnemonic;

  const MnemonicGridDisplay({required this.mnemonic, super.key});

  @override
  Widget build(BuildContext context) {
    final listMnemonic = mnemonic.split(" ");
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3,
        ),
        itemCount: listMnemonic.length,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
            child: Center(
              child: Text(
                "${index + 1}. ${listMnemonic[index]}",
                style: TextStyle(
                  fontFamily: "roboto",
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
