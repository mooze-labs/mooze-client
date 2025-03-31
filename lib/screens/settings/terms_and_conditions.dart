import 'package:flutter/material.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Termos de uso"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Termos e Condições de Uso",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: "roboto",
              ),
            ),
            SizedBox(height: 16),
            _buildSection(
              "Bem-vindo ao Mooze",
              "Ao usar nosso aplicativo, você concorda com estes termos e condições de uso. Este documento estabelece as regras e diretrizes para a utilização do aplicativo Mooze, uma carteira digital descentralizada para armazenamento e transações de ativos digitais.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "1. Responsabilidades do Usuário",
              "Você é responsável por manter sua frase de recuperação segura. Não compartilhe com ninguém. A perda desta frase resultará na perda permanente de acesso à sua carteira e ativos. A Mooze não armazena nem tem acesso à sua frase de recuperação ou chaves privadas.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "2. Limitação de Responsabilidade",
              "A Mooze não será responsável por quaisquer perdas resultantes do uso deste aplicativo, incluindo, mas não limitado a, falhas de rede, transações não confirmadas, erros do usuário ou perda de acesso às chaves privadas. O usuário reconhece que utiliza o aplicativo por sua própria conta e risco.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "3. Privacidade e Segurança",
              "A Mooze se compromete a proteger a privacidade do usuário e não coleta dados pessoais desnecessários. No entanto, certas informações técnicas podem ser coletadas para melhorar a experiência do usuário e resolver problemas técnicos. O usuário deve tomar medidas razoáveis para proteger seu dispositivo e prevenir acesso não autorizado ao aplicativo.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "4. Atualizações e Modificações",
              "A Mooze pode lançar atualizações periódicas para o aplicativo e se reserva o direito de modificar estes termos a qualquer momento. As modificações entrarão em vigor assim que publicadas. O uso contínuo do aplicativo após tais alterações constitui aceitação dos novos termos.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "5. Lei Aplicável",
              "Estes termos são regidos pelas leis do Brasil. Qualquer disputa decorrente ou relacionada a estes termos será submetida à jurisdição exclusiva dos tribunais brasileiros.",
            ),
            SizedBox(height: 24),
            Text(
              "Data da última atualização: 31/03/2024",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: "roboto",
            ),
          ),
          SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 16, fontFamily: "roboto")),
        ],
      ),
    );
  }
}
