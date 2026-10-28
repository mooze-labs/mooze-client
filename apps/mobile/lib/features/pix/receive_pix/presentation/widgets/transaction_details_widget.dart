import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/referral_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_validation_provider.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/motion/size_fade_switcher.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const _tabular = [FontFeature.tabularFigures()];

/// The amount of the selected asset that the deposit delivers.
///
/// The value comes from the asset quote and the deposit after fees. A
/// skeleton holds its place while the quote loads.
class AssetAmountDisplay extends ConsumerWidget {
  const AssetAmountDisplay({super.key});

  TextStyle? _style(BuildContext context) =>
      context.textTheme.headlineMedium?.copyWith(
        color: context.colors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
        fontFeatures: _tabular,
      );

  Widget _returnError(BuildContext context) {
    return Text(
      "N/A",
      style: _style(context)?.copyWith(color: context.colors.negativeColor),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return const SkeletonShimmer(
      child: SkeletonBox(width: 140, height: 30, radius: 8),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final depositAmount = ref.read(depositAmountProvider);
    final assetQuote = ref.watch(assetQuoteProvider(selectedAsset));
    final discountedDepositAmount = ref.watch(
      discountedFeesDepositProvider(depositAmount),
    );

    return assetQuote.when(
      error: (error, stackTrace) {
        if (kDebugMode) debugPrint(error.toString());
        return _returnError(context);
      },
      data: (data) => data.fold(
        (error) {
          if (kDebugMode) debugPrint(error.toString());
          return _returnError(context);
        },
        (val) => val.fold(
          () => _returnError(context),
          (quote) => discountedDepositAmount.when(
            data: (depositAmount) {
              final amount = depositAmount / quote;
              final locale = Localizations.localeOf(context).toString();
              return Text(
                selectedAsset.formatQuoteAmount(amount, locale: locale),
                style: _style(context),
              );
            },
            error: (error, stackTrace) {
              if (kDebugMode) debugPrint(error.toString());
              return _returnError(context);
            },
            loading: () => _buildShimmer(context),
          ),
        ),
      ),
      loading: () => _buildShimmer(context),
    );
  }
}

/// Review of a deposit: what the user receives and the fees that apply.
///
/// The amount sits on the page. The fees share one glass panel. Without a
/// valid amount, the widget asks for one instead.
class TransactionDisplayWidget extends ConsumerWidget {
  const TransactionDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsset = ref.watch(selectedAssetProvider);
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);

    // Each state fills the width, so both states keep the same alignment
    // during the switch.
    return SizeFadeSwitcher(
      child: SizedBox(
        key: ValueKey(validation.isValid),
        width: double.infinity,
        child: validation.isValid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, selectedAsset),
                  const SizedBox(height: 6),
                  _buildReaisAmount(context, depositAmount),
                  const SizedBox(height: 24),
                  _buildFeeBreakdown(context, ref, depositAmount),
                ],
              )
            : _buildEmptyState(context),
      ),
    );
  }

  /// The "You will receive" label and the asset amount, with the asset logo.
  Widget _buildHeader(BuildContext context, Asset asset) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).pix_you_will_receive,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(asset.iconPath, width: 28, height: 28),
              const SizedBox(width: 10),
              // Not const: a new instance reads the current amount on every
              // rebuild of this widget.
              Flexible(child: AssetAmountDisplay()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReaisAmount(BuildContext context, double amount) {
    return Text(
      AppLocalizations.of(
        context,
      ).pix_of_amount(amount.toStringAsFixed(2).replaceAll('.', ',')),
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textSecondary,
        fontFeatures: _tabular,
      ),
    );
  }

  /// Formats a fee rate double as a percentage string with up to 2 decimal
  /// places, stripping trailing zeros. E.g. 3.5 → "3,5%", 3.0 → "3%".
  String _formatPercent(double rate) {
    final s = rate
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '${s.replaceAll('.', ',')}%';
  }

  static String _reais(double amount) =>
      'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';

  Widget _buildFeeBreakdown(
    BuildContext context,
    WidgetRef ref,
    double depositAmount,
  ) {
    final t = AppLocalizations.of(context);
    final feeAmount = ref.watch(feeAmountProvider(depositAmount));
    final feeRate = ref.watch(feeRateProvider(depositAmount));
    final hasReferral = ref.watch(hasReferralProvider);
    final isFixedFee = depositAmount <= fixedFeeRateThreshold;

    // Derive the percent label from the live fee rate (already includes the
    // 15% referral discount when applicable).
    final percentLabel = feeRate.maybeWhen(
      data: _formatPercent,
      orElse: () => '...%',
    );

    // The row of the Mooze fee and, with a referral, the amount saved.
    final Widget moozeFeeRow;
    String? savings;
    if (isFixedFee) {
      moozeFeeRow = _FeeRow(
        title: t.pix_fee_fixed_mooze,
        subtitle: t.pix_fee_fixed_for_small_subtitle,
        value: const _FeeValue('R\$ 1,00'),
      );
    } else {
      final loadingRow = _FeeRow(
        title: t.pix_fee_mooze,
        value: const _FeeValueSkeleton(),
      );
      moozeFeeRow = feeAmount.when(
        data: (amount) => hasReferral.when(
          data: (hasRef) {
            if (hasRef) {
              final originalAmount = amount / 0.85;
              final savedAmount = originalAmount - amount;
              savings = t.pix_fee_savings(
                savedAmount.toStringAsFixed(2).replaceAll('.', ','),
              );
              return _FeeRow(
                title: t.pix_fee_mooze,
                subtitle: t.pix_fee_referral_discount,
                value: _FeeValue(_reais(amount)),
                percent: percentLabel,
              );
            }
            return _FeeRow(
              title: t.pix_fee_mooze,
              value: _FeeValue(_reais(amount)),
              percent: percentLabel,
            );
          },
          error: (_, _) => _FeeRow(
            title: t.pix_fee_mooze,
            value: _FeeValue(_reais(amount)),
            percent: percentLabel,
          ),
          loading: () => loadingRow,
        ),
        error: (_, _) => _FeeRow(
          title: t.pix_fee_mooze,
          value: _FeeValue(t.common_error, muted: true),
        ),
        loading: () => loadingRow,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.pix_fees_applied,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        PixSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            children: [
              moozeFeeRow,
              Divider(
                height: 1,
                thickness: 1,
                color: AppSurfaces.hairline(context),
              ),
              _FeeRow(
                title: t.pix_fee_processor,
                value: const _FeeValue('R\$ 1,00'),
              ),
            ],
          ),
        ),
        if (savings != null) ...[
          const SizedBox(height: 12),
          _SavingsNote(text: savings!),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PixEmptyState(
      icon: PixIcons.amount,
      title: t.pix_waiting_amount_title,
      message: t.pix_waiting_amount_body,
      isCompact: true,
    );
  }
}

