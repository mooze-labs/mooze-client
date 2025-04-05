import 'package:flutter/material.dart';

class MnemonicGridDisplay extends StatelessWidget {
  final String mnemonic;
  final double maxHeight;

  const MnemonicGridDisplay({
    required this.mnemonic,
    this.maxHeight = 350,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final listMnemonic = mnemonic.split(" ");

    // Calculate the height for the grid
    final int rows = (listMnemonic.length / 3).ceil();
    final double itemHeight = 45;
    final double totalGridHeight = rows * itemHeight + (rows - 1) * 10;

    // Get screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final bool needsScrolling =
        totalGridHeight > maxHeight || screenHeight < 700;
    final containerHeight = needsScrolling ? maxHeight : totalGridHeight + 32;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      height: containerHeight,
      child: ListView(
        children: [
          Wrap(
            spacing: 10, // gap between adjacent items
            runSpacing: 10, // gap between lines
            children: List.generate(listMnemonic.length, (index) {
              return SizedBox(
                width:
                    (MediaQuery.of(context).size.width - 32 - 32) / 3 -
                    7, // Adjust width for 3 items per row
                height: itemHeight,
                child: Container(
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
