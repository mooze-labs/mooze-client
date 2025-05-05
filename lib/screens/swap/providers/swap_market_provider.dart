import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_market_provider.g.dart';

@Riverpod(keepAlive: true)
class SwapMarket extends _$SwapMarket {
  @override
  Future<List<SideswapMarket>> build() async {
    final sideswap = ref.read(sideswapRepositoryProvider);
    sideswap.ensureConnection();
    return sideswap.getMarkets();
  }
}
