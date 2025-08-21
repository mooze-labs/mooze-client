import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/home/providers/visibility_provider.dart';

const double logoOpacity = 0.2;
const String logoPath = 'assets/new_ui_wallet/assets/logos/logo_primary.svg';
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
            child: SvgPicture.asset(
              logoPath,
              width: logoWidth,
              height: logoHeight,
            ),
          ),
        ),
        const SizedBox(height: 30)
      ],
    );
  }
}

class WalletHeader extends ConsumerWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(isVisibleProvider);
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
            onPressed: () => ref.read(isVisibleProvider.notifier).state = !isVisible,
            icon: Icon(icon, color: Theme.of(context).colorScheme.primary)
        )
      ]
    );
  }
}
