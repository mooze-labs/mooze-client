import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets.dart';

class PhoneVerificationIntroScreen extends StatelessWidget {
  const PhoneVerificationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação'),
        leading: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SvgPicture.asset(
                'assets/new_ui_wallet/assets/images/phone_verification/background_image.svg',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verificação de Humanidade',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: size.width < 350 ? 18 : null,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'Para garantir a segurança, precisamos confirmar que você é uma pessoa real. O número de telefone será usado apenas para enviar um código de verificação. Nenhum dado será armazenado ou vinculado à sua carteira.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: size.width < 350 ? 13 : null,
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(text: 'Próximo', onPressed: () {
              context.go('/phone-verification/method');
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
