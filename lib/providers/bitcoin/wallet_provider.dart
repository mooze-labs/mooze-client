import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/providers/mnemonic_provider.dart';

part 'wallet_provider.g.dart';

const electrumUrl = "blockstream.info";

@riverpod
Future<Blockchain?> blockchain(Ref ref, Network network) async {
	final port = (network == Network.bitcoin) ? 700 : 993;
	final blockchain = await Blockchain.create(
		config: BlockchainConfig.electrum(
			config: ElectrumConfig(
				stopGap: BigInt.from(10),
				timeout: 5,
				retry: 5,
				url: "${electrumUrl}:${port}",
				validateDomain: true
			)
		)
	);

	return blockchain;
}

@riverpod
class BitcoinWalletNotifier extends _$BitcoinWalletNotifier {
	@override
	AsyncValue<Wallet?> build() {
		return const AsyncValue.loading();
	}

	Future<void> initializeWallet(Network network) async {
		state = const AsyncValue.loading();
		try {
			final mnemonic = await ref.read(mnemonicNotifierProvider.future);
			if (mnemonic == null) {
				throw Exception("Mnemônico não encontrado!");
			}

			final blockchain = await ref.read(blockchainProvider(network).future);
			if (blockchain == null) {
				throw Exception("Não foi possível sincronizar com o servidor. Tente novamente mais tarde.");
			}

			final descriptorKey = await DescriptorSecretKey.create(
				network: network,
				mnemonic: await Mnemonic.fromString(mnemonic)
			);

			final externalDescriptor = await Descriptor.newBip44(
				secretKey: descriptorKey,
				network: network,
				keychain: KeychainKind.externalChain
			);
			final internalDescriptor = await Descriptor.newBip44(
				secretKey: descriptorKey,
				network: network,
				keychain: KeychainKind.internalChain
			);

			final wallet = await Wallet.create(
				descriptor: externalDescriptor,
				changeDescriptor: internalDescriptor,
				network: network,
				databaseConfig: const DatabaseConfig.memory()
			);

			final _ = await wallet.sync(blockchain: blockchain);
			state = AsyncValue.data(wallet);
		} catch (e, stackTrace) {
			state = AsyncValue.error(e, stackTrace);
		}
	}

	Future<void> sync() async {
		final wallet = state.asData?.value;
		if (wallet == null) {
			throw Exception("Carteira não inicializada.");
		}

		try {
			state = const AsyncValue.loading();
			final network = wallet.network();
			final blockchain = await ref.read(blockchainProvider(network).future);
			if (blockchain == null) {
				throw Exception("Não foi possível sincronizar com o servidor.");
			}

			await wallet.sync(blockchain: blockchain);
			state = AsyncValue.data(wallet);
		} catch (e, stackTrace) {
			state = AsyncValue.error(e, stackTrace);
		}
	}

	Future<String?> generateAddress() async {
		final wallet = state.asData?.value;
		if (wallet == null) {
			throw Exception("Carteira não inicializada.");
		}

		state = const AsyncValue.loading();
		final address = wallet.getAddress(
			addressIndex: AddressIndex.increase()
		).address.asString();

		state = AsyncValue.data(wallet);
		return address;
	}
}
