import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/shared/widgets.dart';

import 'consts.dart';
import 'providers.dart';
import 'widgets.dart';

class PixPaymentScreen extends ConsumerWidget {
  const PixPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositId =
        GoRouterState.of(context).pathParameters["transaction_id"] as String;
    final deposit = ref.watch(depositDataProvider(depositId));

    return deposit.when(
      data:
          (data) => data.fold(
            (err) => ErrorPixPaymentScreen(
              errorMessage: "Falha ao gerar QR code: $err",
            ),
            (deposit) => ValidPixPaymentScreen(deposit: deposit),
          ),
      error:
          (err, stackTrace) => ErrorPixPaymentScreen(
            errorMessage: "Falha ao gerar QR code: $err",
          ),
      loading: () => LoadingPixPaymentScreen(),
    );
  }
}

class ValidPixPaymentScreen extends StatelessWidget {
  final PixDeposit deposit;
  const ValidPixPaymentScreen({super.key, required this.deposit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagamento PIX'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.go("/pix");
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(contentPadding),
                child: Column(
                  children: [
                    TimerCountdown(
                      expireAt: deposit.createdAt.add(Duration(minutes: 20)),
                      onExpired: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (dialogContext) => AlertDialog(
                                title: const Text('Tempo Esgotado'),
                                content: const Text(
                                  'O tempo para realizar o pagamento expirou. Por favor, gere um novo PIX.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop();
                                      context.go(
                                        '/pix',
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                    const Spacer(),
                    PixQrCodeDisplay(
                      pixQrData: deposit.pixKey,
                      boxConstraints: constraints,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Powered by depix.info",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    CopyableAddress(),
                    SizedBox(height: 20),
                    PaymentDetailsDisplay(deposit: deposit),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ErrorPixPaymentScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorPixPaymentScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: TextSpan(text: ""),
        onBack: () => context.go("/pix/receive"),
      ),
      body: Center(
        child: Text(
          errorMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class LoadingPixPaymentScreen extends StatelessWidget {
  const LoadingPixPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: TextSpan(text: ""),
        onBack: () => context.go("/pix"),
      ),
      body: Center(
        child: LoadingAnimationWidget.threeRotatingDots(
          color: Theme.of(context).colorScheme.primary,
          size: loadingAnimationWidgetSize,
        ),
      ),
    );
  }
}
