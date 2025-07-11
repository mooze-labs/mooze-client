import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/terms_acceptance_provider.dart';
import 'package:go_router/go_router.dart';

const double fontSize = 16.0;

class ImportWalletWidget extends ConsumerWidget {
  const ImportWalletWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptanceProvider);
    final linkStyle = TextStyle(color: Colors.pinkAccent, fontSize: fontSize);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Já tem uma carteira? ",
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
        InkWell(
          onTap:
              termsAccepted ? () => context.go("/setup/import-wallet") : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Importe-a",
                style:
                    termsAccepted
                        ? linkStyle
                        : linkStyle.copyWith(
                          color: linkStyle.color?.withOpacity(0.5),
                        ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color:
                    termsAccepted
                        ? linkStyle.color
                        : linkStyle.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
