// import 'package:fpdart/fpdart.dart';
// import 'package:mooze_mobile/features/swap/domain/entities.dart';
// import 'package:mooze_mobile/features/swap/domain/repositories.dart';
// import 'package:mooze_mobile/shared/entities/asset.dart';

// class MockSwapWallet implements SwapWallet {
//   final List<SwapUtxo> _mockUtxos;
//   final String _mockAddress;
//   final bool _shouldFailUtxos;
//   final bool _shouldFailSigning;

//   MockSwapWallet({
//     List<SwapUtxo>? mockUtxos,
//     String mockAddress =
//         'lq1qqt6lewa5ludy4dndmvfn37v864pxaqu62dule99rlmkx3nh9lvkljl83fqr6s3lyaesmds8c23vvg3jwjgpkvvt0ytjskqt8q',
//     bool shouldFailUtxos = false,
//     bool shouldFailSigning = false,
//   }) : _mockUtxos = mockUtxos ?? _defaultMockUtxos,
//        _mockAddress = mockAddress,
//        _shouldFailUtxos = shouldFailUtxos,
//        _shouldFailSigning = shouldFailSigning;

//   static List<SwapUtxo> get _defaultMockUtxos => [
//     SwapUtxo(
//       txid: 'mock_txid_1',
//       vout: 0,
//       asset: 'mock_asset_1',
//       assetBf: 'mock_asset_bf_1',
//       value: BigInt.from(1000000),
//       valueBf: 'mock_value_bf_1',
//     ),
//     SwapUtxo(
//       txid: 'mock_txid_2',
//       vout: 1,
//       asset: 'mock_asset_2',
//       assetBf: 'mock_asset_bf_2',
//       value: BigInt.from(2000000),
//       valueBf: 'mock_value_bf_2',
//     ),
//   ];

//   @override
//   TaskEither<String, List<SwapUtxo>> getUtxos(Asset asset, BigInt amount) {
//     return TaskEither<String, List<SwapUtxo>>(() async {
//       if (_shouldFailUtxos) {
//         return Either<String, List<SwapUtxo>>.left(
//           "Mock error: Failed to get UTXOs",
//         );
//       }

//       final assetId = Asset.toId(asset);
//       final filteredUtxos =
//           _mockUtxos.where((u) => u.asset == assetId).toList();

//       final selectedUtxos = <SwapUtxo>[];
//       var remaining = amount;

//       for (final utxo in filteredUtxos) {
//         if (remaining <= BigInt.zero) break;

//         selectedUtxos.add(utxo);
//         remaining -= utxo.value;
//       }

//       if (remaining > BigInt.zero) {
//         return Either<String, List<SwapUtxo>>.left("Insufficient funds");
//       }

//       return Either<String, List<SwapUtxo>>.right(selectedUtxos);
//     });
//   }

//   @override
//   Task<String> getAddress() {
//     return Task(() async => _mockAddress);
//   }

//   @override
//   TaskEither<String, String> signSwapOperation(String pset) {
//     return TaskEither<String, String>(() async {
//       if (_shouldFailSigning) {
//         return Either<String, String>.left(
//           "Mock error: Failed to sign transaction",
//         );
//       }

//       return Either<String, String>.right("mock_signed_pset_$pset");
//     });
//   }
// }
