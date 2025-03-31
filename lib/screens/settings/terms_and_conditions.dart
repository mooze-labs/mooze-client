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
            _buildSection("1. Responsabilidades do Usuário", """
a) Você é responsável por manter sua frase de recuperação segura. Não compartilhe com ninguém. A perda desta frase resultará na perda permanente de acesso à sua carteira e ativos. A Mooze não armazena nem tem acesso à sua frase de recuperação ou chaves privadas.\n
b) O usuário, seja no uso pessoal da carteira ou na função de comerciante utilizando o “modo comércio” via gateway DEPIX, aceita integralmente os termos de uso e reconhece que é responsável pelas operações realizadas tanto em nome próprio quanto de terceiros (ex: clientes).\n
c) O usuário compreende que ao realizar pagamentos via PIX no Brasil, está adquirindo a stablecoin privada DEPIX, lastreada em reais tokenizados. Os valores recebidos são líquidos, após dedução de taxas de rede e de prestação de serviço da Mooze, incluindo swaps entre camadas do Bitcoin on-chain ou ativos da rede Liquid.\n
d) Fica reiterado que todas as transações realizadas com o app Mooze via PIX – seja em compras pessoais ou como gateway de pagamento – são operações de tokenização de reais em DEPIX, utilizando a blockchain privada da Liquid Network.\n
e) No caso de recebimento em outras moedas como USDT Liquid, Bitcoin On-chain ou Liquid Bitcoin, a conversão ocorre por um sistema automatizado de swap interno à própria carteira do cliente. A Mooze, bem como as processadoras de pagamentos em reais, não operam câmbio, não vendem moedas estrangeiras e não participam desses swaps. Elas apenas viabilizam a tokenização dos reais via empresas internacionais do sistema DEPIX. A Mooze atua como uma ponte automatizada que converte os DEPIX recebidos em ativos selecionados pelo usuário na sua própria custódia.
              """),
            SizedBox(height: 16),
            _buildSection(
              "2. Limitação de Responsabilidade",
              "A Mooze não será responsável por quaisquer perdas resultantes do uso deste aplicativo, incluindo, mas não limitado a, falhas de rede, transações não confirmadas, erros do usuário ou perda de acesso às chaves privadas. O usuário reconhece que utiliza o aplicativo por sua própria conta e risco.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "3. Cotações de ativos",
              """As cotações utilizadas nos swaps podem ter como referência plataformas como Bitfinex, Blockchain.com, Binance, CoinGecko ou outras. O sistema busca sempre a cotação mais atualizada entre todas as fontes disponíveis.\n
Cotações de ativos como Bitcoin, USDT e outros podem incluir spread, especialmente no modo de compra ou uso comercial.
              """,
            ),
            SizedBox(height: 16),
            _buildSection("4. Serviços", """
a)Taxas de Rede e de Serviço\n
As taxas totais aplicadas pela Mooze consideram:
 i) A rede do ativo escolhido (ex: taxa on-chain para Bitcoin ou taxas da rede Liquid para DEPIX, L-BTC ou USDT).
 ii) Taxas de intermediários das processadoras de pagamento via PIX.
 iii) As cotações já incluem todos os custos de rede e intermediação.

b) Confirmação e Recebimento
Em caso de inconsistências, falhas de transação ou qualquer outra anomalia durante o processo de pagamento via PIX, o usuário deve entrar em contato com o suporte através do site oficial: https://mooze.app, acessando a opção de atendimento.\n
Atualmente, a Mooze opera exclusivamente com as redes Bitcoin on-chain e Liquid Network (Blockstream).\n
Todas as transações originadas na Mooze são blindadas contra rastreamento, pois utilizam a Liquid Network, cuja estrutura garante anonimato e confidencialidade. Mesmo que o cliente opte por receber em Bitcoin on-chain, a origem será sempre da Liquid, mantendo a privacidade da operação.
              """),
            SizedBox(height: 16),
            _buildSection("5. Pagamentos Fiat", """
O único meio de pagamento aceito no app é o PIX, com limites de valor nas primeiras transações como medida de segurança.
Existe um limite diário de R\$5.000,00 por CPF/CNPJ, compartilhado entre todos os aplicativos e P2Ps que utilizam o sistema DEPIX. Se esse limite for excedido em qualquer plataforma, a transação poderá ser estornada automaticamente.
Esse controle segue conformidades exigidas pelas processadoras de pagamento, com o objetivo de mitigar riscos de lavagem de dinheiro, mantendo a privacidade e segurança do sistema DEPIX.
              """),
            SizedBox(height: 16),
            _buildSection("6. Privacidade e Segurança", """
A Mooze se compromete a proteger a privacidade do usuário e não coleta dados pessoais desnecessários. No entanto, certas informações técnicas podem ser coletadas para melhorar a experiência do usuário e resolver problemas técnicos. O usuário deve tomar medidas razoáveis para proteger seu dispositivo e prevenir acesso não autorizado ao aplicativo.
Nenhuma informação pessoal é arquivada nos bancos de dados da Mooze.
Nós podemos arquivar as seguintes informações:
  - Uma chave única não identificável baseada em criptografia irreversível por pagante.
  - Identificador único associado ao dispositivo do usuário e à instalação do aplicativo.
  - Informações técnicas para melhorar a experiência do usuário e resolver problemas técnicos.
              """),
            SizedBox(height: 16),
            _buildSection("7. Obrigações fiscais", """
O cliente é integralmente responsável por declarar seus ativos ao fisco.
A Mooze pode, sob solicitação, fornecer um extrato para fins fiscais. Para isso, o cliente deverá informar nome, CPF ou CNPJ, permitindo que a Mooze solicite relatórios às instituições de pagamento, que são as únicas que armazenam os registros das transações.
Reiteramos que Mooze não possui banco de dados com informações de clientes.
              """),
            SizedBox(height: 16),
            _buildSection(
              "8. Atualizações e Modificações",
              "A Mooze pode lançar atualizações periódicas para o aplicativo e se reserva o direito de modificar estes termos a qualquer momento. As modificações entrarão em vigor assim que publicadas. O uso contínuo do aplicativo após tais alterações constitui aceitação dos novos termos.",
            ),
            SizedBox(height: 16),
            _buildSection(
              "9. Lei Aplicável",
              "Os termos de uso do aplicativo, se aplicam aos usuários das transações com as processantes de pagamento a legislação vigente do Brasil.\nAs responsabilidades como intermediária de swaps no app da Mooze são regidas por jurisdição internacional, devido sua natureza como entidade empresarial do tipo DAO, verificável através da central de dados no portal de transparência da empresa, através do menu de configuração do app.",
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
