import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/data/services/bitcoin_fee_service.dart';
import 'package:mooze_mobile/features/wallet/domain/models/bitcoin_fee_estimate.dart';
import 'package:mooze_mobile/features/swap/presentation/controllers/btc_lbtc_swap_controller.dart';
import 'package:mooze_mobile/features/swap/presentation/widgets/swap_deal_card.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

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
  bool _feesExpanded = false;
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
                  '[BtcLbtcConfirm] Drain mode - SDK calculated fees with rate: $feeRate sat/vB',
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
    final t = AppLocalizations.of(context);
    final fromAsset = widget.isPegIn ? core.Asset.btc : core.Asset.lbtc;
    final toAsset = widget.isPegIn ? core.Asset.lbtc : core.Asset.btc;

    final boltzFeeSat = _currentFeeEstimate?.boltzServiceFeeSat ?? BigInt.zero;
    final networkFeeSat = _currentFeeEstimate?.networkFeeSat ?? BigInt.zero;
    final totalFeeSat = _currentFeeEstimate?.totalFeeSat ?? BigInt.zero;

    // Deal-card amounts: send is the user's input (known immediately);
    // receive is send minus total fees, but only once fees have been
    // estimated. While fees are loading, pass null so the card shimmers
    // the receive amount — matching the regular confirm sheet's UX.
    final sendAmountSats = widget.amount.toInt();
    final receiveAmountSats = _isLoadingFees
        ? null
        : (widget.amount - totalFeeSat).toInt();

    return PlatformSafeArea(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                t.swap_confirm_title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SwapDealCard(
                    sendAsset: fromAsset,
                    sendAmountSats: sendAmountSats,
                    receiveAsset: toAsset,
                    receiveAmountSats: receiveAmountSats,
                    isLoadingReceive: _isLoadingFees,
                    sendLabel: t.swap_you_send,
                    receiveLabel: t.swap_you_receive,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (_feeEstimate != null) ...[
                    FeeSpeedSelector(
                      selectedSpeed: _selectedFeeSpeed,
                      lowFeeLoading: false,
                      onSpeedChanged: _onFeeSpeedChanged,
                      lowFeeSatPerVByte: _feeEstimate!.lowFeeSatPerVByte,
                      mediumFeeSatPerVByte: _feeEstimate!.mediumFeeSatPerVByte,
                      fastFeeSatPerVByte: _feeEstimate!.fastFeeSatPerVByte,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                  ] else ...[
                    _buildFeeSpeedSelectorSkeleton(),
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
            const SizedBox(height: 16),
            SlideToConfirmButton(
              text: _isConfirming ? t.common_confirming : t.swap_confirm_title,
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

  Widget _buildFeeSpeedSelectorSkeleton() {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 14,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFeeCardSkeleton(baseColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildFeeCardSkeleton(baseColor)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFeeCardSkeleton(Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 14,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown({
    required BigInt boltzFeeSat,
    required BigInt networkFeeSat,
    required BigInt totalFeeSat,
    required bool isLoading,
  }) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    String formatSats(BigInt s) =>
        '${NumberFormat('#,##0', locale).format(s.toInt())} sats';

    // ── Total fees row (collapsible) ──────────────────────────────────
    // Mirrors `_FeesSection` in `confirm_swap_bottom_sheet.dart`:
    // one row showing the total, tap to expand → Boltz + Tx breakdown.
    // The "sending" / "receiving" rows that used to live here have
    // been removed because the SwapDealCard already surfaces both
    // amounts above this section.
    final Widget totalValue = isLoading
        ? _ShimmerBlock(width: 80, height: 16)
        : Text(
            formatSats(totalFeeSat),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estimate — kept as a small helper because peg swaps take
        // minutes (unlike Sideswap which is instant), so users still
        // need this context.
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              '${t.swap_confirm_estimate} · ${_getEstimatedTime()}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () => setState(() => _feesExpanded = !_feesExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.swap_confirm_total_fees_short,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const Spacer(),
                      totalValue,
                      const SizedBox(width: 4),
                      if (!isLoading)
                        AnimatedRotation(
                          turns: _feesExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: (_feesExpanded && !isLoading)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10, left: 24),
                            child: Column(
                              children: [
                                _BreakdownRow(
                                  label: t.swap_confirm_boltz_fee,
                                  value: formatSats(boltzFeeSat),
                                ),
                                const SizedBox(height: 6),
                                _BreakdownRow(
                                  label: t.swap_confirm_tx_fee,
                                  value: formatSats(networkFeeSat),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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

}

/// Single breakdown row inside the expanded fees panel
/// ("Boltz fee · 80 sats", "Tx fee · 2,546 sats"). Mirrors `_SubFeeRow`
/// in the Sideswap confirm sheet.
class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Shimmer placeholder used while fees are being estimated. Matches the
/// shape used by the Sideswap confirm sheet's `_ShimmerBlock` so both
/// loading states feel like the same component.
class _ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBlock({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final base = context.colors.baseColor;
    final highlight = context.colors.highlightColor;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
