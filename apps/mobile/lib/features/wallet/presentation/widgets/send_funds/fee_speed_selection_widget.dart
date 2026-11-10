import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';

import 'custom_fee_rate_option.dart';

/// The fee speed choice of a Bitcoin on-chain send.
///
/// It shows only for BTC on the Bitcoin network. While the fee rates load,
/// a skeleton of the segmented control holds its place. With the custom fee
/// setting on, a custom rate follows the speeds: it replaces the selected
/// speed until the user picks a speed again.
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

  @override
  void initState() {
    super.initState();
    _loadFeeEstimates();
  }

  Future<void> _loadFeeEstimates() async {
    final bitcoinEstimate = await ref
        .read(bitcoinFeeServiceProvider)
        .fetchFeeEstimate();

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
    final customRate = ref.watch(customFeeRateProvider);
    final customEnabled = ref.watch(sendCustomFeeEnabledProvider);

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

    final estimate = _feeEstimate!;
    return Padding(
      key: const ValueKey('selector'),
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeeSpeedSelector(
            // A custom rate leaves no speed selected.
            selectedSpeed: customRate == null ? selectedSpeed : null,
            lowFeeLoading: true,
            onSpeedChanged: (speed) {
              ref.read(feeSpeedProvider.notifier).state = speed;
              ref.read(customFeeRateProvider.notifier).state = null;
            },
            lowFeeSatPerVByte: estimate.lowFeeSatPerVByte,
            mediumFeeSatPerVByte: estimate.mediumFeeSatPerVByte,
            fastFeeSatPerVByte: estimate.fastFeeSatPerVByte,
          ),
          if (customEnabled)
            CustomFeeRateOption(
              rate: customRate,
              estimate: estimate,
              onChanged: (rate) =>
                  ref.read(customFeeRateProvider.notifier).state = rate,
            ),
        ],
      ),
    );
  }
}

/// The shape of [FeeSpeedSelector] while the fee rates load: the title, and
/// the glass track at its height, so nothing moves when the rates arrive.
class _FeeSpeedSkeleton extends StatelessWidget {
  const _FeeSpeedSkeleton();

  /// Height of the track of three speeds at the default text size.
  static const double _trackHeight = 82;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: SkeletonBox(width: 140, height: 14),
          ),
          const SizedBox(height: 10),
          SkeletonBox(
            width: double.infinity,
            height: _trackHeight,
            radius: FeeSpeedSelector.radius.topLeft.x,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
