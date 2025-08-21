import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LevelSection {
  final String title;
  final String description;
  final IconData icon;
  final double limiteDiario;
  final double limiteMaximo;
  final List<String> beneficios;
  final Color levelColor;

  const LevelSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.limiteDiario,
    required this.limiteMaximo,
    required this.beneficios,
    required this.levelColor,
  });
}

class WalletLevelsScreen extends StatefulWidget {
  const WalletLevelsScreen({super.key});

  @override
  State<WalletLevelsScreen> createState() => _WalletLevelsScreenState();
}

class _WalletLevelsScreenState extends State<WalletLevelsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  final List<bool> _expandedSections = List.filled(5, false);
  
  final double _limiteAtual = 750.0;
  final double _limiteMaximoPossivel = 5000.0;
  final double _limiteMinimo = 20.0;
  final String _nivelAtual = "Satoshi";

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
      title: const Text('Níveis da Carteira'),
      leading: IconButton(
        onPressed: () {
          context.go('/menu');
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                const SizedBox(height: 16),
                _buildCurrentLimitsCard(colorScheme),
                const SizedBox(height: 24),
                _buildQuickInfo(colorScheme),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            ..._buildLevelSections(theme, colorScheme),
            const SizedBox(height: 32),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
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
                  'Cresça com a Mooze',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quanto mais você movimenta, mais benefícios e limites desbloqueia.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLimitsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seus Limites Atuais',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Nível: $_nivelAtual',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLimitInfo(
                  'Limite Atual',
                  'R\$ ${_limiteAtual.toStringAsFixed(0)}',
                  Icons.trending_up,
                  colorScheme.primary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitInfo(
                  'Máximo Possível',
                  'R\$ ${_limiteMaximoPossivel.toStringAsFixed(0)}',
                  Icons.flag,
                  colorScheme.secondary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLimitInfo(
                  'Mínimo',
                  'R\$ ${_limiteMinimo.toStringAsFixed(0)}',
                  Icons.low_priority,
                  colorScheme.tertiary,
                  colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _limiteAtual / _limiteMaximoPossivel,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Você está usando ${((_limiteAtual / _limiteMaximoPossivel) * 100).toInt()}% do limite máximo',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitInfo(String title, String value, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(ColorScheme colorScheme) {
    return SizedBox(
      height: 95,
      child: Center(
        child: Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.lock_open_rounded,
                title: 'Desbloqueie',
                subtitle: 'Aumente limites',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.redeem_rounded,
                title: 'Ganhe',
                subtitle: 'Benefícios extras',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.star_rate_rounded,
                title: 'Status',
                subtitle: 'Reconhecimento VIP',
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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

  List<Widget> _buildLevelSections(ThemeData theme, ColorScheme colorScheme) {
    final sections = _getLevelSections();
    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      final isCurrentLevel = section.title == _nivelAtual;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: isCurrentLevel ? 2 : 0,
          color: isCurrentLevel ? section.levelColor.withValues(alpha: 0.05) : colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrentLevel 
                ? section.levelColor.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.2),
              width: isCurrentLevel ? 2 : 1,
            ),
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
                  color: section.levelColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  section.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (isCurrentLevel) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: section.levelColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ATUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'Limite diário: R\$ ${section.limiteDiario.toStringAsFixed(0)} • Máximo: R\$ ${section.limiteMaximo.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: section.levelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getPreview(section.description),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          section.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: section.levelColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: section.levelColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 16,
                                  color: section.levelColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Limites do Nível',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLevelLimitCard(
                                    'Diário',
                                    'R\$ ${section.limiteDiario.toStringAsFixed(0)}',
                                    Icons.today,
                                    section.levelColor,
                                    colorScheme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildLevelLimitCard(
                                    'Máximo',
                                    'R\$ ${section.limiteMaximo.toStringAsFixed(0)}',
                                    Icons.trending_up,
                                    section.levelColor,
                                    colorScheme,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: section.levelColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Benefícios',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...section.beneficios.map((beneficio) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6, right: 8),
                                    decoration: BoxDecoration(
                                      color: section.levelColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      beneficio,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLevelLimitCard(String title, String value, IconData icon, Color levelColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: levelColor),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getPreview(String content) {
    return content.length > 80 ? '${content.substring(0, 80)}...' : content;
  }

  Widget _buildBackToTopButton(ColorScheme colorScheme) {
    return FloatingActionButton.small(
      onPressed: _scrollToTop,
      elevation: 4,
      child: const Icon(Icons.keyboard_arrow_up_rounded),
    );
  }

  List<LevelSection> _getLevelSections() {
    return [
      LevelSection(
        title: "Satoshi",
        description: "Comece movimentando pequenos valores e desbloqueie os primeiros benefícios. Ideal para quem está começando no mundo das criptomoedas.",
        icon: Icons.energy_savings_leaf_rounded,
        limiteDiario: 500.0,
        limiteMaximo: 750.0,
        levelColor: const Color(0xFF4CAF50),
        beneficios: [
          "Transações básicas disponíveis",
          "Suporte por chat",
          "Taxa padrão em todas as operações",
          "Acesso ao app mobile",
        ],
      ),
      LevelSection(
        title: "Minerador",
        description: "Quanto mais você gasta, mais sobe de nível. Torne-se um minerador e aumente seus limites para movimentações maiores.",
        icon: Icons.construction_rounded,
        limiteDiario: 1500.0,
        limiteMaximo: 2000.0,
        levelColor: const Color(0xFF2196F3),
        beneficios: [
          "Limite diário aumentado",
          "Desconto de 5% nas taxas",
          "Suporte prioritário",
          "Relatórios mensais detalhados",
          "Notificações personalizadas",
        ],
      ),
      LevelSection(
        title: "Hodler",
        description: "Mantenha uso frequente da carteira e alcance benefícios exclusivos e funcionalidades avançadas.",
        icon: Icons.shield_rounded,
        limiteDiario: 3000.0,
        limiteMaximo: 3500.0,
        levelColor: const Color(0xFF9C27B0),
        beneficios: [
          "Autenticação em dois fatores premium",
          "Desconto de 10% nas taxas",
          "Suporte 24/7",
          "Acesso antecipado a novas funcionalidades",
          "Backup automático da carteira",
          "Programa de cashback",
        ],
      ),
      LevelSection(
        title: "Whale",
        description: "Você já movimenta grandes volumes. Tenha status de baleia e acesso a limites premium para grandes investidores.",
        icon: Icons.water,
        limiteDiario: 4500.0,
        limiteMaximo: 5000.0,
        levelColor: const Color(0xFFFF9800),
        beneficios: [
          "Limites premium para grandes volumes",
          "Desconto de 15% nas taxas",
          "Gerente de conta dedicado",
          "Análises de mercado exclusivas",
          "Acesso a produtos de investimento VIP",
          "Execução prioritária de ordens",
          "Eventos exclusivos para baleias",
        ],
      ),
      LevelSection(
        title: "Nakamoto",
        description: "O nível máximo! Reconhecimento VIP, limites no topo e benefícios exclusivos. Para os verdadeiros magnatas do Bitcoin.",
        icon: Icons.workspace_premium_rounded,
        limiteDiario: 10000.0,
        limiteMaximo: 15000.0,
        levelColor: const Color(0xFFFFD700),
        beneficios: [
          "Limites ilimitados para grandes volumes",
          "Taxa zero em todas as operações",
          "Suporte VIP 24/7 com linha direta",
          "Consultoria financeira personalizada",
          "Acesso completo a todos os produtos",
          "Programa de recompensas premium",
          "Badge exclusivo Nakamoto",
          "Convites para eventos especiais",
          "API dedicada para trading automatizado",
        ],
      ),
    ];
  }
}