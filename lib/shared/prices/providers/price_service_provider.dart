import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../services.dart';
import '../settings.dart';

final priceServiceProvider = Provider<TaskEither<String, PriceService>>((ref) {
  final service = PriceSettingsRepositoryImpl().getPriceServiceConfig().flatMap((
    c,
  ) {
    print(
      'DEBUG: Configuração do serviço de preços - Source: ${c.priceSource}, Currency: ${c.currency}',
    );
    print(
      'DEBUG: Usando HybridPriceService com fonte primária: ${c.priceSource.name}',
    );
    return TaskEither.right(HybridPriceService(c.currency, c.priceSource));
  });

  return service;
});
