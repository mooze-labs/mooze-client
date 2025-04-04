import 'package:flutter/material.dart';

class MnemonicGridDisplay extends StatelessWidget {
  final String mnemonic;
  final double maxHeight;

  const MnemonicGridDisplay({
    required this.mnemonic,
    this.maxHeight = 350, // Default max height that works well for most devices
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final listMnemonic = mnemonic.split(" ");

    // Determine if we need a higher container for more words
    final int rows = (listMnemonic.length / 3).ceil();
    final int baseRowHeight = 55; // Estimated height per row including spacing

    // If using a smaller device, constrain the height
    final screenHeight = MediaQuery.of(context).size.height;
    final bool useConstrainedHeight =
        rows * baseRowHeight > maxHeight || screenHeight < 700;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      // Only constrain the height if needed
      constraints:
          useConstrainedHeight ? BoxConstraints(maxHeight: maxHeight) : null,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}
