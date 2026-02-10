import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../settings/price_settings_repository.dart';
import '../../../features/wallet/presentation/providers/cached_data_provider.dart';
import '../../../features/wallet/presentation/providers/fiat_price_provider.dart';
import 'price_service_provider.dart';

final currencyControllerProvider =
    StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
      return CurrencyNotifier(ref);
    });

class CurrencyItem {
  final String icon;
  final String code;
  final String name;
  final Currency currency;

  const CurrencyItem({
    required this.icon,
    required this.code,
    required this.name,
    required this.currency,
  });
}

class CurrencyNotifier extends StateNotifier<Currency> {
  final Ref ref;

  String get icon {
    switch (state) {
      case Currency.brl:
        return 'R\$';
      case Currency.usd:
        return '\$';
    }
  }

  List<CurrencyItem> get availableCurrencies {
    return [
      const CurrencyItem(
        icon: 'R\$',
        code: 'BRL',
        name: 'Brasil (Brasil Real)',
        currency: Currency.brl,
      ),
      const CurrencyItem(
        icon: '\$',
        code: 'USD',
        name: 'Estados Unidos (US Dólar)',
        currency: Currency.usd,
      ),
    ];
  }

  CurrencyNotifier(this.ref) : super(Currency.brl) {
    _loadCurrency();
  }

  final _repo = PriceSettingsRepositoryImpl();

  Future<void> _loadCurrency() async {
    final result = await _repo.getPriceCurrency().run();
    result.match((err) => state = Currency.brl, (currency) => state = currency);
  }

  Future<void> setCurrency(Currency currency) async {
    final result = await _repo.setPriceCurrency(currency).run();
    result.match((err) => null, (_) {
      state = currency;
      _invalidatePriceCache();
    });
  }

  void _invalidatePriceCache() {
    try {
      ref.invalidate(assetPriceHistoryCacheProvider);

      ref.invalidate(fiatPriceProvider);
      ref.invalidate(priceServiceProvider);
    } catch (e) {}
  }

  Currency? currencyFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'brl':
        return Currency.brl;
      case 'usd':
        return Currency.usd;
      default:
        return null;
    }
  }

  bool isSelected(CurrencyItem item) {
    return state == item.currency;
  }
}
