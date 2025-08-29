import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/asset_detail/widgets/period_selector_widget.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class AssetChartWidget extends ConsumerWidget {
  final Asset asset;
  final TimePeriod selectedPeriod;

  const AssetChartWidget({
    super.key,
    required this.asset,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mapear o período selecionado para parâmetros de API
    final params = _getParamsForPeriod(selectedPeriod, asset);
    final priceHistory = ref.watch(assetPriceHistoryWithPeriodProvider(params));
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: priceHistory.when(
        data:
            (data) => data.fold(
              (err) => _buildErrorChart(),
              (klines) => _buildSuccessChart(klines),
            ),
        error: (_, __) => _buildErrorChart(),
        loading: () => _buildLoadingChart(),
      ),
    );
  }

  AssetPriceHistoryParams _getParamsForPeriod(TimePeriod period, Asset asset) {
    switch (period) {
      case TimePeriod.day:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneHour,
          periodInDays: 1,
        );
      case TimePeriod.week:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.fourHours,
          periodInDays: 7,
        );
      case TimePeriod.month:
        return AssetPriceHistoryParams(
          asset: asset,
          interval: KlineInterval.oneDay,
          periodInDays: 30,
        );
    }
  }

  Widget _buildSuccessChart(List<double> klines) {
    final isPositive = klines.last > klines.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gráfico - ${_getPeriodLabel(selectedPeriod)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: CustomPaint(
            painter: DetailedChartPainter(
              isPositive: isPositive,
              klines: klines,
            ),
            size: const Size(double.infinity, double.infinity),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChart() {
    return Shimmer.fromColors(
      baseColor: AppColors.baseColor,
      highlightColor: AppColors.highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.baseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gráfico Indisponível',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.withOpacity(0.7),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível carregar o gráfico',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return '1D';
      case TimePeriod.week:
        return '7D';
      case TimePeriod.month:
        return '1M';
    }
  }
}

class DetailedChartPainter extends CustomPainter {
  final bool isPositive;
  final List<double> klines;

  DetailedChartPainter({required this.isPositive, required this.klines});

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;

    final paint =
        Paint()
          ..color = isPositive ? Colors.green : Colors.red
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isPositive ? Colors.green : Colors.red).withOpacity(0.3),
              (isPositive ? Colors.green : Colors.red).withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1;

    // Desenha grid
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Normaliza os dados
    final minValue = klines.reduce((a, b) => a < b ? a : b);
    final maxValue = klines.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < klines.length; i++) {
      final x = (i / (klines.length - 1)) * size.width;
      final normalizedValue = range == 0 ? 0.5 : (klines[i] - minValue) / range;
      final y = size.height * (1 - normalizedValue);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      // Linha principal
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.5, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) * 0.5, p2.dy);

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }

      // Completa o preenchimento
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Desenha preenchimento
      canvas.drawPath(fillPath, gradientPaint);

      // Desenha linha
      canvas.drawPath(path, paint);

      // Desenha pontos
      final pointPaint =
          Paint()
            ..color = isPositive ? Colors.green : Colors.red
            ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
