import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import '../models/swap_input_model.dart';

part 'swap_input_provider.g.dart';

bool isPegOp(Asset sendAsset, Asset recvAsset) {
  return sendAsset == AssetCatalog.bitcoin || recvAsset == AssetCatalog.bitcoin;
}

@riverpod
class SwapInputNotifier extends _$SwapInputNotifier {
  @override
  SwapInputModel build() {
    return SwapInputModel(
      sendAsset: AssetCatalog.getById("lbtc")!,
      recvAsset: AssetCatalog.getById("depix")!,
      sendAssetSatoshiAmount: 0,
      recvAssetSatoshiAmount: 0,
    );
  }

  void changeSendAsset(Asset asset) {
    state = state.copyWith(sendAsset: asset);

    if (state.sendAssetSatoshiAmount > 0 &&
        !isPegOp(state.sendAsset, state.recvAsset)) {
      ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
      ref.read(sideswapRepositoryProvider).stopQuotes();
      ref
          .read(swapQuoteNotifierProvider.notifier)
          .requestNewQuote(
            state.sendAsset.id,
            state.sendAssetSatoshiAmount,
            state.recvAsset.id,
          );

      state = state.copyWith(
        sendAssetSatoshiAmount: 0,
        recvAssetSatoshiAmount: 0,
      );
      return;
    }

    if (isPegOp(state.sendAsset, state.recvAsset)) {
      state = state.copyWith(
        sendAssetSatoshiAmount: 0,
        recvAssetSatoshiAmount: 0,
      );
      return;
    }
  }

  void changeRecvAsset(Asset asset) {
    state = state.copyWith(recvAsset: asset);

    ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
    ref.read(sideswapRepositoryProvider).stopQuotes();

    if (state.sendAssetSatoshiAmount > 0 &&
        !isPegOp(state.sendAsset, state.recvAsset)) {
      ref
          .read(swapQuoteNotifierProvider.notifier)
          .requestNewQuote(
            state.sendAsset.id,
            state.sendAssetSatoshiAmount,
            state.recvAsset.id,
          );

      state = state.copyWith(
        sendAssetSatoshiAmount: 0,
        recvAssetSatoshiAmount: 0,
      );
      return;
    }

    if (isPegOp(state.sendAsset, state.recvAsset)) {
      state = state.copyWith(
        sendAssetSatoshiAmount: 0,
        recvAssetSatoshiAmount: 0,
      );
      return;
    }
  }

  void changeSendAssetSatoshiAmount(int amount) {
    state = state.copyWith(sendAssetSatoshiAmount: amount);

    if (state.sendAssetSatoshiAmount > 0 &&
        !isPegOp(state.sendAsset, state.recvAsset)) {
      ref
          .read(swapQuoteNotifierProvider.notifier)
          .requestNewQuote(
            state.sendAsset.id,
            state.sendAssetSatoshiAmount,
            state.recvAsset.id,
          );

      state = state.copyWith(
        sendAssetSatoshiAmount: state.sendAssetSatoshiAmount,
        recvAssetSatoshiAmount: 0,
      );
      return;
    }

    if (isPegOp(state.sendAsset, state.recvAsset)) {
      state = state.copyWith(
        sendAssetSatoshiAmount: amount,
        recvAssetSatoshiAmount: (amount * 0.99).toInt(),
      );
      return;
    }
  }

  void changeRecvAssetSatoshiAmount(int amount) {
    state = state.copyWith(recvAssetSatoshiAmount: amount);
  }
}
