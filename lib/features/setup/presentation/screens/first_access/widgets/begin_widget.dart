import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/first_access/providers.dart';
import 'package:go_router/go_router.dart';

const double iconSize = 20.0;
const double textSize = 19.0;

class BeginWidget extends ConsumerWidget {
  const BeginWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptanceProvider);

    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.wallet_rounded, color: Colors.white, size: iconSize),
          label: Text("Começar"),
          onPressed:
              termsAccepted
                  ? () {
                    context.go("/create_wallet");
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textStyle: TextStyle(
              fontSize: textSize,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 0.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50.0),
            maximumSize: Size(MediaQuery.of(context).size.width * 0.9, 50.0),
            elevation: 3.0,
          ),
        ),
      ],
    );
  }
}
