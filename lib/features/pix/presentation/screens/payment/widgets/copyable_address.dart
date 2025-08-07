import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pix_copypaste_provider.dart';

import '../consts.dart';

class CopyableAddress extends ConsumerWidget {
  const CopyableAddress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixCopypaste = ref.read(pixCopypasteProvider);

    return GestureDetector(
      onTap: () => (),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: containerPadding,
          vertical: containerVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, color: primaryColor, size: iconSize),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pixCopypaste,
                // style: AppTextStyles.value,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.copy, color: primaryColor, size: copyIconSize),
          ],
        ),
      ),
    );
  }
}
