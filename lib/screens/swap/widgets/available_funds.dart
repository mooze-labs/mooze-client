import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';

class AvailableFunds extends ConsumerWidget {
  final OwnedAsset? asset;

  const AvailableFunds({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (asset == null) {
      return Text("");
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Quantidade disponível: ${(asset!.amount / pow(10, asset!.asset.precision)).toStringAsFixed(asset!.asset.precision)} ${asset!.asset.ticker}",
          ),
        ],
      ),
    );
  }
}
