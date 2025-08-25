// import 'dart:developer';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mooze_mobile/features/swap/data/datasources/sideswap.dart';
// import 'package:mooze_mobile/features/swap/data/repositories.dart';
// import 'package:mooze_mobile/shared/entities/asset.dart';

// import 'mock_swap_wallet.dart';

// void main() {
//   group("Swap repository", () {
//     test(
//       'Should instantiate the Sideswap repository and get swap rate for USDt <> BTC',
//       () async {
//         final sideswapApiKey = String.fromEnvironment("SIDESWAP_API_KEY");

//         final sideswapApi = SideswapApi();
//         sideswapApi.connect();
//         // Wait for connection to be established
//         await Future.delayed(const Duration(seconds: 5));

//         final sideswapService = SideswapService(
//           api: sideswapApi,
//           apiKey: sideswapApiKey,
//         );

//         sideswapService.ensureConnection();

//         final swapRepository = SwapRepositoryImpl(
//           sideswapService: sideswapService,
//           liquidWallet: MockSwapWallet(),
//         );

//         final swapRate =
//             await swapRepository.getSwapRate(Asset.btc, Asset.usdt).run();
//         swapRate.fold(
//           (l) => print('Could not get swap rate: $l'),
//           (r) => print("Swap rate: $r"),
//         );
//       },
//     );
//   });
// }
