import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/price_service_provider.dart';

enum DisplayModeType { fiat, selectedAsset, bitcoin, sats }

final receiveAmountProvider = StateProvider<String>((ref) => '');

final receiveAmountDisplayModeProvider = StateProvider<AmountDisplayMode>(
  (ref) => AmountDisplayMode.bitcoin,
);

final receiveAssetPriceProvider = FutureProvider<double>((ref) async {
  final selectedAsset = ref.watch(selectedReceiveAssetProvider);
  if (selectedAsset == null) {
    throw Exception('Nenhum ativo selecionado');
  }

  final priceServiceResult = await ref.read(priceServiceProvider).run();

  return await priceServiceResult.fold(
    (error) async {
      print('DEBUG: Erro ao obter serviço de preços: $error');
      throw Exception('Serviço de preços indisponível: $error');
    },
    (service) async {
      final assetPriceResult = await service.getCoinPrice(selectedAsset).run();
      return assetPriceResult.fold(
        (error) {
          print('DEBUG: Erro ao obter preço de ${selectedAsset.name}: $error');
          throw Exception(
            'Erro ao obter cotação de ${selectedAsset.name}: $error',
          );
        },
        (priceOption) => priceOption.fold(
          () {
            print('DEBUG: Preço de ${selectedAsset.name} não disponível');
            throw Exception('Preço de ${selectedAsset.name} não disponível');
          },
          (price) {
            print('DEBUG: Preço real de ${selectedAsset.name} obtido: $price');
            return price;
          },
        ),
      );
    },
  );
});

final receiveBitcoinPriceProvider = FutureProvider<double>((ref) async {
  final priceServiceResult = await ref.read(priceServiceProvider).run();

  return await priceServiceResult.fold(
    (error) async {
      print('DEBUG: Erro ao obter serviço de preços: $error');
      throw Exception('Serviço de preços indisponível: $error');
    },
    (service) async {
      final btcPriceResult = await service.getCoinPrice(Asset.btc).run();
      return btcPriceResult.fold(
        (error) {
          print('DEBUG: Erro ao obter preço do Bitcoin: $error');
          throw Exception('Erro ao obter cotação do Bitcoin: $error');
        },
        (priceOption) => priceOption.fold(
          () {
            print('DEBUG: Preço do Bitcoin não disponível');
            throw Exception('Preço do Bitcoin não disponível');
          },
          (price) {
            print('DEBUG: Preço real do Bitcoin obtido: $price');
            return price;
          },
        ),
      );
    },
  );
});

class AmountFieldReceive extends ConsumerStatefulWidget {
  const AmountFieldReceive({super.key});

  @override
  ConsumerState<AmountFieldReceive> createState() => _AmountFieldReceiveState();
}

