import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_expandable_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_footer_link.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_header.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_info_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_warning_card.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late final List<bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _expandedSections = List<bool>.filled(_termsSections.length, false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final shouldShow = _scrollController.offset >= 200;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && mounted) {
          AppSnackBar.error(context, 'Não foi possível abrir o link');
        }
      }
    } catch (_) {
      if (mounted) AppSnackBar.error(context, 'Erro ao abrir o link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LegalDocumentHeader(
                    icon: Icons.gavel_rounded,
                    title: 'Termos de Uso',
                    subtitle: 'Mooze Wallet',
                    description:
                        'Ao utilizar o aplicativo Mooze, você concorda integralmente com estes termos. Leia atentamente antes de prosseguir.',
                  ),
                  const SizedBox(height: 24),
                  LegalDocumentWarningCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Aviso Importante',
                    message:
                        'Você é o único responsável por manter suas senhas de recuperação seguras. A perda dessas informações implica perda irreversível das unidades digitais.',
                    containerColor:
                        colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderColor: colorScheme.error.withValues(alpha: 0.3),
                    iconColor: colorScheme.error,
                    textColor: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickInfo(),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return LegalDocumentExpandableSection(
                  index: index,
                  section: _termsSections[index],
                  isExpanded: _expandedSections[index],
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedSections[index] = expanded);
                  },
                );
              },
              childCount: _termsSections.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildFooter(colorScheme, textTheme),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _showBackToTop
              ? FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  elevation: 4,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildQuickInfo() {
    return const SizedBox(
      height: 125,
      child: Row(
        children: [
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.account_balance_rounded,
              title: 'Autocustódia',
              subtitle: 'Você controla seus fundos',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.shield_rounded,
              title: 'Privacidade',
              subtitle: 'Dados protegidos',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.science_rounded,
              title: 'Beta',
              subtitle: 'Em desenvolvimento',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Última atualização: 13/11/2025',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LegalDocumentFooterLink(
            icon: Icons.privacy_tip_outlined,
            label: 'Ver Política de Privacidade',
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.primary,
            onTap: () =>
                _launchUrl('https://mooze.app/termos-e-privacidade/'),
          ),
        ],
      ),
    );
  }
}

