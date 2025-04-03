import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';

class SuccessfulQuoteAmountDisplay extends StatelessWidget {
  final Asset asset;
  final int amount;

  const SuccessfulQuoteAmountDisplay({
    super.key,
    required this.asset,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Você receberá aproximadamente:",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Image.asset(asset.logoPath, height: 24, width: 24),
                const SizedBox(width: 12),
                Text(
                  "${(amount / pow(10, asset.precision)).toStringAsFixed(asset.precision)} ${asset.ticker}",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LowBalanceQuoteDisplay extends StatelessWidget {
  final Asset asset;
  final int availableBalance;
  final int requestedBalance;

  const LowBalanceQuoteDisplay({
    super.key,
    required this.asset,
    required this.availableBalance,
    required this.requestedBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Fundos insuficientes",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(asset.logoPath, height: 24, width: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Solicitado: ${(requestedBalance / pow(10, asset.precision)).toStringAsFixed(asset.precision)} ${asset.ticker}",
                      style: TextStyle(
                        fontFamily: "roboto",
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      "Disponível: ${(availableBalance / pow(10, asset.precision)).toStringAsFixed(asset.precision)} ${asset.ticker}",
                      style: TextStyle(
                        fontFamily: "roboto",
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorQuoteDisplay extends StatelessWidget {
  final String errorMessage;

  const ErrorQuoteDisplay({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Erro ao processar:",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 16,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
