import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/fake_wallet_repository_impl.dart';

part 'fake_wallet_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WalletRepository fakeWalletRepository(Ref ref) {
  return FakeWalletRepositoryImpl();
}

// Provider with custom mock data
@Riverpod(keepAlive: true)
WalletRepository fakeWalletRepositoryWithData(
  Ref ref,
  Map<String, dynamic> mockData,
) {
  return FakeWalletRepositoryImpl(mockData: mockData);
}
