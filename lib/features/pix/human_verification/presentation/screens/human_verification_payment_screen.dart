import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class HumanVerificationPaymentScreen extends StatefulWidget {
  const HumanVerificationPaymentScreen({super.key});

  @override
  State<HumanVerificationPaymentScreen> createState() =>
      _HumanVerificationPaymentScreenState();
}

class _HumanVerificationPaymentScreenState
    extends State<HumanVerificationPaymentScreen> {
  bool _pixKeyCopied = false;
  late Timer _timer;
  Duration _remainingTime = Duration.zero;
  bool _hasExpired = false;

  final String _pixKey =
      '00020126360014BR.GOV.BCB.PIX0114+55119999999990204000053039865802BR5925NOME DO RECEBEDOR6014SAO PAULO62070503***63041D3D';
  final String _amount = 'R\$ 1,00';
  final DateTime _expiresAt = DateTime.now().add(const Duration(minutes: 20));

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  void _updateRemainingTime() {
    final newRemainingTime = _expiresAt.difference(DateTime.now());

    setState(() {
      if (newRemainingTime.isNegative || newRemainingTime.inSeconds == 0) {
        _remainingTime = Duration.zero;
        _timer.cancel();

        if (!_hasExpired) {
          _hasExpired = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (dialogContext) => AlertDialog(
                      title: const Text('Tempo Esgotado'),
                      content: const Text(
                        'O tempo para realizar o pagamento expirou. Por favor, tente novamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/human-verification');
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            }
          });
        }
      } else {
        _remainingTime = newRemainingTime;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagamento de Verificação'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.subtitle,
                          children: [
                            const TextSpan(text: 'Você tem '),
                            TextSpan(
                              text:
                                  "${_remainingTime.inMinutes} minutos e ${_remainingTime.inSeconds % 60} segundos ",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: 'para concluir o pagamento.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: PrettyQrView.data(data: _pixKey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Powered by depix.info",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: _pixKey));
                          setState(() {
                            _pixKeyCopied = true;
                          });
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) {
                            setState(() {
                              _pixKeyCopied = false;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                _pixKeyCopied
                                    ? AppColors.primaryColor.withValues(
                                      alpha: 0.08,
                                    )
                                    : AppColors.pinBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _pixKeyCopied
                                      ? AppColors.primaryColor.withValues(
                                        alpha: 0.5,
                                      )
                                      : AppColors.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.qr_code_rounded,
                                color:
                                    _pixKeyCopied
                                        ? AppColors.primaryColor
                                        : AppColors.primaryColor.withValues(
                                          alpha: 0.7,
                                        ),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chave PIX',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pixKey,
                                      style: TextStyle(
                                        color:
                                            _pixKeyCopied
                                                ? AppColors.primaryColor
                                                : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                _pixKeyCopied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                color:
                                    _pixKeyCopied
                                        ? AppColors.primaryColor
                                        : AppColors.primaryColor.withValues(
                                          alpha: 0.7,
                                        ),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pix,
                                  color: AppColors.primaryColor,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PIX',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _amount,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pagamento de verificação',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Após o pagamento, você receberá um código na mensagem do PIX de retorno.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: 'Já fiz o pagamento',
                        onPressed: () {
                          context.push('/human-verification/code');
                        },
                      ),
                      const SizedBox(height: 20),
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
