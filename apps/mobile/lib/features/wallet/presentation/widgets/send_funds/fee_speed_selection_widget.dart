import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';

/// The fee speed choice of a Bitcoin on-chain send.
///
/// It shows only for BTC on the Bitcoin network. While the fee rates load,
/// a skeleton of the segmented control holds its place.
class FeeSpeedSelectionWidget extends ConsumerStatefulWidget {
  const FeeSpeedSelectionWidget({super.key});

  @override
  ConsumerState<FeeSpeedSelectionWidget> createState() =>
      _FeeSpeedSelectionWidgetState();
}

class _FeeSpeedSelectionWidgetState
    extends ConsumerState<FeeSpeedSelectionWidget> {
  bool _isLoadingFees = true;
  BitcoinFeeEstimate? _feeEstimate;
  final _feeService = BitcoinFeeService();

  @override
  void initState() {
    super.initState();
    _loadFeeEstimates();
  }

  Future<void> _loadFeeEstimates() async {
    final bitcoinEstimate = await _feeService.fetchFeeEstimate();

    if (bitcoinEstimate == null) {
      if (mounted) {
        setState(() {
          _isLoadingFees = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _feeEstimate = bitcoinEstimate;
        _isLoadingFees = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeFadeSwitcher(child: _content(context));
  }

  Widget _content(BuildContext context) {
    const none = SizedBox(key: ValueKey('none'), width: double.infinity);
    final asset = ref.watch(selectedAssetProvider);
    final blockchain = ref.watch(selectedNetworkProvider);
    final selectedSpeed = ref.watch(feeSpeedProvider);

    if (asset != Asset.btc || blockchain != Blockchain.bitcoin) {
      return none;
    }

    if (_isLoadingFees) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.only(top: 28),
        child: _FeeSpeedSkeleton(),
      );
    }

    if (_feeEstimate == null) {
      return none;
    }

    return Padding(
      key: const ValueKey('selector'),
      padding: const EdgeInsets.only(top: 28),
      child: FeeSpeedSelector(
        selectedSpeed: selectedSpeed,
        lowFeeLoading: true,
        onSpeedChanged: (speed) {
          ref.read(feeSpeedProvider.notifier).state = speed;
        },
        lowFeeSatPerVByte: _feeEstimate!.lowFeeSatPerVByte,
        mediumFeeSatPerVByte: _feeEstimate!.mediumFeeSatPerVByte,
        fastFeeSatPerVByte: _feeEstimate!.fastFeeSatPerVByte,
      ),
    );
  }
}

/// The shape of [FeeSpeedSelector] while the fee rates load.
class _FeeSpeedSkeleton extends StatelessWidget {
  const _FeeSpeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 140, height: 14),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                const Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 64,
                    radius: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
