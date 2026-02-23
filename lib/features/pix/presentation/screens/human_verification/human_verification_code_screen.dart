import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/themes/pin_theme.dart';
import 'package:pinput/pinput.dart';

class HumanVerificationCodeScreen extends StatefulWidget {
  const HumanVerificationCodeScreen({super.key});

  @override
  State<HumanVerificationCodeScreen> createState() =>
      _HumanVerificationCodeScreenState();
}

class _HumanVerificationCodeScreenState
    extends State<HumanVerificationCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeValid = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {
        _isCodeValid = _codeController.text.length == 6;
      });
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onContinuePressed() async {
    if (_isVerifying || _codeController.text.length != 6) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final isValid = true;

      if (isValid && mounted) {
        context.pushReplacement('/human-verification/success');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido. Tente novamente.')),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
        _codeController.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Validar Código'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.message_outlined,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    const TextSpan(text: 'Digite o '),
                    TextSpan(
                      text: 'código',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Insira o código de 6 dígitos que você recebeu na mensagem do PIX de retorno.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              Pinput(
                keyboardType: TextInputType.number,
                length: 6,
                controller: _codeController,
                defaultPinTheme: PinThemes.focusedPinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                focusedPinTheme: PinThemes.focusedPinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor, width: 2),
                  ),
                ),
                submittedPinTheme: PinThemes.focusedPinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                ),
                errorPinTheme: PinThemes.focusedPinTheme.copyWith(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              PrimaryButton(
                text: _isVerifying ? "Verificando..." : "Validar Código",
                onPressed: _onContinuePressed,
                isEnabled: _isCodeValid && !_isVerifying,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
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
                        'Verifique o campo de mensagem do PIX que você recebeu de volta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                label: Text(
                  'Voltar para o pagamento',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
