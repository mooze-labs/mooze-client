enum Currency { brl, usd }

enum PriceSource { coingecko, mock }

class PriceServiceConfig {
  final Currency currency;
  final PriceSource priceSource;

  PriceServiceConfig({required this.currency, required this.priceSource});
}
