import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/widgets/asset_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/widgets/period_selector_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/widgets/asset_chart_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/widgets/asset_stats_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen>
    with TickerProviderStateMixin {
  TimePeriod selectedPeriod = TimePeriod.day;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            widget.asset.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com informações do ativo
              SlideTransition(
                position: _slideAnimation,
                child: AssetHeaderWidget(asset: widget.asset),
              ),

              const SizedBox(height: 32),

              // Seletor de período
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
                  ),
                ),
                child: PeriodSelectorWidget(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Gráfico principal
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
                  ),
                ),
                child: AssetChartWidget(
                  asset: widget.asset,
                  selectedPeriod: selectedPeriod,
                ),
              ),

              const SizedBox(height: 32),

              // Estatísticas detalhadas
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
                  ),
                ),
                child: AssetStatsWidget(
                  asset: widget.asset,
                  selectedPeriod: selectedPeriod,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
