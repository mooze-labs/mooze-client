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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Você receberá aproximadamente: ",
              style: TextStyle(fontFamily: "roboto", fontSize: 20),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(asset.logoPath, height: 24, width: 24),
                const SizedBox(width: 8),
                Text(
                  "${amount / pow(10, asset.precision)} ${asset.ticker}",
                  style: TextStyle(fontFamily: "roboto", fontSize: 24),
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
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Fundos insuficientes",
              style: TextStyle(fontFamily: "roboto", fontSize: 24),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(asset.logoPath, height: 24, width: 24),
                const SizedBox(width: 8),
                Text(
                  "Você ofereceu: ${requestedBalance.toStringAsFixed(asset.precision)} ${asset.ticker}",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                Text(
                  "Você tem: ${availableBalance.toStringAsFixed(asset.precision)} ${asset.ticker}",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSecondary,
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

class ErrorQuoteDisplay extends StatelessWidget {
  final String errorMessage;

  const ErrorQuoteDisplay({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Erro ao processar: $errorMessage",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 20,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
