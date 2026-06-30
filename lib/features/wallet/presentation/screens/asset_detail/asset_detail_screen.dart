import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_chart_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_stats_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen>
    with SingleTickerProviderStateMixin {
  TimePeriod selectedPeriod = TimePeriod.day;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(widget.asset.iconPath, width: 22, height: 22),
            const SizedBox(width: 8),
            Text(widget.asset.name),
          ],
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssetHeaderWidget(asset: widget.asset),

                const SizedBox(height: 32),

                PeriodSelectorWidget(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() => selectedPeriod = period);
                  },
                ),

                const SizedBox(height: 16),

                AssetChartWidget(
                  asset: widget.asset,
                  selectedPeriod: selectedPeriod,
                ),

                const SizedBox(height: 24),

                AssetStatsWidget(
                  asset: widget.asset,
                  selectedPeriod: selectedPeriod,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
