import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsSection {
  final String title;
  final String content;

  const TermsSection(this.title, this.content);
}

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  final List<bool> _expandedSections = List.filled(20, false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 200) {
      if (!_showBackToTop) {
        setState(() => _showBackToTop = true);
      }
    } else {
      if (_showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Não foi possível abrir o link');
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir o link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(theme, colorScheme),
      floatingActionButton:
          _showBackToTop ? _buildBackToTopButton(colorScheme) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Termos de Uso'),
      leading: IconButton(
        onPressed: () {
          context.pop();
        },
        icon: Icon(Icons.arrow_back_ios_new_rounded),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                const SizedBox(height: 24),
                _buildWarningCard(colorScheme),
                const SizedBox(height: 24),
                _buildQuickInfo(colorScheme),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            ..._buildTermsSections(theme, colorScheme),
            const SizedBox(height: 32),
            _buildFooter(colorScheme),
            const SizedBox(height: 100),
          ]),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termos de Uso',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mooze Wallet',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ao utilizar o aplicativo Mooze, você concorda integralmente com estes termos. Leia atentamente antes de prosseguir.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aviso Importante',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você é o único responsável por manter suas senhas de recuperação seguras. A perda dessas informações implica perda irreversível das unidades digitais.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onErrorContainer.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(ColorScheme colorScheme) {
    return SizedBox(
      height: 125,
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.account_balance_rounded,
                title: 'Autocustódia',
                subtitle: 'Você controla seus fundos',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.shield_rounded,
                title: 'Privacidade',
                subtitle: 'Dados protegidos',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.science_rounded,
                title: 'Beta',
                subtitle: 'Em desenvolvimento',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTermsSections(ThemeData theme, ColorScheme colorScheme) {
    final sections = _getTermsSections();
    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandedSections[index],
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedSections[index] = expanded;
                });
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              title: Text(
                section.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                _getPreview(section.content),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      section.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
                'Última atualização: 16/05/2024',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchUrl('https://mooze.app/termos-e-privacidade/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ver Política de Privacidade',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToTopButton(ColorScheme colorScheme) {
    return FloatingActionButton.small(
      onPressed: _scrollToTop,
      elevation: 4,
      child: const Icon(Icons.keyboard_arrow_up_rounded),
    );
  }

  String _getPreview(String content) {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  List<TermsSection> _getTermsSections() {
    return [
      TermsSection(
        "Aceitação dos Termos",
        "Ao utilizar o aplicativo Mooze, você concorda integralmente com estes Termos de Uso. Este documento estabelece as regras para o uso do aplicativo Mooze, um gerenciador de unidades digitais com funcionalidades de intercomunicação, transferências interconectadas ao mundo real e referencial de valor FIAT brasileiro. O aplicativo tem como objetivo proporcionar maior discrição transacional e proteção de dados dos usuários, de forma análoga à privacidade oferecida pelo uso do referencial de valor FIAT em espécie — um direito respaldado por garantias constitucionais fundamentais à privacidade e à inviolabilidade da vida privada, conforme previsto no artigo 5º, inciso X, da Constituição Federal do Brasil e na Quarta Emenda à Constituição dos Estados Unidos.",
      ),
      TermsSection(
        "Responsabilidades do Usuário",
        "- O usuário é o único responsável por manter seguras suas senhas de recuperação das unidades digitais em autocustódia no aplicativo. A perda dessas informações implica a perda irreversível das unidades digitais no aplicativo.\n- A Mooze não armazena, não acessa senhas privadas nem dados de registros distribuídos de operações do aplicativo que permitam acesso aos fundos de unidades digitais dos usuários.\n- Ao utilizar o \"modo comerciante\" por meio do sistema de operações da DEPIX.INFO no aplicativo Mooze, o usuário aceita plenamente os termos e se responsabiliza legalmente pelas ações realizadas, sejam próprias ou de terceiros que utilizem o aplicativo como ferramenta de gerenciamento sob sua tutela física do aparelho.\n- Operações instantâneas em referencial de valor FIAT brasileiro resultam exclusivamente em operações registradas de unidades digitais da DEPIX.INFO, cuja unidade digital tem valor equivalente ao referencial de valor FIAT brasileiro.",
      ),
      TermsSection(
        "Atitudes Catastróficas Irreversíveis do Usuário",
        "- Ao utilizar o aplicativo Mooze e criar um usuário, obtendo suas palavras e senhas privadas ou importando acesso por senhas privadas externas, o usuário é responsável por armazenar suas senhas em local seguro. Essas senhas são o único meio de recuperar o acesso às unidades digitais em autocustódia. Todo o sistema de unidades digitais do aplicativo é gerido em autocustódia pelo usuário, não pela Mooze ou pelas tecnologias parceiras agregadas.\n- Em caso de problemas com transferências de unidades digitais, seja por uso pessoal ou recebimento por meio do sistema de transações em referencial de valor FIAT brasileiro via DEPIX.INFO, a desinstalação do aplicativo sem a cópia e armazenamento seguro das senhas privadas resultará na perda definitiva de acesso aos fundos. Essa responsabilidade é exclusivamente do usuário, pois a Mooze e suas parceiras tecnológicas não possuem meios de recuperar essas senhas, que são geradas no aparelho do usuário e acessíveis apenas por ele. Essa é uma característica inerente a sistemas de autocustódia, onde a responsabilidade recai exclusivamente sobre o custodiante. A falta de zelo pode levar a consequências como a perda de fundos.\n- Não desinstale o aplicativo sem salvar suas senhas privadas de recuperação, especialmente se houver fundos de unidades digitais no aplicativo ou unidades a receber. Isso pode ocasionar a perda permanente dos fundos. Em caso de problemas com transferências, não desinstale o aplicativo; salve suas senhas privadas e, se necessário, contate o suporte da Mooze em suporte@mooze.app ou pelo canal de suporte no Telegram.",
      ),
      TermsSection(
        "Comportamentos e Tecnologias de Segurança",
        "- A Mooze utiliza sistemas de proteção de dados criptográficos para os IDs dos usuários e suas requisições de transações com empresas parceiras da EULEN.APP, como a Plebank no Brasil. Os dados de transações de unidades digitais são garantidos por tecnologias de registros distribuídos criptografados, como a rede Liquid Network da Blockstream ou tecnologias semelhantes de código aberto e descentralizadas. A responsabilidade pelos dados de operações em referencial de valor FIAT no Brasil é da Plebank, que mantém seus próprios sistemas de segurança e conformidade no país.\n- A Mooze não possui sistemas de recuperação de acesso ao aplicativo ou às unidades digitais de usuários que percam suas senhas privadas. A guarda dessas senhas é de responsabilidade exclusiva do usuário.\n- O usuário deve armazenar suas senhas privadas com cuidado. O vazamento de senhas devido a anotações em locais inseguros pode permitir acesso malicioso aos fundos. A Mooze não se responsabiliza por perdas decorrentes de senhas vazadas por descuido do usuário ou por violações físicas ao aparelho. Evite armazenar senhas em locais digitais sem criptografia e prefira guardá-las em locais físicos seguros.\n- Acessos indevidos ao aparelho físico do usuário, seja por coação, furto ou perda, são de responsabilidade do usuário, que aceita esses termos ao utilizar o aplicativo.",
      ),
      TermsSection(
        "Limitação de Responsabilidade",
        "- A Mooze não se responsabiliza por perdas ou problemas decorrentes do uso do aplicativo, especialmente em casos de falhas de rede (como problemas em redes de registros distribuídos, soft/hard forks), operações não confirmadas ou erros de uso do usuário nessas redes. As redes de registros distribuídos, que escaneiam históricos de movimentações de unidades digitais, não são controladas pela Mooze, mas por terceiros, como Blockstream, Sideswap ou registros distribuídos de código aberto descentralizados.\n- O aplicativo Mooze opera em modo beta aberto, e o usuário concorda que problemas podem ocorrer até o lançamento de uma versão estável. Em caso de problemas críticos que impossibilitem a movimentação de unidades digitais, as senhas privadas dos usuários do aplicativo Mooze são compatíveis com o aplicativo Blockstream Green, permitindo a recuperação e movimentação das unidades digitais em casos de incompatibilidade crítica ou falhas no código do aplicativo em modo beta.\n- A Mooze e suas processadoras parceiras de unidades digitais não participam de atividades entre usuários e clientes. O aplicativo Mooze é apenas uma ponte tecnológica, agregando tecnologias de empresas como EULEN.APP e DEPIX.INFO. Em casos de uso comercial, a responsabilidade é do usuário. A Mooze não lida com questões contábeis ou fiscais (como emissão de notas fiscais). Os usuários podem regularizar suas operações conforme a legislação brasileira, utilizando, se necessário, a pessoa jurídica (CNPJ) das processadoras da EULEN.APP, como a Plebank.",
      ),
      TermsSection(
        "Apreço Monetário",
        "Para unidades digitais que não seguem o referencial de valor FIAT brasileiro, a Mooze realizará uma varredura das principais fontes de precificação do mercado para obter uma média e determinar seu preço monetário próprio no aplicativo.",
      ),
      TermsSection(
        "Tarifas e Confirmações",
        "a) Tarifas incluem:\n- Tarifas de rede (cobranças das redes de registros distribuídos).\n- Tarifas operacionais para operações em referencial de valor FIAT brasileiro das parceiras da EULEN.APP.\n- As unidades digitais transferidas ao usuário já incluem todas as tarifas mencionadas.\n\nb) Confirmações:\n- Em caso de problemas com transações instantâneas em referencial de valor FIAT brasileiro ou transferências de unidades digitais no aplicativo, contate o suporte em suporte@mooze.app.\n- Todas as operações são protegidas pela tecnologia da Liquid Network contra vazamento de dados e exposição a terceiros não envolvidos nas transferências.",
      ),
      TermsSection(
        "O que a Mooze NÃO Faz",
        "- A Mooze não realiza nem opera transações bancárias em referencial de valor FIAT. O aplicativo é apenas um agregador de tecnologias para transferências de unidades digitais por meio de transações em referencial de valor FIAT para o público de finanças alternativas.\n- A Mooze não realiza entradas ou saídas de transações financeiras com unidades digitais, não custodia unidades digitais, não atua como corretora nem realiza operações de corretagem.\n- A Mooze não realiza trocas de unidades digitais de diferentes paridades ou unidades monetárias. Essas operações são de responsabilidade da EULEN.APP e suas parceiras, que decidem aceitar ou processar as operações iniciadas pelos usuários. Em caso de bloqueios ou não processamento devido a comportamento malicioso identificado pelo sistema EULEN.APP via DEPIX.INFO ou suas parceiras, como a Plebank, as operações podem ser estornadas.",
      ),
      TermsSection(
        "O que a Mooze Faz",
        "- A Mooze agrega tecnologias de transferência de dados de unidades digitais por sistemas de registros distribuídos e conversão de unidades digitais, utilizando redes como a da Blockstream e outras descentralizadas de código aberto. Também utiliza sistemas de trocas de unidades digitais das empresas Sideswap, DEPIX.INFO, EULEN.APP e suas parceiras reguladas no Brasil. Novas tecnologias agregadas serão mencionadas em atualizações destes Termos de Uso.\n- A Mooze oferece suporte informacional aos usuários por canais eletrônicos, encaminhando informações e pedidos às empresas envolvidas, como a EULEN.APP e suas parceiras no Brasil, atuando como ponte entre o usuário e essas tecnologias.\n- A Mooze comunica-se em português ou inglês, dependendo da demanda ou entidade envolvida. Comunicações em português não implicam sede ou operação física no Brasil.",
      ),
      TermsSection(
        "Política Antifraude",
        "- A Mooze pode armazenar APP IDs, que são hashes criptográficos de dados como MediaDRM, IPv4, UUID, Device Check, entre outros, dependendo da plataforma. O objetivo é detectar uso humano real, evitar spam, ataques a servidores, uso por robôs, fraudes e proteger as parceiras processadoras da EULEN.APP.\n- Esses dados não identificam o usuário nem a natureza de transações específicas, não configuram captura de dados civis ou identificação pessoal e são usados apenas em casos de danos a terceiros causados pelo uso do aplicativo, como impactos nas operações das parceiras da EULEN.APP.",
      ),
      TermsSection(
        "Obrigações Legais",
        "- A Mooze não armazena dados pessoais abertos dos usuários.\n- O usuário é responsável por reportar unidades digitais reguladas legalmente no Brasil, conforme exigido pela legislação vigente, já que plataformas internacionais não têm obrigação de reporte direto ao Brasil.\n- Informações sobre unidades digitais para fins de declaração podem ser solicitadas via suporte@mooze.app.",
      ),
      TermsSection(
        "Das Jurisdições",
        "- A \"Otoco Matic LLC – Mooze – Series 99\" é a entidade que agrega as tecnologias mencionadas, doravante referida como \"Mooze\". Trata-se de uma Series LLC derivada da master LLC \"Otoco Matic LLC\", com jurisdição e sede nos Estados Unidos, estado de Wyoming.\n- Requisições legais sobre operações e estrutura da Mooze são respondidas sob a jurisdição de Wyoming, EUA.\n- As operações no Brasil, por meio do sistema agregado de transferências e trocas de unidades digitais em referencial de valor FIAT, são de responsabilidade jurídica das parceiras da EULEN.APP, como a Plebank (registro aqui), que cumpre todas as normativas e regulamentações legais no Brasil.",
      ),
      TermsSection(
        "Atualizações",
        "- A Mooze pode alterar os Termos de Uso e o aplicativo a qualquer momento. O uso contínuo implica aceitação das novas condições.\n- O usuário também concorda com a Política de Privacidade vinculada, disponível em https://mooze.app/termos-e-privacidade/.",
      ),
    ];
  }
}
