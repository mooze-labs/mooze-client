import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../settings/price_settings_repository.dart';
import '../../../features/wallet/presentation/providers/cached_data_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

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

  List<CurrencyItem> availableCurrencies(BuildContext context) {
    final t = AppLocalizations.of(context);
    return [
      CurrencyItem(
        icon: 'R\$',
        code: 'BRL',
        name: t.currency_brl_name,
        currency: Currency.brl,
      ),
      CurrencyItem(
        icon: '\$',
        code: 'USD',
        name: t.currency_usd_name,
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
    if (state == currency) return;


    final previous = state;
    state = currency;

    final result = await _repo.setPriceCurrency(currency).run();
    result.match(
      (_) {
        state = previous;
      },
      (_) {

        try {
          ref.invalidate(assetPriceHistoryCacheProvider);
        } catch (_) {}
      },
    );
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
