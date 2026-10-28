import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_header_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/period_selector_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_chart_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_detail/asset_stats_widget.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_icon_hero.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen>
    with SingleTickerProviderStateMixin {
  TimePeriod selectedPeriod = TimePeriod.day;
  late final AnimationController _entryController = AnimationController(
    duration: Motion.durationEmphasis,
    vsync: this,
  );
  late final CurvedAnimation _entryAnimation = CurvedAnimation(
    parent: _entryController,
    curve: Motion.curveEnter,
  );
  bool _entryStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    // Reduced motion shows the content without an entrance.
    if (Motion.isReduced(context)) {
      _entryController.value = 1;
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryAnimation.dispose();
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
            // Hero target of the home asset row icon. It sits outside the
            // body entrance, so the flight lands on a fixed position.
            AssetIconHero(asset: widget.asset, size: 22),
            const SizedBox(width: 8),
            Text(widget.asset.name),
          ],
        ),
        centerTitle: true,
      ),
      body: FadeSlideIn(
        animation: _entryAnimation,
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
    );
  }
}
