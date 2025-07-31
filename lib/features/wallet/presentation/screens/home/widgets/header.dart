import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/providers/visibility_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/visibility_provider.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/logos/5.png';
const double logoWidth = 117.0;
const double logoHeight = 24.0;

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Opacity(
            opacity: logoOpacity,
            child: Image.asset(
              logoPath,
              width: logoWidth,
              height: logoHeight,
            ),
          ),
        )
      ],
    );
  }
}

class WalletHeader extends ConsumerWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.read(visibilityProvider);
    final icon = (isVisible) ? Icons.visibility : Icons.visibility_off;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            "Minha Carteira",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: 20
          )
        ),
        IconButton(
            onPressed: () => ref.read(visibilityProvider.notifier).state = !isVisible,
            icon: Icon(icon, color: Theme.of(context).colorScheme.primary)
        )
      ]
    );
  }
}
