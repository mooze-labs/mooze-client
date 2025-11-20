import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/swap/presentation/controllers/btc_lbtc_swap_controller.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class BtcLbtcConfirmBottomSheet extends ConsumerStatefulWidget {
  final BigInt amount;
  final bool isPegIn;
  final BtcLbtcSwapController controller;
  final Future<void> Function(int? feeRateSatPerVByte) onConfirm;
  final VoidCallback? onCancel;
  final bool drain;

  const BtcLbtcConfirmBottomSheet({
    super.key,
    required this.amount,
    required this.isPegIn,
    required this.controller,
    required this.onConfirm,
    this.onCancel,
    this.drain = false,
  });

  static void show(
    BuildContext context, {
    required BigInt amount,
    required bool isPegIn,
    required BtcLbtcSwapController controller,
    required Future<void> Function(int? feeRateSatPerVByte) onConfirm,
    VoidCallback? onCancel,
    bool drain = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BtcLbtcConfirmBottomSheet(
            amount: amount,
            isPegIn: isPegIn,
            controller: controller,
            onConfirm: onConfirm,
            onCancel: onCancel,
            drain: drain,
          ),
    );
  }

  @override
  ConsumerState<BtcLbtcConfirmBottomSheet> createState() =>
      _BtcLbtcConfirmBottomSheetState();
}

