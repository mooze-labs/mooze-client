import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../consts.dart';

const List<Asset> assetList = [Asset.btc, Asset.usdt, Asset.depix];

class AssetCardList extends ConsumerWidget {
  const AssetCardList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: AssetGraphCard(asset: Asset.btc)),
        const SizedBox(width: cardSpacing),
        Expanded(child: AssetGraphCard(asset: Asset.usdt))
      ],
    );
  }
}

class AssetGraphCard extends ConsumerWidget {
  final Asset asset;

  const AssetGraphCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceHistory = ref.watch(assetPriceHistoryProvider(asset));
    
    return priceHistory.when(
      data: (data) => data.fold(
        (err) {
          if (kDebugMode) debugPrint("[KLINES] $err");
          return ErrorAssetCard(asset: asset);
        },
        (klines) => SuccessfulAssetCard(asset: asset, klines: klines)
      ),
      error: (err, stackTrace) {
        if (kDebugMode) debugPrint("[KLINES] $err");
        return ErrorAssetCard(asset: asset);
      },
      loading: () => LoadingAssetCard(asset: asset)
    );
  }
}

class SuccessfulAssetCard extends StatelessWidget {
  final Asset asset;
  final List<double> klines;

  const SuccessfulAssetCard({
    super.key,
    required this.asset,
    required this.klines
  });

  @override
  Widget build(BuildContext context) {
    final percentage = klines.last / klines.first;
    final isPositive = klines.last > klines.first;
    final assetValue = klines.last;

    return Container(
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
                SvgPicture.asset("assets/new_ui_wallet/assets/icons/asset/${asset.name.toLowerCase()}.svg", width: 40, height: 40),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              assetValue.toStringAsFixed(2),
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
          // Gráfico simples simulado SEM padding
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: SimpleChartPainter(isPositive: isPositive, klines: klines),
              size: Size(double.infinity, 40),
            ),
          ),
        ],
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

    // Normalize kline data to chart coordinates
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

      // Conecta ao último ponto
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
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Container(
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
                SvgPicture.asset("assets/new_ui_wallet/assets/icons/asset/${asset.name.toLowerCase()}.svg", width: 40, height: 40),
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
          SizedBox(
            height: 40,
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: baseColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorAssetCard extends StatelessWidget {
  final Asset asset;

  const ErrorAssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                SvgPicture.asset("assets/new_ui_wallet/assets/icons/asset/${asset.name.toLowerCase()}.svg", width: 40, height: 40),
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.remove,
                  color: Colors.grey,
                  size: 16,
                ),
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
    );
  }
}

class ErrorChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final y = size.height * 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