const _termsSections = [
  LegalDocumentSection(
    "1. Aceitação dos Termos",
    "Ao utilizar o aplicativo Mooze, você concorda integralmente com estes Termos de Uso. Este documento estabelece as regras de uso do aplicativo da Mooze, um gerenciador de unidades digitais com funcionalidades de intercomunicação com transferências interconectadas ao mundo real e ao referencial de valor FIAT brasileiro. O aplicativo tem como objetivo proporcionar maior discrição transacional e proteção de dados dos usuários, de forma análoga à privacidade oferecida pelo uso do referencial de valor FIAT em espécie — um direito respaldado por garantias constitucionais fundamentais à privacidade e à inviolabilidade da vida privada, conforme previsto no artigo 5º, inciso X, da Constituição Federal do Brasil e na Quarta Emenda à Constituição dos Estados Unidos.",
  ),
  LegalDocumentSection(
    "2. Responsabilidades do Usuário",
    "O usuário é o único responsável por manter seguras suas senhas de recuperação das unidades digitais em auto custódia no aplicativo. A perda dessas informações implica a perda irreversível das unidades digitais dentro do nosso aplicativo.\n\nA Mooze não armazena nem tem acesso a senhas privadas ou dados de registro distribuído de operações do aplicativo que permitam acessar os fundos de unidades digitais dos usuários.\n\nAo utilizar o \"modo comerciante\" via sistema de operações no aplicativo Mooze, o usuário aceita plenamente os termos e se responsabiliza legalmente pelas ações realizadas, sejam próprias ou de terceiros que utilizem o aplicativo como ferramenta de gerenciamento sob sua tutela física do aparelho.\n\nOperações instantâneas em referencial de valor FIAT brasileiro resultam unicamente em operações registradas de unidades digitais da depix.info, unidade digital de valor igual ao referencial de valor FIAT brasileiro.\n\nA conversão de unidades digitais com valor diferente do referencial de valor FIAT brasileiro ocorrerá de forma automática dentro do aplicativo do usuário. A Mooze não realiza operações no sistema financeiro tradicional do Brasil; apenas viabiliza a movimentação de unidades digitais e trocas de unidades digitais pareáveis em valores de forma automatizada.",
  ),
  LegalDocumentSection(
    "2.1. Atitudes Catastróficas Irreversíveis",
    "O usuário, ao utilizar o aplicativo da Mooze e criar seu perfil, obtendo suas palavras e senhas privadas ou importando acesso por senhas privadas externas, se responsabiliza por salvar suas senhas em local seguro. Essa senha é o único meio de recuperar o acesso às suas unidades digitais em sua própria custódia.\n\nCaso o usuário tenha algum problema nas transferências de unidades digitais, seja por uso pessoal ou por recebimentos de unidades digitais através do sistema de transação em referencial de valor FIAT brasileiro via depix.info, e desinstale o aplicativo sem copiar e guardar suas senhas em local seguro para recuperá-las posteriormente, perderá o acesso definitivo aos seus fundos.\n\nNão desinstale o aplicativo sem salvar suas senhas privadas de recuperação, principalmente se houver fundos de unidades digitais no aplicativo ou unidades por receber. Em caso de problemas, contate o suporte em suporte@mooze.app ou via Telegram.",
  ),
  LegalDocumentSection(
    "2.2. Comportamentos e Tecnologias de Segurança",
    "A Mooze possui sistemas de proteção de dados criptográficos dos IDs de usuários e de suas requisições de transações com as empresas parceiras da Eulen.app, como a Plebank em território nacional. Os dados de transações de unidades digitais são garantidos pela tecnologia de registros distribuídos criptografados via rede Liquid Network, da empresa Blockstream.\n\nA Mooze não possui sistemas de segurança para recuperação de acesso ao aplicativo de usuários ou acesso às unidades digitais de usuários que percam suas senhas privadas. A guarda é de exclusiva responsabilidade do usuário.\n\nO usuário deve ser responsável por guardar suas senhas privadas. Caso elas sejam vazadas por anotações em locais inseguros, poderá dar acesso malicioso aos seus fundos. Evite salvar senhas em locais digitais sem criptografia. Prefira guardar suas senhas pessoais em local físico seguro.\n\nAcessos indevidos ao aparelho físico do usuário, seja por coação, furto ou perda do mesmo, são de responsabilidade do usuário.",
  ),
  LegalDocumentSection(
    "3. Limitação de Responsabilidade",
    "A Mooze não se responsabiliza por perdas ou problemas decorrentes do uso do aplicativo, principalmente em casos que incluam falhas de rede, operações não confirmadas ou erros de uso do usuário nessas redes.\n\nO aplicativo da Mooze está em funcionamento como aplicativo em modo BETA e em versão de release em breve. O usuário concorda que problemas podem ocorrer caso esteja usando a versão BETA. Caso ocorram problemas críticos, as senhas privadas dos usuários têm compatibilidade com recuperação no aplicativo Blockstream.\n\nA Mooze e as processadoras de unidades digitais parceiras não participam de atividades entre usuários e clientes. O sistema do aplicativo da Mooze é apenas uma ponte tecnológica. A Mooze apenas agrega tecnologias de outras empresas, como Eulen.app e depix.info. Em casos de fins comerciais, é de inteira responsabilidade do usuário.",
  ),
  LegalDocumentSection(
    "4. Apreço Monetário",
    "Os apreços monetários das unidades digitais que não sejam do referencial de valor FIAT brasileiro oficial serão determinados pela Mooze mediante varredura das principais fontes conhecidas do mercado de precificação de unidades digitais, para obtenção de uma média e geração de seu preço monetário próprio no aplicativo. Esses valores serão valores de referência para prestação de serviços de resgates de colaterais do DEPIX, o Bitcoin.",
  ),
  LegalDocumentSection(
    "5. Tarifas e Confirmações",
    "a) Tarifas incluem:\n- Tarifas de rede (tarifas cobradas pelas redes de registros distribuídos)\n- Tarifas operacionais pelas operações em referencial de valor FIAT brasileiro das parceiras Eulen.app\n- As unidades digitais emitidas a custódia do usuário já incluirão todas as tarifas citadas acima\n\nb) Confirmações:\n- Em caso de problemas com transações instantâneas em referencial de valor FIAT brasileiro ou transferência de unidades digitais dentro do aplicativo, o suporte deve ser contatado via suporte@mooze.app\n- Todas as operações são protegidas com a tecnologia da Liquid Network contra vazamento de dados e exposição a terceiros não envolvidos na transferência de unidades digitais, através do sistema de \"Confidential Transactions\" com Blinding Factors.",
  ),
  LegalDocumentSection(
    "6. O que a Mooze NÃO FAZ",
    "A Mooze não realiza nem opera transações em referencial de valor FIAT bancárias. O aplicativo é apenas um agregador de tecnologias de transferências de unidades digitais por meio de transações em referencial de valor FIAT brasileiro para o público de finanças alternativas, realizadas por parceiras BaaS e EaaS no Brasil e no exterior.\n\nA Mooze não realiza entradas ou saídas de transações financeiras diante de unidades digitais, não possui custódia de unidades digitais em nome de terceiros, não age nem faz operações de corretagem e não opera como corretora.\n\nA Mooze não realiza trocas de unidades digitais de diferentes paridades ou unidades monetárias. Operações em referenciais de valor FIAT brasileiro/unidades digitais são de responsabilidade e operadas pela Eulen.app e suas parceiras.",
  ),
  LegalDocumentSection(
    "6.1. O que a Mooze Faz",
    "A Mooze apenas agrega tecnologias de transferências de dados de unidades digitais por sistemas de registros distribuídos e conversão de unidades digitais. Utilizamos redes de registros distribuídos, como exemplo a da consolidada empresa Blockstream e sua federação. Utilizamos sistemas de trocas entre e por unidades digitais das empresas: Sideswap, DEPIX.INFO, EULEN.APP e suas parceiras reguladas legalmente em território brasileiro.\n\nA Mooze realiza suporte informacional a usuários do aplicativo através de canais eletrônicos, encaminhando informações e pedidos de usuários para as empresas envolvidas no uso das tecnologias do aplicativo.\n\nA Mooze se comunica em língua portuguesa ou inglesa, dependendo da demanda, do tipo de usuário ou entidade que exija essa comunicação. Comunicações em português do Brasil não significam que a Mooze tem sede ou operação física no Brasil. A Mooze tem sede e operação nos Estados Unidos da América, na cidade de Wyoming.",
  ),
  LegalDocumentSection(
    "7. Política Antifraude",
    "A Mooze poderá armazenar APP IDs, consistentes em hashes criptografados de dados como MediaDRM, IPv4, UUID, Device Check e outros de natureza equivalente, conforme a plataforma utilizada. Essa medida tem por finalidade identificar o uso humano legítimo, prevenir spam, mitigar ataques aos servidores, impedir a utilização do aplicativo por robôs ou fraudes.\n\nOs referidos dados:\n- Não permitem a identificação do usuário nem revelam a natureza de transações específicas\n- Não constituem coleta de informações civis, documentação ou identificação pessoal na plataforma da Mooze\n- Serão utilizados exclusivamente nas hipóteses em que usuários do aplicativo causem prejuízos a terceiros por meio do seu uso",
  ),
  LegalDocumentSection(
    "8. Obrigações Legais",
    "A Mooze não armazena dados pessoais abertos de seus usuários.\n\nO usuário é responsável pelo reporte das unidades digitais do aplicativo que eventualmente sejam submetidas a regulação legal no Brasil, uma vez que a legislação brasileira vigente impõe essa obrigação aos usuários de plataformas internacionais, as quais não possuem obrigação direta de reporte de dados ao País.\n\nInformações relativas às unidades digitais do aplicativo Mooze, para fins de declaração eventualmente exigida, poderão ser requisitadas por meio do e-mail suporte@mooze.app.",
  ),
  LegalDocumentSection(
    "8.1. Das Jurisdições",
    "A \"Otoco Matic LLC – Mooze – Series 99\" é a empresa que detém a operação agregadora de todas as tecnologias das parceiras mencionadas nestes termos, doravante designada simplesmente como \"Mooze\". Trata-se de uma Series LLC constituída sob a master LLC \"Otoco Matic LLC\", com jurisdição e sede nos Estados Unidos da América, no Estado de Wyoming.\n\nTodas as requisições legais referentes às operações e à estrutura da empresa serão dirimidas sob a jurisdição dos Estados Unidos da América, no Estado de Wyoming.\n\nAs operações realizadas em território brasileiro por meio do aplicativo Mooze são de responsabilidade jurídica das parceiras da rede Eulen.app que atuam no Brasil, as quais observam integralmente as normas, leis e regulamentações aplicáveis no País.",
  ),
  LegalDocumentSection(
    "9. Modelo de Transações Não Custodiais",
    "A) Aquisição de Ativos Digitais via Mooze\n\nTodas as aquisições de unidades digitais realizadas por meio da Mooze são regidas pelos presentes Termos de Uso. Qualquer aquisição de ativos efetuada mediante pagamentos em moeda fiduciária a parceiras globais da rede Eulen.app refere-se exclusivamente a DEPIX – token unitário digital sintético colateralizado parcialmente em moedas fiduciárias e majoritariamente em Bitcoin.\n\nAo efetuar o pagamento fiduciário no sistema financeiro brasileiro, o usuário adquire DEPIX em nome e titularidade da Mooze. O usuário aceita expressamente essa condição ao prosseguir com a operação.\n\nB) Aquisição de DEPIX\n\nAo selecionar a opção DEPIX na plataforma, o usuário contrata o serviço de aquisição de DEPIX em nome da Mooze. Os ativos são mantidos sob posse da Mooze para viabilizar a execução de serviços de intermediação. A Mooze deduz sua taxa de serviço do montante a ser entregue, e os DEPIX são emitidos em favor do usuário.\n\nC) Aquisição de Bitcoin\n\nAo selecionar Bitcoin, o usuário contrata o serviço de aquisição de DEPIX em nome da Mooze. Os DEPIX são utilizados para resgatar o colateral em Bitcoin. A Mooze deduz sua taxa de serviço, e o Bitcoin é emitido em favor do usuário.\n\nD) Jurisdição de Acesso\n\nA Mooze disponibiliza o acesso aos serviços exclusivamente por meio do sistema financeiro brasileiro, utilizando o PIX. Somente indivíduos com cidadania brasileira ativa podem utilizar os serviços de pagamento.",
  ),
  LegalDocumentSection(
    "10. Atualizações",
    "A Mooze reserva-se o direito de alterar estes Termos de Uso e o aplicativo a qualquer momento. O uso continuado da plataforma após tais modificações implica aceitação integral das novas condições.\n\nO usuário declara concordar, ainda, com os termos da Política de Privacidade, disponível em https://mooze.app/termos-e-privacidade/.",
  ),
];
