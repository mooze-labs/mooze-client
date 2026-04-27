import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
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

    final t = AppLocalizations.of(context);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final isValid = true;

      if (isValid && mounted) {
        context.pushReplacement('/human-verification/success');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.human_verif_code_invalid)),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.error_generic(e.toString()))));
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      appBar: AppBar(
        title: Text(t.human_verif_code_title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
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
                  color: context.colors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.message_outlined,
                  size: 50,
                  color: context.colors.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    TextSpan(text: t.human_verif_code_prompt_prefix),
                    TextSpan(
                      text: t.human_verif_code_word,
                      style: TextStyle(color: context.colors.primaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                t.human_verif_code_body,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              Pinput(
                keyboardType: TextInputType.number,
                length: 6,
                controller: _codeController,
                defaultPinTheme: PinThemes.focusedThemeOf(context).copyWith(
                  decoration: BoxDecoration(
                    color: context.colors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                focusedPinTheme: PinThemes.focusedThemeOf(context).copyWith(
                  decoration: BoxDecoration(
                    color: context.colors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.primaryColor, width: 2),
                  ),
                ),
                submittedPinTheme: PinThemes.focusedThemeOf(context).copyWith(
                  decoration: BoxDecoration(
                    color: context.colors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.primaryColor),
                  ),
                ),
                errorPinTheme: PinThemes.focusedThemeOf(context).copyWith(
                  decoration: BoxDecoration(
                    color: context.colors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              PrimaryButton(
                text: _isVerifying ? t.common_verifying : t.human_verif_code_title,
                onPressed: _onContinuePressed,
                isEnabled: _isCodeValid && !_isVerifying,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.colors.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.human_verif_code_help,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  context.pop();
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: context.colors.primaryColor,
                  size: 20,
                ),
                label: Text(
                  t.human_verif_back_to_payment,
                  style: TextStyle(color: context.colors.primaryColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