class _BtcLbtcConfirmBottomSheetState
    extends ConsumerState<BtcLbtcConfirmBottomSheet> {
  bool _isConfirming = false;
  bool _isLoadingFees = true;
  FeeSpeed _selectedFeeSpeed = FeeSpeed.medium;
  BitcoinFeeEstimate? _feeEstimate;
  BtcLbtcFeeEstimate? _currentFeeEstimate;
  final _feeService = BitcoinFeeService();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print(
        '[BtcLbtcConfirmBottomSheet] initState - drain: ${widget.drain}, amount: ${widget.amount}',
      );
    }
    _loadFeeEstimates();
  }

  Future<void> _loadFeeEstimates() async {
    if (kDebugMode) {
      print(
        '[BtcLbtcConfirmBottomSheet] _loadFeeEstimates - drain: ${widget.drain}',
      );
    }

    final bitcoinEstimate = await _feeService.fetchFeeEstimate();

    if (bitcoinEstimate == null && kDebugMode) {
      print('[BtcLbtcConfirm] Failed to fetch fee estimates from APIs');
    }

    final feeRate = bitcoinEstimate?.mediumFeeSatPerVByte;
    final feeEstimateResult =
        await widget.controller
            .prepareFeeEstimate(
              amount: widget.amount,
              isPegIn: widget.isPegIn,
              feeRateSatPerVByte: feeRate,
              drain: widget.drain,
            )
            .run();

    if (mounted) {
      setState(() {
        _feeEstimate = bitcoinEstimate;
        _currentFeeEstimate = feeEstimateResult.fold(
          (error) {
            if (kDebugMode) {
              print('[BtcLbtcConfirm] Error loading fee estimate: $error');
            }
            return null;
          },
          (estimate) {
            if (kDebugMode) {
              print(
                '[BtcLbtcConfirm] Fee estimate loaded - Boltz: ${estimate.boltzServiceFeeSat}, Network: ${estimate.networkFeeSat}, Total: ${estimate.totalFeeSat}',
              );
              if (widget.drain) {
                print(
                  '[BtcLbtcConfirm] Drain mode - SDK calculated fees with rate: ${feeRate} sat/vB',
                );
              }
            }

            return estimate;
          },
        );
        _isLoadingFees = false;
      });
    }
  }

  Future<void> _onFeeSpeedChanged(FeeSpeed speed) async {
    if (kDebugMode) {
      print(
        '[BtcLbtcConfirmBottomSheet] _onFeeSpeedChanged - speed: $speed, drain: ${widget.drain}',
      );
    }

    setState(() {
      _selectedFeeSpeed = speed;
      _isLoadingFees = true;
    });

    final feeRate = _getSelectedFeeRate();
    if (kDebugMode) {
      print(
        '[BtcLbtcConfirmBottomSheet] Selected fee rate: $feeRate sat/vB for speed: $speed',
      );
    }

    final feeEstimateResult =
        await widget.controller
            .prepareFeeEstimate(
              amount: widget.amount,
              isPegIn: widget.isPegIn,
              feeRateSatPerVByte: feeRate,
              drain: widget.drain,
            )
            .run();

    if (mounted) {
      setState(() {
        _currentFeeEstimate = feeEstimateResult.fold(
          (error) {
            if (kDebugMode) {
              print('[BtcLbtcConfirm] Error updating fee estimate: $error');
            }
            return _currentFeeEstimate;
          },
          (estimate) {
            if (kDebugMode) {
              print(
                '[BtcLbtcConfirm] Fee estimate updated - Boltz: ${estimate.boltzServiceFeeSat}, Network: ${estimate.networkFeeSat}, Total: ${estimate.totalFeeSat}',
              );
              if (widget.drain) {
                print(
                  '[BtcLbtcConfirm] Drain mode - SDK recalculated fees with rate: $feeRate sat/vB',
                );
              }
            }

            return estimate;
          },
        );
        _isLoadingFees = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountBtc = widget.amount.toDouble() / 100000000;
    final fromAsset = widget.isPegIn ? core.Asset.btc : core.Asset.lbtc;
    final toAsset = widget.isPegIn ? core.Asset.lbtc : core.Asset.btc;

    final boltzFeeSat = _currentFeeEstimate?.boltzServiceFeeSat ?? BigInt.zero;
    final networkFeeSat = _currentFeeEstimate?.networkFeeSat ?? BigInt.zero;
    final totalFeeSat = _currentFeeEstimate?.totalFeeSat ?? BigInt.zero;

    final totalFeeBtc = totalFeeSat.toDouble() / 100000000;
    final receivedAmount = amountBtc - totalFeeBtc;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Text(
                'Confirmar Swap',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _fromToSummary(
                      context,
                      fromAsset,
                      toAsset,
                      amountBtc,
                      receivedAmount,
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (_feeEstimate != null) ...[
                      FeeSpeedSelector(
                        selectedSpeed: _selectedFeeSpeed,
                        onSpeedChanged: _onFeeSpeedChanged,
                        lowFeeSatPerVByte: _feeEstimate!.lowFeeSatPerVByte,
                        mediumFeeSatPerVByte:
                            _feeEstimate!.mediumFeeSatPerVByte,
                        fastFeeSatPerVByte: _feeEstimate!.fastFeeSatPerVByte,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    _buildFeeBreakdown(
                      boltzFeeSat: boltzFeeSat,
                      networkFeeSat: networkFeeSat,
                      totalFeeSat: totalFeeSat,
                      isLoading: _isLoadingFees,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SlideToConfirmButton(
              text: _isConfirming ? 'Confirmando...' : 'Confirmar Swap',
              isLoading: _isConfirming || _isLoadingFees,
              onSlideComplete:
                  (_isConfirming || _isLoadingFees) ? () {} : _handleConfirm,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown({
    required BigInt boltzFeeSat,
    required BigInt networkFeeSat,
    required BigInt totalFeeSat,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimativa',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getEstimatedTime(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _FeeRow(
                label: 'Enviando:',
                value: '${widget.amount} sats',
                valueColor: Colors.white,
                isBold: false,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              if (!isLoading && boltzFeeSat > BigInt.zero || isLoading) ...[
                _FeeRow(
                  label: 'Taxa de serviço da Boltz:',
                  value: isLoading ? '' : '-${boltzFeeSat} sats',
                  valueColor: Colors.grey[400],
                  isBold: false,
                  isLoading: isLoading,
                ),
              ],
              _FeeRow(
                label: 'Taxa da transação:',
                value: isLoading ? '' : '-${networkFeeSat} sats',
                valueColor: Colors.grey[400],
                isBold: false,
                isLoading: isLoading,
              ),
              _FeeRow(
                label: 'Total de taxas:',
                value: isLoading ? '' : '-${networkFeeSat + boltzFeeSat} sats',
                valueColor: Colors.grey[400],
                isBold: false,
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.grey[700]),
              const SizedBox(height: 16),
              _FeeRow(
                label: 'Recebendo:',
                value: isLoading ? '' : '${widget.amount - totalFeeSat} sats',
                valueColor: Colors.white,
                isBold: true,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDollarValue(BigInt sats) {
    final btc = sats.toDouble() / 100000000;
    final dollarValue = btc * 91300;
    return dollarValue.toStringAsFixed(2);
  }

  String _getEstimatedTime() {
    switch (_selectedFeeSpeed) {
      case FeeSpeed.low:
        return '~60+ minutos';
      case FeeSpeed.medium:
        return '~30 minutos';
      case FeeSpeed.fast:
        return '~10 minutos';
    }
  }

  int? _getSelectedFeeRate() {
    if (_feeEstimate == null) return null;

    switch (_selectedFeeSpeed) {
      case FeeSpeed.low:
        return _feeEstimate!.lowFeeSatPerVByte;
      case FeeSpeed.medium:
        return _feeEstimate!.mediumFeeSatPerVByte;
      case FeeSpeed.fast:
        return _feeEstimate!.fastFeeSatPerVByte;
    }
  }

  Future<void> _handleConfirm() async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      await widget.onConfirm(_getSelectedFeeRate());
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Widget _fromToSummary(
    BuildContext context,
    core.Asset sendAsset,
    core.Asset receiveAsset,
    double sendAmount,
    double receiveAmount,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2D2E2A), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você envia'),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        sendAsset.iconPath,
                        width: 15,
                        height: 15,
                      ),
                    ],
                  ),
                  Text(
                    sendAmount.toStringAsFixed(8),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(sendAsset.name.toLowerCase()),
                ],
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/icons/menu/arrow.svg',
                width: 25,
                height: 25,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você recebe'),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        receiveAsset.iconPath,
                        width: 15,
                        height: 15,
                      ),
                    ],
                  ),
                  Text(
                    receiveAmount.toStringAsFixed(8),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(receiveAsset.name.toLowerCase()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isLoading;

  const _FeeRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isBold,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        isLoading
            ? Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
            : Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
      ],
    );
  }
}
