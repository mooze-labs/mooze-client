import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PixFeesScreen extends StatefulWidget {
  const PixFeesScreen({super.key});

  @override
  State<PixFeesScreen> createState() => _PixFeesScreenState();
}

class _PixFeesScreenState extends State<PixFeesScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      title: const Text('Taxas do PIX'),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        tooltip: 'Voltar',
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 32),
            _buildFixedFeeCard(colorScheme),
            const SizedBox(height: 24),
            _buildFeeRangesSection(colorScheme),
            const SizedBox(height: 24),
            _buildReferralBonusCard(colorScheme),
            const SizedBox(height: 24),
            _buildExamplesSection(colorScheme),
            const SizedBox(height: 32),
            _buildFooterInfo(colorScheme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas Transparentes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conheça nossas taxas de depósito via PIX',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedFeeCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxa Fixa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Para depósitos até R\$ 55,00',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R\$ 2,00',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ 1,00 Mooze + R\$ 1,00 Processadora',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRangesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taxas Percentuais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para depósitos acima de R\$ 55,00',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Sem Desconto'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Com Desconto'),
                        SizedBox(width: 4),
                        Icon(Icons.card_giftcard, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeeRangesList(colorScheme, false),
                    _buildFeeRangesList(colorScheme, true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRangesList(ColorScheme colorScheme, bool withDiscount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeeRangeCard(
            colorScheme: colorScheme,
            rangeLabel: 'R\$ 55 até R\$ 499',
            baseFeePercentage: 3.5,
            withDiscount: withDiscount,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeeRangeCard(
            colorScheme: colorScheme,
            rangeLabel: 'R\$ 500 até R\$ 3.000',
            baseFeePercentage: 3.0,
            withDiscount: withDiscount,
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRangeCard({
    required ColorScheme colorScheme,
    required String rangeLabel,
    required double baseFeePercentage,
    required bool withDiscount,
    required Gradient gradient,
  }) {
    final displayFee =
        withDiscount ? baseFeePercentage * 0.85 : baseFeePercentage;
    final feeText = displayFee.toStringAsFixed(2).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient.colors.first.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rangeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (withDiscount) ...[
                  const SizedBox(height: 4),
                  Text(
                    'antes ${baseFeePercentage.toStringAsFixed(2).replaceAll('.', ',')}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$feeText%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: gradient.colors.first,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralBonusCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.2),
            const Color(0xFF66BB6A).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bônus de Indicação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Use um código de indicação',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '15% de desconto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Todas as taxas percentuais são multiplicadas por 0,85',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Exemplos Práticos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // R$ 30,00 → taxa fixa
        _buildExampleCard(
          colorScheme: colorScheme,
          depositAmount: 'R\$ 30,00',
          fee: 'R\$ 2,00',
          youReceive: 'R\$ 28,00',
          hasReferral: false,
        ),

        const SizedBox(height: 12),

        // R$ 300,00 → 3,5%
        _buildExampleCard(
          colorScheme: colorScheme,
          depositAmount: 'R\$ 300,00',
          fee: 'R\$ 10,50',
          youReceive: 'R\$ 289,50',
          hasReferral: false,
          feeCalculation: '3,5% de R\$ 300,00',
        ),

        const SizedBox(height: 12),

        // R$ 300,00 com referral (2,975%)
        _buildExampleCard(
          colorScheme: colorScheme,
          depositAmount: 'R\$ 300,00',
          fee: 'R\$ 8,93',
          youReceive: 'R\$ 291,07',
          hasReferral: true,
          feeCalculation: '3,5% × 0,85 = 2,975%',
          originalAmount: 'R\$ 289,50',
        ),

        const SizedBox(height: 12),

        // R$ 1.000,00 → 3%
        _buildExampleCard(
          colorScheme: colorScheme,
          depositAmount: 'R\$ 1.000,00',
          fee: 'R\$ 30,00',
          youReceive: 'R\$ 970,00',
          hasReferral: false,
          feeCalculation: '3% de R\$ 1.000,00',
        ),

        const SizedBox(height: 12),

        // R$ 3.000,00 → 3%
        _buildExampleCard(
          colorScheme: colorScheme,
          depositAmount: 'R\$ 3.000,00',
          fee: 'R\$ 90,00',
          youReceive: 'R\$ 2.910,00',
          hasReferral: false,
          feeCalculation: '3% de R\$ 3.000,00',
        ),
      ],
    );
  }

  Widget _buildExampleCard({
    required ColorScheme colorScheme,
    required String depositAmount,
    required String fee,
    required String youReceive,
    required bool hasReferral,
    String? feeCalculation,
    String? originalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasReferral
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          if (hasReferral)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Com indicação',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Depósito',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    depositAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Você recebe',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        youReceive,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              hasReferral
                                  ? const Color(0xFF4CAF50)
                                  : colorScheme.onSurface,
                        ),
                      ),
                      if (hasReferral && originalAmount != null) ...[
                        Text(
                          originalAmount,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  feeCalculation ?? 'Taxa',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  fee,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informações Importantes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            colorScheme: colorScheme,
            text:
                'A taxa fixa de R\$ 2,00 se aplica apenas a depósitos até R\$ 55,00',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            colorScheme: colorScheme,
            text:
                'Para valores acima de R\$ 55,00, as taxas percentuais são aplicadas',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            colorScheme: colorScheme,
            text:
                'O desconto de 15% com indicação se aplica apenas às taxas percentuais',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            colorScheme: colorScheme,
            text: 'As taxas são deduzidas automaticamente do valor depositado',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required ColorScheme colorScheme,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToTopButton(ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: _scrollToTop,
      backgroundColor: colorScheme.primary,
      child: const Icon(Icons.arrow_upward_rounded),
    );
  }
}