class _AmountFieldReceiveState extends ConsumerState<AmountFieldReceive> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedNetwork = ref.watch(selectedReceiveNetworkProvider);
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final validationState = ref.watch(receiveValidationControllerProvider);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );
    final amountText = ref.watch(receiveAmountProvider);
    final displayMode = ref.watch(receiveAmountDisplayModeProvider);
    final currentCurrency = ref.watch(currencyControllerProvider);

    if (_textController.text != amountText) {
      _textController.text = amountText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: amountText.length),
      );
    }

    final isRequired = selectedNetwork == NetworkType.lightning;
    final isDisabled = selectedAsset == null || selectedNetwork == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Valor',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Spacer(),

            _buildDisplayModeToggle(context, ref, displayMode, currentCurrency),
          ],
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _textController,
          enabled: !isDisabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText:
                isRequired
                    ? 'Digite o valor (obrigatório)'
                    : 'Digite o valor (opcional)',
            suffixText: _getSuffixText(
              displayMode,
              selectedAsset,
              currentCurrency,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: validationState.amountError,
            helperText:
                isDisabled
                    ? 'Selecione um ativo e rede primeiro'
                    : isRequired
                    ? 'Valor obrigatório para Lightning'
                    : 'Valor opcional para Bitcoin/Liquid',
          ),
          onChanged: (value) {
            ref.read(receiveAmountProvider.notifier).state = value;
            final doubleValue = double.tryParse(value);
            validationController.validateAmount(doubleValue, displayMode);
          },
        ),

        if (selectedNetwork != null && amountText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final assetPriceAsync = ref.watch(receiveAssetPriceProvider);
              final bitcoinPriceAsync = ref.watch(receiveBitcoinPriceProvider);

              return assetPriceAsync.when(
                data:
                    (assetPrice) => bitcoinPriceAsync.when(
                      data:
                          (btcPrice) => _buildAmountInfo(
                            context,
                            selectedNetwork,
                            amountText,
                            displayMode,
                            currentCurrency,
                            assetPrice,
                            btcPrice,
                          ),
                      loading:
                          () => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Carregando cotação do Bitcoin...'),
                              ],
                            ),
                          ),
                      error:
                          (error, _) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_outlined,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Erro ao carregar cotação do Bitcoin: Conversões indisponíveis',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                loading:
                    () => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Carregando cotação...'),
                        ],
                      ),
                    ),
                error:
                    (error, _) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erro ao carregar cotação: Conversões indisponíveis',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDisplayModeToggle(
    BuildContext context,
    WidgetRef ref,
    AmountDisplayMode currentMode,
    Currency currentCurrency,
  ) {
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final currencyCode = currentCurrency == Currency.brl ? 'BRL' : 'USD';
    final assetTicker = selectedAsset?.ticker ?? 'BTC';

    List<Widget> modeButtons = [];

    modeButtons.add(
      _buildModeButton(
        context,
        ref,
        currencyCode,
        AmountDisplayMode.fiat,
        currentMode,
        displayType: DisplayModeType.fiat,
      ),
    );

    modeButtons.add(
      _buildModeButton(
        context,
        ref,
        assetTicker,
        AmountDisplayMode.selectedAsset,
        currentMode,
        displayType: DisplayModeType.selectedAsset,
      ),
    );

    if (selectedAsset != Asset.btc) {
      modeButtons.add(
        _buildModeButton(
          context,
          ref,
          'BTC',
          AmountDisplayMode.bitcoin,
          currentMode,
          displayType: DisplayModeType.bitcoin,
        ),
      );
    }

    modeButtons.add(
      _buildModeButton(
        context,
        ref,
        'SATS',
        AmountDisplayMode.sats,
        currentMode,
        displayType: DisplayModeType.sats,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: modeButtons),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    AmountDisplayMode mode,
    AmountDisplayMode currentMode, {
    required DisplayModeType displayType,
  }) {
    final isSelected = mode == currentMode;

    return GestureDetector(
      onTap: () {
        _convertAmountOnModeChange(
          ref,
          currentMode,
          mode,
          displayType: displayType,
        );
        ref.read(receiveAmountDisplayModeProvider.notifier).state = mode;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _convertAmountOnModeChange(
    WidgetRef ref,
    AmountDisplayMode fromMode,
    AmountDisplayMode toMode, {
    required DisplayModeType displayType,
  }) async {
    final currentAmountText = ref.read(receiveAmountProvider);
    if (currentAmountText.isEmpty) return;

    final currentAmount = double.tryParse(currentAmountText);
    if (currentAmount == null) return;

    final selectedAsset = ref.read(selectedReceiveAssetProvider);
    if (selectedAsset == null) return;

    try {
      final selectedAssetPriceAsync = ref.read(
        receiveAssetPriceProvider.future,
      );
      final selectedAssetPrice = await selectedAssetPriceAsync;

      final priceServiceResult = await ref.read(priceServiceProvider).run();
      final service = priceServiceResult.fold(
        (error) => throw Exception('Serviço de preços indisponível: $error'),
        (service) => service,
      );

      final btcPriceResult = await service.getCoinPrice(Asset.btc).run();
      final btcPrice = btcPriceResult.fold(
        (error) => throw Exception('Erro ao obter preço do Bitcoin: $error'),
        (priceOption) => priceOption.fold(
          () => throw Exception('Preço do Bitcoin não disponível'),
          (price) => price,
        ),
      );

      double fiatValue;
      switch (fromMode) {
        case AmountDisplayMode.fiat:
          fiatValue = currentAmount;
          break;
        case AmountDisplayMode.bitcoin:
          fiatValue = currentAmount * btcPrice;
          break;
        case AmountDisplayMode.selectedAsset:
          fiatValue = currentAmount * selectedAssetPrice;
          break;
        case AmountDisplayMode.sats:
          final btcAmount = currentAmount / 100000000;
          fiatValue = btcAmount * btcPrice;
          break;
      }

      double convertedAmount;
      switch (toMode) {
        case AmountDisplayMode.fiat:
          convertedAmount = fiatValue;
          break;
        case AmountDisplayMode.bitcoin:
          convertedAmount = fiatValue / btcPrice;
          break;
        case AmountDisplayMode.selectedAsset:
          convertedAmount = fiatValue / selectedAssetPrice;
          break;
        case AmountDisplayMode.sats:
          final btcAmount = fiatValue / btcPrice;
          convertedAmount = btcAmount * 100000000;
          break;
      }

      String formattedAmount;
      if (toMode == AmountDisplayMode.sats) {
        formattedAmount = convertedAmount.round().toString();
      } else if (toMode == AmountDisplayMode.bitcoin ||
          toMode == AmountDisplayMode.selectedAsset) {
        formattedAmount = convertedAmount.toStringAsFixed(8);

        formattedAmount = formattedAmount
            .replaceAll(RegExp(r'0*$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      } else {
        formattedAmount = convertedAmount.toStringAsFixed(2);
      }

      ref.read(receiveAmountProvider.notifier).state = formattedAmount;

      final validationController = ref.read(
        receiveValidationControllerProvider.notifier,
      );
      final doubleValue = double.tryParse(formattedAmount);

      validationController.validateAmount(doubleValue, toMode);
    } catch (e) {
      print('DEBUG: Erro ao converter valor: $e');
    }
  }

  String _getSuffixText(
    AmountDisplayMode mode,
    Asset? selectedAsset,
    Currency currentCurrency,
  ) {
    switch (mode) {
      case AmountDisplayMode.fiat:
        return currentCurrency == Currency.brl ? 'BRL' : 'USD';
      case AmountDisplayMode.bitcoin:
        return 'BTC';
      case AmountDisplayMode.selectedAsset:
        return selectedAsset?.ticker ?? 'BTC';
      case AmountDisplayMode.sats:
        return 'sats';
    }
  }

  Widget _buildAmountInfo(
    BuildContext context,
    NetworkType network,
    String amountText,
    AmountDisplayMode displayMode,
    Currency currentCurrency,
    double assetPrice,
    double btcPrice,
  ) {
    final amount = double.tryParse(amountText);

    if (amount == null) return const SizedBox.shrink();

    final satsAmount = _calculateSatsAmount(
      amount,
      displayMode,
      assetPrice,
      btcPrice,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildConversions(
            context,
            amount,
            displayMode,
            currentCurrency,
            assetPrice,
            btcPrice,
          ),

          if (network == NetworkType.bitcoin ||
              network == NetworkType.lightning) ...[
            const SizedBox(height: 4),
            if (satsAmount < 25000)
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Valor mínimo: 25.000 sats',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Valor válido',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ] else if (network == NetworkType.liquid) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Rede Liquid selecionada',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildConversions(
    BuildContext context,
    double amount,
    AmountDisplayMode displayMode,
    Currency currentCurrency,
    double assetPrice,
    double btcPrice,
  ) {
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);
    final currencySymbol = currentCurrency == Currency.brl ? 'R\$' : '\$';
    final currencyCode = currentCurrency == Currency.brl ? 'BRL' : 'USD';
    final assetTicker = selectedAsset?.ticker ?? 'BTC';

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        final assetAmount = amount / assetPrice;

        int satsAmount;
        if (selectedAsset == Asset.btc) {
          satsAmount = (assetAmount * 100000000).round();
        } else {
          final btcAmount = amount / btcPrice;
          satsAmount = (btcAmount * 100000000).round();
        }

        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em $assetTicker:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${assetAmount.toStringAsFixed(8)} $assetTicker',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em satoshis:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${satsAmount.toString()} sats',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ];
      case AmountDisplayMode.bitcoin:
        final satsAmount = (amount * 100000000).round();

        final fiatAmount = amount * btcPrice;
        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em $currencyCode:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$currencySymbol${fiatAmount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em satoshis:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${satsAmount.toString()} sats',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ];
      case AmountDisplayMode.selectedAsset:
        int satsAmount;
        if (selectedAsset == Asset.btc) {
          satsAmount = (amount * 100000000).round();
        } else {
          final fiatValue = amount * assetPrice;
          final btcAmount = fiatValue / btcPrice;
          satsAmount = (btcAmount * 100000000).round();
        }
        final fiatAmount = amount * assetPrice;

        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em $currencyCode:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$currencySymbol${fiatAmount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em satoshis:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${satsAmount.toString()} sats',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ];
      case AmountDisplayMode.sats:
        final btcAmount = amount / 100000000;
        final fiatAmount = btcAmount * btcPrice;

        final assetAmount = fiatAmount / assetPrice;

        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em $assetTicker:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${assetAmount.toStringAsFixed(8)} $assetTicker',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em $currencyCode:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$currencySymbol${fiatAmount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ];
    }
  }

  int _calculateSatsAmount(
    double amount,
    AmountDisplayMode displayMode,
    double selectedAssetPrice,
    double btcPrice,
  ) {
    final selectedAsset = ref.watch(selectedReceiveAssetProvider);

    switch (displayMode) {
      case AmountDisplayMode.fiat:
        final btcAmount = amount / btcPrice;
        return (btcAmount * 100000000).round();

      case AmountDisplayMode.bitcoin:
        return (amount * 100000000).round();

      case AmountDisplayMode.selectedAsset:
        if (selectedAsset == Asset.btc) {
          return (amount * 100000000).round();
        } else {
          final fiatValue = amount * selectedAssetPrice;
          final btcAmount = fiatValue / btcPrice;
          return (btcAmount * 100000000).round();
        }

      case AmountDisplayMode.sats:
        return amount.round();
    }
  }
}
