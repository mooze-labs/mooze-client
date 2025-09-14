import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/selected_receive_network_provider.dart';
import 'package:mooze_mobile/features/wallet/providers/receive_funds/receive_validation_controller.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/asset_selector_receive.dart';

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
                'SATS',
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
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText:
                isRequired
                    ? 'Digite o valor em satoshis (obrigatório)'
                    : 'Digite o valor em satoshis (opcional)',
            suffixText: 'sats',
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
            final intValue = int.tryParse(value);
            final doubleValue = intValue?.toDouble();

            final validationController = ref.read(
              receiveValidationControllerProvider.notifier,
            );
            validationController.validateAmount(
              doubleValue,
              AmountDisplayMode.sats,
            );
          },
        ),

        if (selectedNetwork != null && amountText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAmountInfo(context, selectedNetwork, amountText),
        ],
      ],
    );
  }

  Widget _buildAmountInfo(
    BuildContext context,
    NetworkType network,
    String amountText,
  ) {
    final satsAmount = int.tryParse(amountText);

    if (satsAmount == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor em BTC:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(satsAmount / 100000000).toStringAsFixed(8)} BTC',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (network == NetworkType.bitcoin ||
              network == NetworkType.lightning) ...[
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
                      'Valor mínimo recomendado: 25.000 sats',
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
