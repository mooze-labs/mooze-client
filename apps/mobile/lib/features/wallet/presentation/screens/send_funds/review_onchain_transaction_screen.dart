import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/bitcoin_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/drain_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/prepared_psbt_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/formatters/sats_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'transaction_sent_screen.dart';

class ReviewOnchainTransactionScreen extends ConsumerStatefulWidget {
  const ReviewOnchainTransactionScreen({super.key});

  @override
  ConsumerState<ReviewOnchainTransactionScreen> createState() =>
      _ReviewOnchainTransactionScreenState();
}

class _ReviewOnchainTransactionScreenState
    extends ConsumerState<ReviewOnchainTransactionScreen> {
  bool _isConfirming = false;

  Future<void> _handleConfirm() async {
    if (_isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final walletController = await ref.read(walletControllerProvider.future);
      final psbt = ref.read(preparedPsbtProvider);

      if (psbt == null) {
        if (mounted) {
          AppSnackBar.error(
            context,
            AppLocalizations.of(context).wallet_tx_not_found_error,
          );
        }
        return;
      }

      await walletController.match(
        (error) async {
          if (mounted) {
            AppSnackBar.error(
              context,
              AppLocalizations.of(context).error_generic(error.toString()),
            );
          }
        },
        (controller) async {
          final txResult =
              await controller.confirmTransaction(psbt: psbt).run();

          await txResult.match(
            (error) async {
              if (mounted) {
                AppSnackBar.error(
                  context,
                  AppLocalizations.of(
                    context,
                  ).wallet_send_tx_error(error.toString()),
                );
              }
            },
            (transaction) async {
              Future<void>.microtask(() async {
                try {
                  final useCase = await ref.read(refreshWalletProvider.future);
                  await useCase(strategy: SyncStrategy.light);
                } catch (_) {
                  // Swallowed by design.
                }
              });

              if (mounted) {
                TransactionSentScreen.show(
                  context,
                  asset: psbt.asset,
                  amount: psbt.satoshi,
                  destinationAddress: psbt.destination,
                );
              }
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final asset = ref.watch(selectedAssetProvider);
    final finalAmount = ref.watch(finalAmountProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final destination = ref.watch(addressStateProvider);
    final psbt = ref.watch(preparedPsbtProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.wallet_send_title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: PlatformSafeArea(
        child:
            psbt == null
                ? const _EmptyState()
                : _ReviewBody(
                  asset: asset,
                  amountInSats: finalAmount,
                  isDrain: isDrainTransaction,
                  destination: destination,
                  networkFeeSats: psbt.networkFees,
                  bitcoinPrice: bitcoinPrice,
                  currencySymbol: currencySymbol,
                  isConfirming: _isConfirming,
                  onConfirm: _handleConfirm,
                ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  final Asset asset;
  final int amountInSats;
  final bool isDrain;
  final String destination;
  final BigInt networkFeeSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;
  final bool isConfirming;
  final Future<void> Function() onConfirm;

  const _ReviewBody({
    required this.asset,
    required this.amountInSats,
    required this.isDrain,
    required this.destination,
    required this.networkFeeSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
    required this.isConfirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDrain) ...[_DrainBanner(), const SizedBox(height: 16)],
                _HeroCard(
                  asset: asset,
                  amountInSats: amountInSats,
                  bitcoinPrice: bitcoinPrice,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),
                _DetailsCard(
                  address: destination,
                  amountInSats: amountInSats,
                  feeSats: networkFeeSats.toInt(),
                  isDrain: isDrain,
                  bitcoinPrice: bitcoinPrice,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),
                const _FeeSpeedCard(),
                const SizedBox(height: 14),
                _Footnote(text: t.wallet_fee_calculated_note),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: SlideToConfirmButton(
            text: isConfirming ? t.common_sending : t.wallet_slide_to_confirm,
            isLoading: isConfirming,
            onSlideComplete: isConfirming ? () {} : () => onConfirm(),
          ),
        ),
      ],
    );
  }
}

class _DrainBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning = context.appColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.wallet_send_all_info,
              style: theme.textTheme.labelMedium?.copyWith(
                color: warning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Asset asset;
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroCard({
    required this.asset,
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AssetMedallion(asset: asset),
          const SizedBox(height: 14),
          Text(
            asset.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.wallet_onchain_network,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _TickerPill(text: asset.ticker),
          const SizedBox(height: 12),
          _HeroAmountStack(
            asset: asset,
            amountInSats: amountInSats,
            bitcoinPrice: bitcoinPrice,
            currencySymbol: currencySymbol,
          ),
        ],
      ),
    );
  }
}

class _AssetMedallion extends StatelessWidget {
  final Asset asset;
  const _AssetMedallion({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset.iconPath,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _TickerPill extends StatelessWidget {
  final String text;
  const _TickerPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _HeroAmountStack extends StatelessWidget {
  final Asset asset;
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroAmountStack({
    required this.asset,
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBtcLike = asset == Asset.btc || asset == Asset.lbtc;
    final amount = amountInSats / 100000000;
    final mainStr =
        isBtcLike
            ? amount.toStringAsFixed(8)
            : amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${SatsInputFormatter.formatValue(amountInSats)} sats',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isBtcLike) ...[
          const SizedBox(height: 8),
          Text(
            '$mainStr ${asset.ticker}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        _HeroFiatLine(
          amountInSats: amountInSats,
          bitcoinPrice: bitcoinPrice,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}

class _HeroFiatLine extends StatelessWidget {
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _HeroFiatLine({
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (amountInSats / 100000000) * price;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$currencySymbol ${fiat.toStringAsFixed(2)}',
            style: style,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String address;
  final int amountInSats;
  final int feeSats;
  final bool isDrain;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _DetailsCard({
    required this.address,
    required this.amountInSats,
    required this.feeSats,
    required this.isDrain,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05);

    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: _AddressBlock(address: address),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: _FeeBlock(
              feeSats: feeSats,
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
            ),
          ),
          if (!isDrain) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: _TotalBlock(
                amountInSats: amountInSats,
                feeSats: feeSats,
                bitcoinPrice: bitcoinPrice,
                currencySymbol: currencySymbol,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String address;
  const _AddressBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.wallet_destination,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            _InlineCopyButton(text: address),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          address,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13.5,
            height: 1.45,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _FeeBlock extends StatelessWidget {
  final int feeSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FeeBlock({
    required this.feeSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  t.wallet_network_fee,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$feeSats Sats',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            _FiatSubLine(
              amountInSats: feeSats,
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
            ),
          ],
        ),
      ],
    );
  }

  static String _formatBtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} BTC';
}

class _TotalBlock extends StatelessWidget {
  final int amountInSats;
  final int feeSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _TotalBlock({
    required this.amountInSats,
    required this.feeSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totalSats = amountInSats + feeSats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            t.wallet_total,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$totalSats Sats',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            _FiatSubLine(
              amountInSats: totalSats,
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
            ),
          ],
        ),
      ],
    );
  }
}

class _FiatSubLine extends StatelessWidget {
  final int amountInSats;
  final AsyncValue<double> bitcoinPrice;
  final String currencySymbol;

  const _FiatSubLine({
    required this.amountInSats,
    required this.bitcoinPrice,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (amountInSats <= 0) return const SizedBox.shrink();
    return bitcoinPrice.when(
      data: (price) {
        if (price <= 0) return const SizedBox.shrink();
        final fiat = (amountInSats / 100000000) * price;
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '≈ $currencySymbol ${fiat.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _InlineCopyButton extends StatefulWidget {
  final String text;
  const _InlineCopyButton({required this.text});

  @override
  State<_InlineCopyButton> createState() => _InlineCopyButtonState();
}

class _InlineCopyButtonState extends State<_InlineCopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = context.colors.positiveColor;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copy,
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            key: ValueKey(_copied),
            width: 28,
            height: 28,
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: _copied ? positive : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeSpeedCard extends ConsumerWidget {
  const _FeeSpeedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedSpeed = ref.watch(feeSpeedProvider);

    final String label;
    final String description;
    final Color accent;
    final IconData icon;

    switch (selectedSpeed) {
      case FeeSpeed.low:
        label = t.wallet_speed_economic;
        description = t.wallet_speed_economic_desc;
        accent = theme.colorScheme.secondary;
        icon = Icons.schedule_rounded;
        break;
      case FeeSpeed.medium:
        label = t.wallet_speed_normal;
        description = t.wallet_speed_normal_desc;
        accent = context.appColors.warning;
        icon = Icons.speed_rounded;
        break;
      case FeeSpeed.fast:
        label = t.wallet_speed_priority;
        description = t.wallet_speed_priority_desc;
        accent = theme.colorScheme.tertiary;
        icon = Icons.flash_on_rounded;
        break;
    }

    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.wallet_speed_label(label),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  final String text;
  const _Footnote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: context.colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.error.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.wallet_send_prepare_error,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              t.wallet_tx_not_found,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: child,
    );
  }
}
