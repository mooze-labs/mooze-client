import 'package:flutter/material.dart';
import 'package:mooze_mobile/widgets/appbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Termos de Uso"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Termos de Uso – Mooze Wallet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: "roboto",
              ),
            ),
            SizedBox(height: 16),
            _buildSection(
              "1. Aceitação dos Termos",
              "Ao utilizar o aplicativo Mooze, você concorda integralmente com estes Termos de Uso. Este documento estabelece as regras para o uso do aplicativo Mooze, um gerenciador de unidades digitais com funcionalidades de intercomunicação, transferências interconectadas ao mundo real e referencial de valor FIAT brasileiro. O aplicativo tem como objetivo proporcionar maior discrição transacional e proteção de dados dos usuários, de forma análoga à privacidade oferecida pelo uso do referencial de valor FIAT em espécie — um direito respaldado por garantias constitucionais fundamentais à privacidade e à inviolabilidade da vida privada, conforme previsto no artigo 5º, inciso X, da Constituição Federal do Brasil e na Quarta Emenda à Constituição dos Estados Unidos.",
            ),
            SizedBox(height: 16),
            _buildSection("2. Responsabilidades do Usuário", """
- O usuário é o único responsável por manter seguras suas senhas de recuperação das unidades digitais em autocustódia no aplicativo. A perda dessas informações implica a perda irreversível das unidades digitais no aplicativo.
- A Mooze não armazena, não acessa senhas privadas nem dados de registros distribuídos de operações do aplicativo que permitam acesso aos fundos de unidades digitais dos usuários.
- Ao utilizar o “modo comerciante” por meio do sistema de operações da DEPIX.INFO no aplicativo Mooze, o usuário aceita plenamente os termos e se responsabiliza legalmente pelas ações realizadas, sejam próprias ou de terceiros que utilizem o aplicativo como ferramenta de gerenciamento sob sua tutela física do aparelho.
- Operações instantâneas em referencial de valor FIAT brasileiro resultam exclusivamente em operações registradas de unidades digitais da DEPIX.INFO, cuja unidade digital tem valor equivalente ao referencial de valor FIAT brasileiro.
              """),
            SizedBox(height: 16),
            _buildSection(
              "2.1. Atitudes Catastróficas Irreversíveis do Usuário",
              """
- Ao utilizar o aplicativo Mooze e criar um usuário, obtendo suas palavras e senhas privadas ou importando acesso por senhas privadas externas, o usuário é responsável por armazenar suas senhas em local seguro. Essas senhas são o único meio de recuperar o acesso às unidades digitais em autocustódia. Todo o sistema de unidades digitais do aplicativo é gerido em autocustódia pelo usuário, não pela Mooze ou pelas tecnologias parceiras agregadas.
- Em caso de problemas com transferências de unidades digitais, seja por uso pessoal ou recebimento por meio do sistema de transações em referencial de valor FIAT brasileiro via DEPIX.INFO, a desinstalação do aplicativo sem a cópia e armazenamento seguro das senhas privadas resultará na perda definitiva de acesso aos fundos. Essa responsabilidade é exclusivamente do usuário, pois a Mooze e suas parceiras tecnológicas não possuem meios de recuperar essas senhas, que são geradas no aparelho do usuário e acessíveis apenas por ele. Essa é uma característica inerente a sistemas de autocustódia, onde a responsabilidade recai exclusivamente sobre o custodiante. A falta de zelo pode levar a consequências como a perda de fundos.
- Não desinstale o aplicativo sem salvar suas senhas privadas de recuperação, especialmente se houver fundos de unidades digitais no aplicativo ou unidades a receber. Isso pode ocasionar a perda permanente dos fundos. Em caso de problemas com transferências, não desinstale o aplicativo; salve suas senhas privadas e, se necessário, contate o suporte da Mooze em suporte@mooze.app ou pelo canal de suporte no Telegram.
              """,
            ),
            SizedBox(height: 16),
            _buildSection("2.2. Comportamentos e Tecnologias de Segurança", """
- A Mooze utiliza sistemas de proteção de dados criptográficos para os IDs dos usuários e suas requisições de transações com empresas parceiras da EULEN.APP, como a Plebank no Brasil. Os dados de transações de unidades digitais são garantidos por tecnologias de registros distribuídos criptografados, como a rede Liquid Network da Blockstream ou tecnologias semelhantes de código aberto e descentralizadas. A responsabilidade pelos dados de operações em referencial de valor FIAT no Brasil é da Plebank, que mantém seus próprios sistemas de segurança e conformidade no país.
- A Mooze não possui sistemas de recuperação de acesso ao aplicativo ou às unidades digitais de usuários que percam suas senhas privadas. A guarda dessas senhas é de responsabilidade exclusiva do usuário.
- O usuário deve armazenar suas senhas privadas com cuidado. O vazamento de senhas devido a anotações em locais inseguros pode permitir acesso malicioso aos fundos. A Mooze não se responsabiliza por perdas decorrentes de senhas vazadas por descuido do usuário ou por violações físicas ao aparelho. Evite armazenar senhas em locais digitais sem criptografia e prefira guardá-las em locais físicos seguros.
- Acessos indevidos ao aparelho físico do usuário, seja por coação, furto ou perda, são de responsabilidade do usuário, que aceita esses termos ao utilizar o aplicativo.
              """),
            SizedBox(height: 16),
            _buildSection("3. Limitação de Responsabilidade", """
- A Mooze não se responsabiliza por perdas ou problemas decorrentes do uso do aplicativo, especialmente em casos de falhas de rede (como problemas em redes de registros distribuídos, soft/hard forks), operações não confirmadas ou erros de uso do usuário nessas redes. As redes de registros distribuídos, que escaneiam históricos de movimentações de unidades digitais, não são controladas pela Mooze, mas por terceiros, como Blockstream, Sideswap ou registros distribuídos de código aberto descentralizados.
- O aplicativo Mooze opera em modo beta aberto, e o usuário concorda que problemas podem ocorrer até o lançamento de uma versão estável. Em caso de problemas críticos que impossibilitem a movimentação de unidades digitais, as senhas privadas dos usuários do aplicativo Mooze são compatíveis com o aplicativo Blockstream Green, permitindo a recuperação e movimentação das unidades digitais em casos de incompatibilidade crítica ou falhas no código do aplicativo em modo beta. Para acessar o aplicativo de “fallback” indicado, Blockstream Green, clique aqui.
- A Mooze e suas processadoras parceiras de unidades digitais não participam de atividades entre usuários e clientes. O aplicativo Mooze é apenas uma ponte tecnológica, agregando tecnologias de empresas como EULEN.APP e DEPIX.INFO. Em casos de uso comercial, a responsabilidade é do usuário. A Mooze não lida com questões contábeis ou fiscais (como emissão de notas fiscais). Os usuários podem regularizar suas operações conforme a legislação brasileira, utilizando, se necessário, a pessoa jurídica (CNPJ) das processadoras da EULEN.APP, como a Plebank.
              """),
            SizedBox(height: 16),
            _buildSection("4. Apreço Monetário", """
- Para unidades digitais que não seguem o referencial de valor FIAT brasileiro, a Mooze realizará uma varredura das principais fontes de precificação do mercado para obter uma média e determinar seu preço monetário próprio no aplicativo.
              """),
            SizedBox(height: 16),
            _buildSection("5. Tarifas e Confirmações", """
### a) Tarifas incluem:

- Tarifas de rede (cobranças das redes de registros distribuídos).
- Tarifas operacionais para operações em referencial de valor FIAT brasileiro das parceiras da EULEN.APP.
- As unidades digitais transferidas ao usuário já incluem todas as tarifas mencionadas.

### b) Confirmações:

- Em caso de problemas com transações instantâneas em referencial de valor FIAT brasileiro ou transferências de unidades digitais no aplicativo, contate o suporte em suporte@mooze.app.
- Todas as operações são protegidas pela tecnologia da Liquid Network contra vazamento de dados e exposição a terceiros não envolvidos nas transferências.
              """),
            SizedBox(height: 16),
            _buildSection("6. O que a Mooze NÃO Faz", """
- A Mooze não realiza nem opera transações bancárias em referencial de valor FIAT. O aplicativo é apenas um agregador de tecnologias para transferências de unidades digitais por meio de transações em referencial de valor FIAT para o público de finanças alternativas.
- A Mooze não realiza entradas ou saídas de transações financeiras com unidades digitais, não custodia unidades digitais, não atua como corretora nem realiza operações de corretagem.
- A Mooze não realiza trocas de unidades digitais de diferentes paridades ou unidades monetárias. Essas operações são de responsabilidade da EULEN.APP e suas parceiras, que decidem aceitar ou processar as operações iniciadas pelos usuários. Em caso de bloqueios ou não processamento devido a comportamento malicioso identificado pelo sistema EULEN.APP via DEPIX.INFO ou suas parceiras, como a Plebank, as operações podem ser estornadas.
              """),
            SizedBox(height: 16),
            _buildSection("6.1. O que a Mooze Faz", """
- A Mooze agrega tecnologias de transferência de dados de unidades digitais por sistemas de registros distribuídos e conversão de unidades digitais, utilizando redes como a da Blockstream e outras descentralizadas de código aberto. Também utiliza sistemas de trocas de unidades digitais das empresas Sideswap, DEPIX.INFO, EULEN.APP e suas parceiras reguladas no Brasil. Novas tecnologias agregadas serão mencionadas em atualizações destes Termos de Uso.
- A Mooze oferece suporte informacional aos usuários por canais eletrônicos, encaminhando informações e pedidos às empresas envolvidas, como a EULEN.APP e suas parceiras no Brasil, atuando como ponte entre o usuário e essas tecnologias.
- A Mooze comunica-se em português ou inglês, dependendo da demanda ou entidade envolvida. Comunicações em português não implicam sede ou operação física no Brasil.
              """),
            SizedBox(height: 16),
            _buildSection("7. Política Antifraude", """
- A Mooze pode armazenar APP IDs, que são hashes criptográficos de dados como MediaDRM, IPv4, UUID, Device Check, entre outros, dependendo da plataforma. O objetivo é detectar uso humano real, evitar spam, ataques a servidores, uso por robôs, fraudes e proteger as parceiras processadoras da EULEN.APP.
- Esses dados não identificam o usuário nem a natureza de transações específicas, não configuram captura de dados civis ou identificação pessoal e são usados apenas em casos de danos a terceiros causados pelo uso do aplicativo, como impactos nas operações das parceiras da EULEN.APP.
              """),
            SizedBox(height: 16),
            _buildSection("8. Obrigações Legais", """
- A Mooze não armazena dados pessoais abertos dos usuários.
- O usuário é responsável por reportar unidades digitais reguladas legalmente no Brasil, conforme exigido pela legislação vigente, já que plataformas internacionais não têm obrigação de reporte direto ao Brasil.
- Informações sobre unidades digitais para fins de declaração podem be solicitadas via suporte@mooze.app.
              """),
            SizedBox(height: 16),
            _buildSection("8.1. Das Jurisdições", """
- A “Otoco Matic LLC – Mooze – Series 99” é a entidade que agrega as tecnologias mencionadas, doravante referida como “Mooze”. Trata-se de uma Series LLC derivada da master LLC “Otoco Matic LLC”, com jurisdição e sede nos Estados Unidos, estado de Wyoming.
- Requisições legais sobre operações e estrutura da Mooze são respondidas sob a jurisdição de Wyoming, EUA.
- As operações no Brasil, por meio do sistema agregado de transferências e trocas de unidades digitais em referencial de valor FIAT, são de responsabilidade jurídica das parceiras da EULEN.APP, como a Plebank (registro aqui), que cumpre todas as normativas e regulamentações legais no Brasil.
              """),
            SizedBox(height: 16),
            _buildSection("9. Atualizações", """
- A Mooze pode alterar os Termos de Uso e o aplicativo a qualquer momento. O uso contínuo implica aceitação das novas condições.
- O usuário também concorda com a Política de Privacidade vinculada, disponível em https://mooze.app/termos-e-privacidade/.
              """),
            SizedBox(height: 24),
            Text(
              "Data da última atualização: 16/05/2024",
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
