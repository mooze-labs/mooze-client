import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/price_repository.dart';

import '../../data/repositories/coingecko_price_repository_impl.dart';
import '../../data/repositories/mock_price_repository_impl.dart';

final priceRepositoryProvider = Provider.family<PriceRepository, String>((
  ref,
  String type,
) {
  switch (type) {
    case 'coingecko':
      return CoingeckoPriceRepositoryImpl();
    case 'mock':
      return MockPriceRepositoryImpl();
    default:
      throw UnimplementedError('Price repository type not implemented');
  }
});
