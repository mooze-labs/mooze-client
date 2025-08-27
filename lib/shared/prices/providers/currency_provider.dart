import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../settings/price_settings_repository.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((
  ref,
) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  String get icon {
    switch (state) {
      case Currency.brl:
        return 'R\$';
      case Currency.usd:
        return '\$';
    }
  }

  CurrencyNotifier() : super(Currency.brl) {
    _loadCurrency();
  }

  final _repo = PriceSettingsRepositoryImpl();

  Future<void> _loadCurrency() async {
    final result = await _repo.getPriceCurrency().run();
    result.match((err) => state = Currency.brl, (currency) => state = currency);
  }

  Future<void> setCurrency(Currency currency) async {
    final result = await _repo.setPriceCurrency(currency).run();
    result.match((err) => null, (_) => state = currency);
  }
}
