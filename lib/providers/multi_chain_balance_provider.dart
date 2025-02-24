import 'package:mooze_mobile/providers/bitcoin/wallet_provider.dart' as bitcoin;
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart' as liquid;

enum Network {
	bitcoin,
	liquid
}

class Balance {
	final String id;
	final Network network;
	final int amount; // amount should be in sats

	Balance({
		required this.ticker,
		required this.network,
		required this.amount
	});
}

@riverpod
class MultiChainBalanceNotifier extends $_MultiChainBalanceNotifier {
	@override
	AsyncValue<Map<String, Balance>> build() {
		return const AsyncValue.loading();
	}
}
