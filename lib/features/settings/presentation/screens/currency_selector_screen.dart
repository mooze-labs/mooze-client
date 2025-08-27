// ...existing code...
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/prices/providers/currency_provider.dart';
import '../../../../shared/prices/models.dart';

class CurrencySelectorScreen extends ConsumerWidget {
  const CurrencySelectorScreen({Key? key}) : super(key: key);

  List<_CurrencyItem> _getAssetsMockData() {
    return [
      _CurrencyItem(icon: 'R\$', code: 'BRL', name: 'Brasil (Brasil Real)'),
      _CurrencyItem(icon: '\$', code: 'USD', name: 'Estados Unidos (US Dólar)'),
    ];
  }

  Currency? _currencyFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'brl':
        return Currency.brl;
      case 'usd':
        return Currency.usd;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final controller = ref.read(currencyProvider.notifier);
    final assets = _getAssetsMockData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Moeda'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final item = assets[index];
                final isSelected =
                    currency.name.toUpperCase() == item.code.toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final selected = _currencyFromCode(item.code);
                        if (selected != null) {
                          controller.setCurrency(selected);
                        }
                      },
                      child: CurrencySelectorItem(
                        item: item,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyItem {
  final String icon;
  final String code;
  final String name;

  _CurrencyItem({required this.icon, required this.code, required this.name});
}

class CurrencySelectorItem extends StatelessWidget {
  final _CurrencyItem item;
  final bool isSelected;

  const CurrencySelectorItem({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          CircleAvatar(child: Text(item.icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IgnorePointer(
            child: Checkbox(value: isSelected, onChanged: (value) {}),
          ),
        ],
      ),
    );
  }
}
