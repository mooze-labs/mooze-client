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

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late final List<bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _expandedSections = List<bool>.filled(_licenseSections.length, false);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Licença GPL v3'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Voltar',
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
                    icon: Icons.description_rounded,
                    title: 'Licença GPL v3',
                    subtitle: 'GNU General Public License',
                    description:
                        'Versão 3, 29 de junho de 2007 • Free Software Foundation',
                  ),
                  const SizedBox(height: 24),
                  LegalDocumentWarningCard(
                    icon: Icons.info_rounded,
                    title: 'Copyleft License',
                    message:
                        'Esta licença garante que o software permaneça livre. Qualquer distribuição deve incluir o código-fonte.',
                    containerColor:
                        colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderColor:
                        colorScheme.tertiary.withValues(alpha: 0.3),
                    iconColor: colorScheme.tertiary,
                    textColor: colorScheme.onTertiaryContainer,
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
                  section: _licenseSections[index],
                  isExpanded: _expandedSections[index],
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedSections[index] = expanded);
                  },
                  showInfoIconForFirst: true,
                  useMonospaceContent: true,
                );
              },
              childCount: _licenseSections.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Center(child: Text('FIM DOS TERMOS E CONDIÇÕES')),
                const SizedBox(height: 16),
                _buildFooter(colorScheme),
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
              icon: Icons.lock_open_rounded,
              title: 'Software Livre',
              subtitle: 'Liberdade garantida',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.share_rounded,
              title: 'Redistribuível',
              subtitle: 'Com código-fonte',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LegalDocumentInfoCard(
              icon: Icons.code_rounded,
              title: 'Copyleft',
              subtitle: 'Derivados livres',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.copyright_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Copyright © 2007 Free Software Foundation, Inc.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LegalDocumentFooterLink(
                icon: Icons.public_rounded,
                label: 'Free Software Foundation',
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                onTap: () => _launchUrl('https://www.fsf.org/'),
              ),
              const SizedBox(height: 8),
              LegalDocumentFooterLink(
                icon: Icons.article_outlined,
                label: 'Licença Completa',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                onTap: () => _launchUrl(
                  'https://www.gnu.org/licenses/gpl-3.0.html',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _licenseSections = [
  LegalDocumentSection(
    "Preâmbulo",
    "A Licença Pública Geral GNU é uma licença livre, com copyleft, para softwares e outros tipos de trabalhos.\n\nAs licenças para a maioria dos softwares e outros trabalhos práticos são projetadas para tirar sua liberdade de compartilhar e alterar os trabalhos. Em contrapartida, a Licença Pública Geral GNU destina-se a garantir a sua liberdade de compartilhar e alterar todas as versões de um programa – para se certificar de que permaneça como software livre para todos os seus usuários.\n\nQuando falamos de software livre, estamos nos referindo à liberdade, não ao preço. Nossas Licenças Públicas Gerais são projetadas para garantir que você tenha a liberdade de distribuir cópias de software livre (e cobrar por elas, se desejar), que você receba o código-fonte ou possa obtê-lo, se desejar, que você possa mudar o software ou usar partes dele em novos programas livres e que você saiba que pode fazer essas coisas.",
  ),
  LegalDocumentSection(
    "Definições",
    "\"Essa Licença\" refere-se à versão 3 da Licença Pública Geral GNU.\n\n\"Copyright\", ou \"direitos autorais\", também significa leis do tipo direito autoral que se aplicam a outros tipos de trabalhos, tal como máscaras de semicondutores.\n\n\"O Programa\" refere-se a qualquer trabalho com direito autoral licenciado sob esta Licença. Cada licenciado é endereçado como \"você\". \"Licenciados\" e \"destinatários\" podem ser indivíduos ou organizações.\n\n\"Modificar\" um trabalho significa copiar ou adaptar tudo ou parte do trabalho de uma forma a ser necessário ter permissão de direitos autorais, além da criação de uma cópia exata.",
  ),
  LegalDocumentSection(
    "Código-fonte",
    "O \"código-fonte\" para um trabalho significa a forma preferida do trabalho para fazer modificações nele. \"Código objeto\" significa qualquer forma não fonte de um trabalho.\n\nUma \"Interface Padrão\" significa uma interface que seja um padrão oficial definido por um corpo de padrões reconhecido ou, no caso de interfaces especificadas para uma linguagem de programação específica, que seja amplamente utilizada entre desenvolvedores que trabalham naquela linguagem.",
  ),
  LegalDocumentSection(
    "Permissões Básicas",
    "Todos os direitos concedidos sob esta Licença são concedidos para o termo de direito autoral sobre o Programa e são irrevogáveis desde que as condições estabelecidas sejam atendidas. Esta Licença afirma explicitamente a sua permissão ilimitada para executar o Programa não modificado.\n\nVocê pode fazer, executar e propagar trabalhos cobertos que você não transmite, sem condições, desde que sua licença permaneça em vigor.",
  ),
  LegalDocumentSection(
    "Protegendo os Direitos Legais dos Usuários",
    "Nenhum trabalho coberto deve ser considerado parte de uma medida tecnológica efetiva sob qualquer lei aplicável que cumpra as obrigações previstas no artigo 11 do tratado de direitos autorais da OMPI.\n\nQuando você transmite um trabalho coberto, você renuncia a qualquer poder legal para proibir a evasão de medidas tecnológicas.",
  ),
  LegalDocumentSection(
    "Transmitindo Cópias Literais",
    "Você pode transmitir cópias literais do código-fonte do Programa na medida que você o recebe, em qualquer meio, desde que você publique de forma consistente e apropriada em cada cópia um aviso de direitos autorais apropriado.\n\nVocê pode cobrar qualquer preço ou nenhum preço por cada cópia que você transmite, e você pode oferecer proteção de suporte ou garantia por uma taxa.",
  ),
  LegalDocumentSection(
    "Transmitindo Versões Modificadas dos Fontes",
    "Você pode transmitir um trabalho baseado no Programa, ou as modificações para produzi-lo a partir do Programa, na forma de código-fonte sob os termos da seção 4, desde que você também atenda a todas essas condições:\n\na) O trabalho deve levar avisos proeminentes afirmando que você o modificou e dando uma data relevante.\nb) O trabalho deve levar avisos proeminentes afirmando que ele está lançado sob esta Licença.",
  ),
  LegalDocumentSection(
    "Transmitindo Formas Não Fonte",
    "Você pode transmitir um trabalho coberto na forma de código objeto nos termos das seções 4 e 5, desde que você também transmita o Fonte Correspondente legível por máquina sob os termos desta Licença.\n\nO Fonte Correspondente pode estar em um servidor diferente (operado por você ou um terceiro) que suporte instalações de cópia equivalentes.",
  ),
  LegalDocumentSection(
    "Termos Adicionais",
    "\"Permissões adicionais\" são termos que complementam os termos desta Licença fazendo exceções de uma ou mais de suas condições. As permissões adicionais que são aplicáveis a todo o Programa devem ser tratadas como se estivessem incluídas nesta Licença.\n\nVocê pode colocar permissões adicionais em material, adicionado por você a um trabalho coberto, para o qual você tenha ou possa dar permissão de direitos autorais apropriados.",
  ),
  LegalDocumentSection(
    "Terminação",
    "Você não pode propagar ou modificar um trabalho coberto, exceto conforme expressamente previsto nesta Licença. Qualquer tentativa de propagar ou modificá-la é inválida e terminará automaticamente os seus direitos sob esta Licença.\n\nNo entanto, se você cessar toda violação desta Licença, a sua licença de um detentor de direitos autorais específicos é reintegrada provisoriamente.",
  ),
  LegalDocumentSection(
    "Aceitação Não Exigida para Ter Cópias",
    "Você não é obrigado a aceitar esta Licença para receber ou executar uma cópia do Programa. A propagação auxiliar de um trabalho coberto que ocorre apenas como consequência da utilização da transmissão ponto a ponto para receber uma cópia também não exige aceitação.",
  ),
  LegalDocumentSection(
    "Licenciamento Automático de Destinatários Downstream",
    "Cada vez que você transmite um trabalho coberto, o destinatário recebe automaticamente uma licença dos licenciadores originais, para executar, modificar e propagar esse trabalho, sujeito a esta Licença.\n\nVocê não pode impor restrições adicionais sobre o exercício dos direitos concedidos ou afirmados sob esta Licença.",
  ),
  LegalDocumentSection(
    "Patentes",
    "Um \"contribuidor\" é um detentor de direitos autorais que autoriza o uso sob esta Licença do Programa ou um trabalho no qual o Programa se baseia.\n\nCada contribuidor concede-lhe uma licença de patente não exclusiva, mundial, livre de royalties sob os principais pedidos de patente do contribuidor.",
  ),
  LegalDocumentSection(
    "Não Entregar a Liberdade dos Outros",
    "Se as condições que forem impostas a você (seja por ordem judicial, acordo ou de outra forma) contradizem as condições desta Licença, elas não lhe eximem das condições desta Licença.\n\nSe você não pode transmitir um trabalho coberto para satisfazer simultaneamente suas obrigações sob esta Licença e quaisquer outras obrigações pertinentes, então você não pode transmitir isso.",
  ),
  LegalDocumentSection(
    "Uso com a Licença Pública Geral Affero GNU",
    "Não obstante qualquer outra disposição desta Licença, você tem permissão para vincular ou combinar qualquer trabalho coberto com um trabalho licenciado sob a versão 3 da Licença Pública Geral Affero GNU em um único trabalho combinado.",
  ),
  LegalDocumentSection(
    "Versões Revisadas desta Licença",
    "A Free Software Foundation pode publicar versões periódicas e/ou novas da Licença Pública Geral GNU de tempos em tempos. Essas novas versões serão semelhantes em espírito à versão atual, mas podem diferir em detalhes para resolver novos problemas ou preocupações.\n\nCada versão recebe um número de versão distinto.",
  ),
  LegalDocumentSection(
    "Aviso Legal de Garantia",
    "NÃO HÁ NENHUMA GARANTIA PARA O PROGRAMA, NA EXTENSÃO PERMITIDA PELA LEI APLICÁVEL. EXCETO QUANDO TUDO INDICADO POR ESCRITO, OS DETENTORES DE DIREITOS AUTORAIS E/OU OUTRAS PARTES FORNECEM O PROGRAMA \"COMO ESTÁ\" SEM GARANTIA DE QUALQUER TIPO.\n\nTODO O RISCO SOBRE A QUALIDADE E O DESEMPENHO DO PROGRAMA ESTÁ COM VOCÊ. SE O PROGRAMA APRESENTAR DEFEITO, VOCÊ ASSUME O CUSTO DE TODA A MANUTENÇÃO, REPARAÇÃO OU CORREÇÃO NECESSÁRIA.",
  ),
  LegalDocumentSection(
    "Limitação de Responsabilidade",
    "EM NENHUM CASO, A MENOS QUE EXIGIDO PELA LEI APLICÁVEL OU ACORDADO POR ESCRITO, QUALQUER DETENTOR DE DIREITOS AUTORAIS, OU QUALQUER OUTRA PARTE QUE MODIFICA E/OU TRANSMITE O PROGRAMA COMO PERMITIDO ACIMA, SE RESPONSABILIZARÁ POR DANOS.\n\nISTO INCLUI QUALQUER DANO GERAL, ESPECIAL, INCIDENTAL OU CONSEQUENCIAL QUE SURGIR DO USO OU INCAPACIDADE DE USAR O PROGRAMA, MESMO SE TAL DETENTOR OU OUTRA PARTE TENHA SIDO AVISADO DA POSSIBILIDADE DE TAIS DANOS.",
  ),
  LegalDocumentSection(
    "Interpretação das Seções 15 e 16",
    "Se a renúncia de garantia e a limitação de responsabilidade previstos acima não puderem ter efeito legal local de acordo com seus termos, os tribunais revisionais aplicarão a lei local que se aproxima mais de uma renúncia absoluta a toda a responsabilidade civil em conexão com o Programa, a menos que uma garantia ou suposição de responsabilidade acompanhe uma cópia do Programa em troca de uma taxa.",
  ),
];