/// One fee: its name, an optional note, the amount, and an optional rate.
///
/// The amount keeps its own width, up to 60% of the row. The name takes the
/// rest, so a short amount does not make a long name wrap.
class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.title,
    required this.value,
    this.subtitle,
    this.percent,
  });

  final String title;
  final String? subtitle;
  final Widget value;
  final String? percent;

  @override
  Widget build(BuildContext context) {
    final percent = this.percent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: MergeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textTertiary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    value,
                    if (percent != null && percent.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        percent,
                        textAlign: TextAlign.end,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The amount of a fee, with tabular figures.
class _FeeValue extends StatelessWidget {
  const _FeeValue(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.end,
      style: context.textTheme.bodyMedium?.copyWith(
        color: muted
            ? context.colors.textSecondary
            : context.colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontFeatures: _tabular,
      ),
    );
  }
}

/// Placeholder of a fee that is still loading.
class _FeeValueSkeleton extends StatelessWidget {
  const _FeeValueSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SkeletonBox(width: 56, height: 14, radius: 6),
    );
  }
}

/// The amount a referral code saves, in the positive tone.
///
/// The icon and the text carry the meaning together with the color.
class _SavingsNote extends StatelessWidget {
  const _SavingsNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = pixToneColor(context, PixTone.positive);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PixIcon(PixIcons.celebrate, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
