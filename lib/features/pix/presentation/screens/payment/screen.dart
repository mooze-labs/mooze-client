import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mooze_mobile/features/pix/domain/entities.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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

class ValidPixPaymentScreen extends StatefulWidget {
  final PixDeposit deposit;
  const ValidPixPaymentScreen({super.key, required this.deposit});

  @override
  State<ValidPixPaymentScreen> createState() => _ValidPixPaymentScreenState();
}

class _ValidPixPaymentScreenState extends State<ValidPixPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _reverseCircleController;
  late Animation<double> _reverseCircleAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeReverseAnimation();
  }

  void _initializeReverseAnimation() {
    _reverseCircleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _reverseCircleAnimation = Tween<double>(begin: 3.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _reverseCircleController,
        curve: Curves.easeInOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReverseOverlay();
      _reverseCircleController.forward().then((_) {
        _hideReverseOverlay();
      });
    });
  }

  void _showReverseOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => AnimatedBuilder(
            animation: _reverseCircleController,
            builder: (context, child) {
              final size = MediaQuery.of(context).size;
              final progress = _reverseCircleAnimation.value / 3.0;

              return IgnorePointer(
                ignoring: true,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                        // Círculo que diminui
                        Positioned(
                          left: -size.width * 1.2,
                          bottom: -size.height * 0.3,
                          child: Container(
                            width:
                                size.width *
                                _reverseCircleAnimation.value *
                                1.2,
                            height:
                                size.width *
                                _reverseCircleAnimation.value *
                                1.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: progress,
                          child: Container(color: AppColors.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReverseOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _reverseCircleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pagamento PIX'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(contentPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TimerCountdown(
                        expireAt: widget.deposit.createdAt.add(
                          Duration(minutes: 20),
                        ),
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
                                        Navigator.of(dialogContext).pop();
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/pix');
                                        }
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      PixQrCodeDisplay(
                        pixQrData: widget.deposit.pixKey,
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
                      SizedBox(height: 20),
                      CopyableAddress(pixKey: widget.deposit.pixKey),
                      SizedBox(height: 20),
                      PaymentDetailsDisplay(deposit: widget.deposit),
                      SizedBox(height: 20),
                    ],
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

class ErrorPixPaymentScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorPixPaymentScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: TextSpan(text: ""),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/pix');
          }
        },
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
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/pix');
          }
        },
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
