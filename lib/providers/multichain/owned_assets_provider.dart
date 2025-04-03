import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_provider.dart';

part 'owned_assets_provider.g.dart';

@Riverpod(keepAlive: true)
class OwnedAssetsNotifier extends _$OwnedAssetsNotifier {
  @override
  Future<List<OwnedAsset>> build() async {
    final bitcoinAssets =
        await ref.read(bitcoinWalletNotifierProvider.notifier).getOwnedAssets();
    final liquidAssets =
        await ref.read(liquidWalletNotifierProvider.notifier).getOwnedAssets();
    return [...bitcoinAssets, ...liquidAssets];
  }

  Future<bool> refresh() async {
    final currentState = state;

    try {
      await ref.read(bitcoinWalletNotifierProvider.notifier).sync();
      await ref.read(liquidWalletNotifierProvider.notifier).sync();

      final bitcoinAssets =
          await ref
              .read(bitcoinWalletNotifierProvider.notifier)
              .getOwnedAssets();
      final liquidAssets =
          await ref
              .read(liquidWalletNotifierProvider.notifier)
              .getOwnedAssets();
      final newAssets = [...bitcoinAssets, ...liquidAssets];

      state = AsyncValue.data(newAssets);
      return true;
    } catch (e, stackTrace) {
      if (!currentState.hasValue) {
        state = AsyncValue.error(e, stackTrace);
      } else {
        if (kDebugMode) {
          debugPrint("Error refreshing assets: $e");
        }
      }
      return false;
    }
  }
}
