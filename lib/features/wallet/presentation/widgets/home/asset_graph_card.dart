import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/asset_detail_screen.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

class AssetCardList extends ConsumerWidget {
  const AssetCardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the refresh trigger to re-render without loading state
    ref.watch(dataRefreshTriggerProvider);

    final favoriteAssets = ref.watch(favoriteAssetsProvider);

    return Row(
      children:
          favoriteAssets
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final asset = entry.value;

                return [
                  Expanded(child: AssetGraphCard(asset: asset)),
                  if (index < favoriteAssets.length - 1)
                    const SizedBox(width: 12),
                ];
              })
              .expand((widgets) => widgets)
              .toList(),
    );
  }
}

class AssetGraphCard extends ConsumerWidget {
  final Asset asset;

  const AssetGraphCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedPriceHistory = ref.watch(
      cachedAssetPriceHistoryProvider(asset),
    );

    if (cachedPriceHistory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(assetPriceHistoryCacheProvider.notifier)
            .fetchAssetPriceHistory(asset);
      });
      return LoadingAssetCard(asset: asset);
    }

    return cachedPriceHistory.fold((err) {
      if (kDebugMode) debugPrint("[KLINES] $err");
      return ErrorAssetCard(asset: asset);
    }, (klines) => SuccessfulAssetCard(asset: asset, klines: klines));
  }
}

class SuccessfulAssetCard extends ConsumerWidget {
  final Asset asset;
  final List<double> klines;

  const SuccessfulAssetCard({
    super.key,
    required this.asset,
    required this.klines,
  });

  @override
  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = ((klines.last - klines.first) / klines.first) * 100;
    final isPositive = klines.last > klines.first;
    final assetValue = klines.last;
    final icon = ref.watch(currencyControllerProvider.notifier).icon;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SvgPicture.asset(asset.iconPath, width: 40, height: 40),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "$icon ${_numberFormat.format(assetValue)}",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "${percentage.toStringAsFixed(2)}% (24h)",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPositive
                          ? context.colors.positiveColor
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive
                        ? context.colors.positiveColor
                        : Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: CustomPaint(
                painter: SimpleChartPainter(
                  isPositive: isPositive,
                  klines: klines,
                  positiveColor: context.colors.positiveColor,
                  negativeColor: Theme.of(context).colorScheme.error,
                ),
                size: Size(double.infinity, 40),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final bool isPositive;
  final List<double> klines;
  final Color positiveColor;
  final Color negativeColor;

  SimpleChartPainter({
    required this.isPositive,
    required this.klines,
    required this.positiveColor,
    required this.negativeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isPositive ? positiveColor : negativeColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

    final zeroLinePaint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0)
          ..strokeWidth = 1;

    final zeroY = size.height * 0.5;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroLinePaint);

    final path = Path();

    if (klines.isEmpty) return;

    final minValue = klines.reduce((a, b) => a < b ? a : b);
    final maxValue = klines.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < klines.length; i++) {
      final x = (i / (klines.length - 1)) * size.width;
      final normalizedValue = range == 0 ? 0.0 : (klines[i] - minValue) / range;
      final y = size.height * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
      }

      path.lineTo(points.last.dx, points.last.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoadingAssetCard extends StatelessWidget {
  final Asset asset;

  const LoadingAssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.baseColor;
    final highlightColor = context.colors.highlightColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SvgPicture.asset(asset.iconPath, width: 40, height: 40),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 80,
                  height: 18,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class ErrorAssetCard extends StatelessWidget {
  final Asset asset;

  const ErrorAssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SvgPicture.asset(asset.iconPath, width: 40, height: 40),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "N/A",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "N/A",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.remove,
                    color: Theme.of(context).colorScheme.outline,
                    size: 16,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: CustomPaint(
                painter: ErrorChartPainter(
                  color: Theme.of(context).colorScheme.error,
                ),
                size: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorChartPainter extends CustomPainter {
  final Color color;

  ErrorChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final y = size.height * 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
