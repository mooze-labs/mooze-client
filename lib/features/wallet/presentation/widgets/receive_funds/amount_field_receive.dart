import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final receiveAmountProvider = StateProvider<String>((ref) => '');

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
    final amountText = ref.watch(receiveAmountProvider);

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                selectedAsset!.ticker,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
            suffixText: selectedAsset.ticker,
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
            ref.read(receiveAmountProvider.notifier).state = value;
            final doubleValue = double.tryParse(value);

            final validationController = ref.read(
              receiveValidationControllerProvider.notifier,
            );
            validationController.validateAmount(
              doubleValue,
              AmountDisplayMode.bitcoin,
            );
          },
        ),

        if (selectedNetwork != null && amountText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAmountInfo(context, selectedNetwork, amountText, selectedAsset),
        ],
      ],
    );
  }

  Widget _buildAmountInfo(
    BuildContext context,
    NetworkType network,
    String amountText,
    Asset selectedAsset,
  ) {
    final btcAmount = double.tryParse(amountText);

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
