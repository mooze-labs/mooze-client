import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';

enum ReceiveConversionType { asset, sats, fiat }

final receiveAmountProvider = StateProvider<String>((ref) => '');
final receiveConversionTypeProvider = StateProvider<ReceiveConversionType>(
  (ref) => ReceiveConversionType.asset,
);
final receiveConversionLoadingProvider = StateProvider<bool>((ref) => false);

final receiveAssetValueProvider = StateProvider<String>((ref) => '');
final receiveSatsValueProvider = StateProvider<String>((ref) => '');
final receiveFiatValueProvider = StateProvider<String>((ref) => '');

class AmountFieldReceive extends ConsumerStatefulWidget {
  const AmountFieldReceive({super.key});

  @override
  ConsumerState<AmountFieldReceive> createState() => _AmountFieldReceiveState();
}

class _AmountFieldReceiveState extends ConsumerState<AmountFieldReceive> {
  late TextEditingController _textController;
  bool _isUpdatingFromProvider = false;

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
    final conversionType = ref.watch(receiveConversionTypeProvider);
    final isConversionLoading = ref.watch(receiveConversionLoadingProvider);

    final currentValue = _getCurrentValueForType(conversionType, ref);

    if (!_isUpdatingFromProvider && _textController.text != currentValue) {
      _isUpdatingFromProvider = true;
      _textController.text = currentValue;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: currentValue.length),
      );
      _isUpdatingFromProvider = false;
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
            _buildConversionOptionsRow(context, ref, selectedAsset),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          enabled: !isDisabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            hintText:
                isRequired
                    ? 'Digite o valor (obrigatório)'
                    : 'Digite o valor (opcional)',
            suffixText: _getSuffixText(selectedAsset, conversionType, ref),
            suffixIcon:
                isConversionLoading
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
            errorText: validationState.amountError,
            helperText:
                isDisabled
                    ? 'Selecione um ativo e rede primeiro'
                    : isRequired
                    ? 'Valor obrigatório para Lightning'
                    : 'Valor opcional para Bitcoin/Liquid',
          ),
          onChanged: (value) {
            if (selectedAsset == null || _isUpdatingFromProvider) return;

            final conversionType = ref.read(receiveConversionTypeProvider);

            _updateCurrentValueProvider(conversionType, value, ref);

            _updateFinalAmountValue(value, conversionType, selectedAsset, ref);
          },
        ),

        if (selectedNetwork != null &&
            currentValue.isNotEmpty &&
            selectedAsset != null) ...[
          const SizedBox(height: 8),
          _buildAmountInfo(
            context,
            selectedNetwork,
            currentValue,
            selectedAsset,
          ),
        ],
      ],
    );
  }

  Widget _buildConversionOptionsRow(
    BuildContext context,
    WidgetRef ref,
    Asset? selectedAsset,
  ) {
    if (selectedAsset == null) return const SizedBox.shrink();

    final conversionType = ref.watch(receiveConversionTypeProvider);
    final currencyNotifier = ref.read(currencyControllerProvider.notifier);
    final fiatCurrency = currencyNotifier.icon;

    return Row(
      children: [
        _buildConversionOption(
          context,
          ref,
          icon: Icons.account_balance_wallet,
          label: selectedAsset.ticker,
          isSelected: conversionType == ReceiveConversionType.asset,
          onTap: () {
            ref.read(receiveConversionLoadingProvider.notifier).state = false;
            ref.read(receiveConversionTypeProvider.notifier).state =
                ReceiveConversionType.asset;
            _syncValuesOnTypeChange(
              ReceiveConversionType.asset,
              selectedAsset,
              ref,
            );
          },
        ),
        const SizedBox(width: 8),
        if (selectedAsset == Asset.btc) ...[
          _buildConversionOption(
            context,
            ref,
            icon: Icons.bolt,
            label: 'sats',
            isSelected: conversionType == ReceiveConversionType.sats,
            onTap: () {
              ref.read(receiveConversionLoadingProvider.notifier).state = false;
              ref.read(receiveConversionTypeProvider.notifier).state =
                  ReceiveConversionType.sats;
              _syncValuesOnTypeChange(
                ReceiveConversionType.sats,
                selectedAsset,
                ref,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        _buildConversionOption(
          context,
          ref,
          icon: Icons.monetization_on,
          label: fiatCurrency,
          isSelected: conversionType == ReceiveConversionType.fiat,
          onTap: () {
            ref.read(receiveConversionLoadingProvider.notifier).state = false;
            ref.read(receiveConversionTypeProvider.notifier).state =
                ReceiveConversionType.fiat;
            _syncValuesOnTypeChange(
              ReceiveConversionType.fiat,
              selectedAsset,
              ref,
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversionOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ReceiveConversionType getCurrentConversionType(WidgetRef ref) {
    return ref.read(receiveConversionTypeProvider);
  }

  String _getCurrentValueForType(
    ReceiveConversionType conversionType,
    WidgetRef ref,
  ) {
    switch (conversionType) {
      case ReceiveConversionType.asset:
        return ref.watch(receiveAssetValueProvider);
      case ReceiveConversionType.sats:
        return ref.watch(receiveSatsValueProvider);
      case ReceiveConversionType.fiat:
        return ref.watch(receiveFiatValueProvider);
    }
  }

  void _updateCurrentValueProvider(
    ReceiveConversionType conversionType,
    String value,
    WidgetRef ref,
  ) {
    switch (conversionType) {
      case ReceiveConversionType.asset:
        ref.read(receiveAssetValueProvider.notifier).state = value;
        break;
      case ReceiveConversionType.sats:
        ref.read(receiveSatsValueProvider.notifier).state = value;
        break;
      case ReceiveConversionType.fiat:
        ref.read(receiveFiatValueProvider.notifier).state = value;
        break;
    }
  }

  void _updateFinalAmountValue(
    String inputValue,
    ReceiveConversionType conversionType,
    Asset selectedAsset,
    WidgetRef ref,
  ) {
    if (inputValue.isEmpty) {
      ref.read(receiveAmountProvider.notifier).state = '';
      return;
    }

    final inputDouble = double.tryParse(inputValue);
    if (inputDouble == null || inputDouble <= 0) {
      ref.read(receiveAmountProvider.notifier).state = '';
      return;
    }

    String finalValue;

    switch (conversionType) {
      case ReceiveConversionType.asset:
        finalValue = inputValue;
        break;

      case ReceiveConversionType.sats:
        if (selectedAsset == Asset.btc) {
          final btcValue = inputDouble / 100000000;
          finalValue = btcValue.toString();
        } else {
          finalValue = inputValue;
        }
        break;

      case ReceiveConversionType.fiat:
        _convertFiatToAsset(inputValue, selectedAsset, ref);
        return;
    }

    ref.read(receiveAmountProvider.notifier).state = finalValue;

    final doubleValue = double.tryParse(finalValue);
    final validationController = ref.read(
      receiveValidationControllerProvider.notifier,
    );
    validationController.validateAmount(doubleValue, AmountDisplayMode.bitcoin);
  }

  void _convertFiatToAsset(
    String inputValue,
    Asset selectedAsset,
    WidgetRef ref,
  ) async {
    final inputDouble = double.tryParse(inputValue);
    if (inputDouble == null || inputDouble <= 0) return;

    ref.read(receiveConversionLoadingProvider.notifier).state = true;

    try {
      final priceResult = await ref.read(
        fiatPriceProvider(selectedAsset).future,
      );

      priceResult.fold(
        (error) {
          print('Erro ao obter preço para conversão: $error');
          ref.read(receiveAmountProvider.notifier).state = '';
        },
        (price) {
          if (price <= 0) {
            print('Preço inválido recebido: $price');
            ref.read(receiveAmountProvider.notifier).state = '';
            return;
          }

          final assetValue = inputDouble / price;
          String finalValue;

          if (selectedAsset == Asset.btc) {
            finalValue = assetValue
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          } else {
            finalValue = assetValue
                .toStringAsFixed(6)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          }

          ref.read(receiveAmountProvider.notifier).state = finalValue;

          final validationController = ref.read(
            receiveValidationControllerProvider.notifier,
          );
          validationController.validateAmount(
            assetValue,
            AmountDisplayMode.bitcoin,
          );
        },
      );
    } catch (e) {
      print('Erro na conversão fiat: $e');
      ref.read(receiveAmountProvider.notifier).state = '';
    } finally {
      ref.read(receiveConversionLoadingProvider.notifier).state = false;
    }
  }

  void _syncValuesOnTypeChange(
    ReceiveConversionType newType,
    Asset selectedAsset,
    WidgetRef ref,
  ) {
    final currentAssetValue = ref.read(receiveAmountProvider);
    if (currentAssetValue.isEmpty) return;

    final assetDouble = double.tryParse(currentAssetValue);
    if (assetDouble == null || assetDouble <= 0) return;

    switch (newType) {
      case ReceiveConversionType.asset:
        ref.read(receiveAssetValueProvider.notifier).state = currentAssetValue;
        break;

      case ReceiveConversionType.sats:
        if (selectedAsset == Asset.btc) {
          final satsValue = (assetDouble * 100000000).round();
          ref.read(receiveSatsValueProvider.notifier).state =
              satsValue.toString();
        }
        break;

      case ReceiveConversionType.fiat:
        _convertAssetToFiat(currentAssetValue, selectedAsset, ref);
        break;
    }
  }

  void _convertAssetToFiat(
    String assetValue,
    Asset selectedAsset,
    WidgetRef ref,
  ) async {
    final assetDouble = double.tryParse(assetValue);
    if (assetDouble == null || assetDouble <= 0) return;

    try {
      final priceResult = await ref.read(
        fiatPriceProvider(selectedAsset).future,
      );

      priceResult.fold(
        (error) {
          print('Erro ao obter preço para conversão reversa: $error');
        },
        (price) {
          if (price <= 0) return;

          final fiatValue = assetDouble * price;
          ref.read(receiveFiatValueProvider.notifier).state = fiatValue
              .toStringAsFixed(2);
        },
      );
    } catch (e) {
      print('Erro na conversão reversa: $e');
    }
  }

  Widget _buildConversionPreview(
    BuildContext context,
    Asset selectedAsset,
    double assetAmount,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final currencyNotifier = ref.read(currencyControllerProvider.notifier);
        final fiatCurrency = currencyNotifier.icon;
        final conversionType = ref.watch(receiveConversionTypeProvider);

        return FutureBuilder(
          future: ref.read(fiatPriceProvider(selectedAsset).future),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Carregando conversões...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              );
            }

            return snapshot.data!.fold((error) => const SizedBox.shrink(), (
              price,
            ) {
              final fiatValue = assetAmount * price;
              final satsValue =
                  selectedAsset == Asset.btc
                      ? (assetAmount * 100000000).round()
                      : null;

              return Column(
                children: [
                  Container(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Conversões equivalentes:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (conversionType != ReceiveConversionType.asset)
                    _buildConversionRow(
                      context,
                      icon: Icons.account_balance_wallet,
                      label: '${selectedAsset.ticker}:',
                      value: assetAmount
                          .toStringAsFixed(selectedAsset == Asset.btc ? 8 : 6)
                          .replaceAll(RegExp(r'0+$'), '')
                          .replaceAll(RegExp(r'\.$'), ''),
                      suffix: selectedAsset.ticker,
                    ),

                  if (selectedAsset == Asset.btc &&
                      conversionType != ReceiveConversionType.sats &&
                      satsValue != null)
                    _buildConversionRow(
                      context,
                      icon: Icons.bolt,
                      label: 'Satoshis:',
                      value: satsValue.toString(),
                      suffix: 'sats',
                    ),

                  if (conversionType != ReceiveConversionType.fiat)
                    _buildConversionRow(
                      context,
                      icon: Icons.monetization_on,
                      label: '$fiatCurrency:',
                      value: fiatValue.toStringAsFixed(2),
                      suffix: fiatCurrency,
                    ),
                ],
              );
            });
          },
        );
      },
    );
  }

  Widget _buildConversionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          Text(
            '$value $suffix',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getSuffixText(
    Asset? selectedAsset,
    ReceiveConversionType conversionType,
    WidgetRef ref,
  ) {
    if (selectedAsset == null) return '';

    switch (conversionType) {
      case ReceiveConversionType.asset:
        return selectedAsset.ticker;
      case ReceiveConversionType.sats:
        return selectedAsset == Asset.btc ? 'sats' : selectedAsset.ticker;
      case ReceiveConversionType.fiat:
        final currencyNotifier = ref.read(currencyControllerProvider.notifier);
        return currencyNotifier.icon;
    }
  }

  Widget _buildAmountInfo(
    BuildContext context,
    NetworkType network,
    String amountText,
    Asset selectedAsset,
  ) {
    final finalAssetValue = ref.watch(receiveAmountProvider);
    final btcAmount = double.tryParse(finalAssetValue);

    if (btcAmount == null) return const SizedBox.shrink();

    final satsAmount = (btcAmount * 100000000).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedAsset == Asset.btc)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valor em Satoshis:',
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
          const SizedBox(height: 8),

          _buildConversionPreview(context, selectedAsset, btcAmount),
          const SizedBox(height: 8),

          if (network == NetworkType.lightning) ...[
            if (btcAmount < 0.000001)
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
                      'Valor mínimo: 100 sats (0.000001 BTC)',
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
                      'Valor válido para Lightning',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ] else if (network == NetworkType.bitcoin) ...[
            if (btcAmount < 0.00025)
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
                      'Valor mínimo: 0.00025 BTC',
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
                      'Valor válido para Bitcoin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ] else if (network == NetworkType.liquid) ...[
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
}
