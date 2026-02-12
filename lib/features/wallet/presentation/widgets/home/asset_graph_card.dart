import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/asset_detail_screen.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class AssetCardList extends ConsumerWidget {
  const AssetCardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          color: AppColors.surfaceLow,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SvgPicture.asset(asset.iconPath, width: 40, height: 40),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "$icon ${assetValue.toStringAsFixed(2)}",
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
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
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

  SimpleChartPainter({required this.isPositive, required this.klines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isPositive ? Colors.green : Colors.red
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
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

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
          color: Color(0xFF2A2A2A),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
          color: Color(0xFF2A2A2A),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SvgPicture.asset(asset.iconPath, width: 40, height: 40),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "N/A",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.remove, color: Colors.grey, size: 16),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: CustomPaint(
                painter: ErrorChartPainter(),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final y = size.height * 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
