import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_network_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

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
    final asset = ref.watch(selectedAssetProvider);
    final blockchain = ref.watch(selectedNetworkProvider);
    final selectedSpeed = ref.watch(feeSpeedProvider);

    if (asset != Asset.btc || blockchain != Blockchain.bitcoin) {
      return const SizedBox.shrink();
    }

    if (_isLoadingFees) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_feeEstimate == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeeSpeedSelector(
          selectedSpeed: selectedSpeed,
          onSpeedChanged: (speed) {
            ref.read(feeSpeedProvider.notifier).state = speed;
          },
          lowFeeSatPerVByte: _feeEstimate!.lowFeeSatPerVByte,
          mediumFeeSatPerVByte: _feeEstimate!.mediumFeeSatPerVByte,
          fastFeeSatPerVByte: _feeEstimate!.fastFeeSatPerVByte,
        ),
      ],
    );
  }
}
