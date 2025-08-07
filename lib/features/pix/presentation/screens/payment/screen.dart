import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mooze_mobile/features/pix/domain/entities.dart';

import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';

import 'consts.dart';
import 'providers.dart';
import 'widgets.dart';

class PixPaymentScreen extends ConsumerWidget {
  const PixPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositId = GoRouterState.of(context).pathParameters["depositId"] as String;
    final deposit = ref.watch(depositDataProvider(depositId));
    
    return deposit.when(
        data: (data) => data.fold(
            (err) => ErrorPixPaymentScreen(errorMessage: "Falha ao gerar QR code: $err"),
            (deposit) => ValidPixPaymentScreen(deposit: deposit)
        ),
        error: (err, stackTrace) => ErrorPixPaymentScreen(errorMessage: "Falha ao gerar QR code: $err"),
        loading: () => LoadingPixPaymentScreen()
    );
  }
}

class ValidPixPaymentScreen extends StatelessWidget {
  final PixDeposit deposit;
  const ValidPixPaymentScreen({super.key, required this.deposit});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: TextSpan(
          text: 'Pagamento ',
          style: AppTextStyles.title,
          children: [
            TextSpan(
              text: 'PIX',
              style: AppTextStyles.title.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
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
                      TimerCountdown(expireAt: deposit.createdAt.add(Duration(minutes: 15))),
                      const Spacer(),
                      PixQrCodeDisplay(pixQrData: deposit.pixKey, boxConstraints: constraints),
                      const Spacer(),
                      CopyableAddress(),
                      const Spacer(),
                      Text("Powered by depix.info", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12)),
                      const Spacer(),
                      PaymentDetailsDisplay(deposit: deposit),
                      const Spacer()
                    ],
                  )
              ),
            )
          );
        }
      )
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
            size: loadingAnimationWidgetSize
        ),
      ),
    );
  }
}