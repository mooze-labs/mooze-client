import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_providers.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_conversion_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/receive_conversion_widgets.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/payment_limits_provider.dart';

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
    final controller = ref.read(receiveConversionControllerProvider.notifier);

    final currentValue = controller.getCurrentValueForType(conversionType);

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
            ReceiveConversionOptionsRow(selectedAsset: selectedAsset),
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
            suffixText: _getSuffixText(selectedAsset, conversionType),
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

            controller.updateCurrentValueProvider(conversionType, value);

            controller.updateFinalAmountValue(
              value,
              conversionType,
              selectedAsset,
            );
          },
        ),

        if (selectedNetwork != null &&
            currentValue.isNotEmpty &&
            selectedAsset != null) ...[
          const SizedBox(height: 8),
          _buildAmountInfo(context, selectedNetwork, selectedAsset),
        ],
      ],
    );
  }

  String _getSuffixText(
    Asset? selectedAsset,
    ReceiveConversionType conversionType,
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

          ReceiveConversionPreview(
            selectedAsset: selectedAsset,
            assetAmount: btcAmount,
          ),
          const SizedBox(height: 8),

          _buildNetworkValidations(context, network, btcAmount),
        ],
      ),
    );
  }

  Widget _buildNetworkValidations(
    BuildContext context,
    NetworkType network,
    double btcAmount,
  ) {
    final amountSats = BigInt.from((btcAmount * 100000000).round());

    if (network == NetworkType.lightning) {
      return ref
          .watch(lightningLimitsProvider)
          .when(
            data: (limits) {
              if (limits == null) {
                return _buildValidationRow(
                  context,
                  icon: Icons.warning_amber_outlined,
                  text: 'Não foi possível carregar limites Lightning',
                  color: Colors.orange,
                );
              }

              if (amountSats < limits.send.minSat) {
                return _buildValidationRow(
                  context,
                  icon: Icons.warning_amber_outlined,
                  text: 'Valor mínimo: ${limits.send.minSat} sats',
                  color: Colors.orange,
                );
              } else if (amountSats > limits.send.maxSat) {
                return _buildValidationRow(
                  context,
                  icon: Icons.error_outline,
                  text: 'Valor máximo: ${limits.send.maxSat} sats',
                  color: Colors.red,
                );
              } else {
                return _buildValidationRow(
                  context,
                  icon: Icons.check_circle_outline,
                  text: 'Valor válido para Lightning',
                  color: Colors.green,
                );
              }
            },
            loading:
                () => _buildValidationRow(
                  context,
                  icon: Icons.hourglass_empty,
                  text: 'Carregando limites Lightning...',
                  color: Colors.grey,
                ),
            error:
                (error, stack) => _buildValidationRow(
                  context,
                  icon: Icons.error_outline,
                  text: 'Erro ao carregar limites Lightning',
                  color: Colors.red,
                ),
          );
    } else if (network == NetworkType.bitcoin) {
      return ref
          .watch(onchainLimitsProvider)
          .when(
            data: (limits) {
              if (limits == null) {
                return _buildValidationRow(
                  context,
                  icon: Icons.warning_amber_outlined,
                  text: 'Não foi possível carregar limites onchain',
                  color: Colors.orange,
                );
              }

              if (amountSats < limits.send.minSat) {
                return _buildValidationRow(
                  context,
                  icon: Icons.warning_amber_outlined,
                  text: 'Valor mínimo: ${limits.send.minSat} sats',
                  color: Colors.orange,
                );
              } else if (amountSats > limits.send.maxSat) {
                return _buildValidationRow(
                  context,
                  icon: Icons.error_outline,
                  text: 'Valor máximo: ${limits.send.maxSat} sats',
                  color: Colors.red,
                );
              } else {
                return _buildValidationRow(
                  context,
                  icon: Icons.check_circle_outline,
                  text: 'Valor válido para Bitcoin',
                  color: Colors.green,
                );
              }
            },
            loading:
                () => _buildValidationRow(
                  context,
                  icon: Icons.hourglass_empty,
                  text: 'Carregando limites onchain...',
                  color: Colors.grey,
                ),
            error:
                (error, stack) => _buildValidationRow(
                  context,
                  icon: Icons.error_outline,
                  text: 'Erro ao carregar limites onchain',
                  color: Colors.red,
                ),
          );
    } else if (network == NetworkType.liquid) {
      return _buildValidationRow(
        context,
        icon: Icons.check_circle_outline,
        text: 'Valor válido para Liquid',
        color: Colors.green,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildValidationRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
